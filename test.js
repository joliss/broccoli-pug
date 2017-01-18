let pug = require('pug')
let lex = require('pug-lexer')
let parse = require('pug-parser')
var util = require('util')
var fs = require('fs')

var fullPath = './a.pug'
var contents = fs.readFileSync(fullPath, 'utf8')

var tokens = lex(contents, {
  filename: fullPath
});

var ast = parse(tokens, {
  filename: fullPath,
  src: contents
});

console.error(util.inspect(ast, { depth: 10 }
  ))
