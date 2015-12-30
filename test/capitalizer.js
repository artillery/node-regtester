#!/usr/bin/env node

var pathlib = require('path');
var fs = require('fs');

exports.readFileCapitalized = function(inputPath) {
  return fs.readFileSync(inputPath, 'utf8').toUpperCase();
}
