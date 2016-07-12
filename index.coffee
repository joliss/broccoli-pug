fs = require 'fs'
path = require 'path'

Plugin = require 'broccoli-plugin'
Promise = require 'bluebird'
fileUtils = require 'file'
mkdirp = require 'mkdirp'

pug = require 'pug'

fs.writeFileAsync = Promise.promisify fs.writeFile

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
      fileUtils.walkSync inputPath, (dirPath, dirs, files) =>
        for file in files
          continue if path.extname(file) isnt '.pug'
          fullPath = path.join dirPath, file
          relativePath = path.relative inputPath, fullPath
          outputPath = path.join @outputPath, relativePath
            .replace /\.[^/.]+$/, ''
          mkdirp.sync path.dirname outputPath

          promises.push(
            if @render
              fs.writeFileAsync "#{outputPath}.html", pug.renderFile fullPath, @pugOptions
            else
              fs.writeFileAsync "#{outputPath}.js", 'module.exports=template;' + pug.compileFileClient fullPath, @pugOptions
          )
    Promise.all promises

module.exports = BroccoliPug
