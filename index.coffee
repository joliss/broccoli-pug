fs = require 'fs'
path = require 'path'

Plugin = require 'broccoli-plugin'
Promise = require 'bluebird'
walk = require 'walk-sync'
{sync: mkdirp} = require 'mkdirp'
{sync: symlink} = require 'symlink-or-copy'

pug = require 'pug'

fs.writeFileAsync = Promise.promisify fs.writeFile
replaceExtension = (file, ext) -> file.substr(0, file.lastIndexOf '.') + ext

class BroccoliPug extends Plugin
  constructor: (inputNodes, options) ->
    unless @ instanceof BroccoliPug
      return new BroccoliPug inputNodes, options
    @render = options?.render or false
    @pugOptions = options?.pugOptions or {}
    super inputNodes, options

  build: ->
    # TODO: we need to cache input files and avoid rebuilding them if their
    # sources are unchanged. We also need to scan for their import/include
    # dependencies, so we can rebuild when a dependency changes.
    promises = []
    for inputPath in @inputPaths
      files = walk.entries inputPath

      for file in files
        continue if file.isDirectory()

        {basePath, relativePath} = file
        outputPath = path.join @outputPath, relativePath
        mkdirp path.dirname outputPath

        fullPath = path.join basePath, relativePath
        if path.extname(fullPath) isnt '.pug'
          symlink fullPath, outputPath
        else
          promises.push (
            if @render
              fs.writeFileAsync replaceExtension(outputPath, '.html'), pug.renderFile fullPath, @pugOptions
            else
              fs.writeFileAsync replaceExtension(outputPath, '.js'), 'module.exports=template;' + pug.compileFileClient fullPath, @pugOptions
          )
    Promise.all promises

module.exports = BroccoliPug
