path = require 'path'

Plugin = require 'broccoli-plugin'
Promise = require 'bluebird'
walk = require 'walk-sync'
{sync: mkdirp} = require 'mkdirp'
{sync: symlink} = require 'symlink-or-copy'
fs = Promise.promisifyAll require 'fs'
exists = require 'file-exists'
debug = require('debug') 'broccoli-pug'

pug = require 'pug'
lex = require 'pug-lexer'
parse = require 'pug-parser'

replaceExtension = (file, ext) -> file.substr(0, file.lastIndexOf '.') + ext

getReferences = (node) ->
  refs = []

  # util = require('util')
  # if (/navbar/).exec(util.inspect(node))
  #   console.log(util.inspect(node))
  if node.file? and node.file.type is 'FileReference'
    refs.push node.file.path

  if node.nodes?
    for child in node.nodes
      refs = refs.concat getReferences child

  return refs

compile = (inputPath, render, options) ->
  if render
    pug.renderFile inputPath, options
  else
    'module.exports=template;' + pug.compileFileClient inputPath, options

makeOutputPath = (outputPath, render) ->
  if render
    replaceExtension outputPath, '.html'
  else
    replaceExtension outputPath, '.js'

META_CACHE_NAME = '.metacache'

class BroccoliPug extends Plugin
  constructor: (inputNodes, options) ->
    unless @ instanceof BroccoliPug
      return new BroccoliPug inputNodes, options
    @render = options?.render or false
    @pugOptions = options?.pugOptions or {}
    super inputNodes, options

  build: ->
    promises = []

    # This tells us when we can invalidate the cache by storing the mtime of
    # the source file and the files that this source file depends on. This lets
    # us build a dependency graph.
    meta = {}

    # Check if a pre-existing metadata cache exists
    metaPath = path.join @cachePath, META_CACHE_NAME
    if exists metaPath
      savedMeta = JSON.parse fs.readFileSync metaPath, 'utf8'
    else
      savedMeta = {}

    for inputPath in @inputPaths
      files = walk.entries inputPath
      filesMap = files.reduce (acc, file) ->
        acc[file.relativePath] = file
        return acc
      , {}

      for file in files
        # Skip folders -- we instead call mkdirp before every file write
        continue if file.isDirectory()
        {basePath, relativePath, mtime} = file

        # Make output file folder
        outputPath = makeOutputPath path.join(@outputPath, relativePath), @render
        mkdirp path.dirname outputPath

        # Pass-through files that are not .pug
        fullPath = path.join basePath, relativePath
        if path.extname(fullPath) isnt '.pug'
          symlink fullPath, outputPath
          continue

        # Check if we can use the cached version
        useCache = true
        if savedMeta[relativePath]?
          if mtime > savedMeta[relativePath].mtime
            debug "Rebuilding #{relativePath} due to changes"
            useCache = false
          for dependency in savedMeta[relativePath].dependencies
            if filesMap[dependency].mtime > savedMeta[dependency].mtime
              debug "Rebuilding #{relativePath} due to changes in #{dependency}"
              useCache = false
              break
        else
          debug "Initial build of #{relativePath}"
          useCache = false

        cachePath = path.join @cachePath, relativePath
        if useCache
          meta[relativePath] = savedMeta[relativePath]
          symlink cachePath, outputPath unless exists outputPath
          continue

        # Make cache file folder
        mkdirp path.dirname cachePath

        promise = do (inputPath, fullPath, relativePath, cachePath, outputPath, mtime, meta) =>
          fs.readFileAsync fullPath, 'utf8'
            .then (contents) =>
              # Parse the file for FileReferences (see
              # https://github.com/pugjs/pug-ast-spec/blob/master/parser.md)
              tokens = lex contents, filename: fullPath
              ast = parse tokens, filename: fullPath, src: contents
              console.error getReferences ast
              dependencies = getReferences ast
                .map (depPath) ->
                  resolved = path.relative inputPath, path.join path.dirname(fullPath), depPath
                  if path.extname(resolved) is ''
                    resolved += '.pug'
                  return resolved
              meta[relativePath] = {dependencies, mtime}

              # Write compiled file to cache and symlink to output
              compiled = compile fullPath, @render, @pugOptions

              fs.writeFileAsync cachePath, compiled
                .then -> symlink cachePath, outputPath

        # We need to make sure we process all files
        # On weird systems (slow at processing files + lots of files), this may
        # cause an error where too many files are open simultaneously.
        promises.push promise

    # Commit metadata to cache
    Promise.all promises
      .then -> fs.writeFileAsync metaPath, JSON.stringify meta

module.exports = BroccoliPug
