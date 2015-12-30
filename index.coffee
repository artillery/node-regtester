# Copyright 2015 Artillery Games, Inc. All rights reserved.
#
# This code, and all derivative work, is the exclusive property of Artillery
# Games, Inc. and may not be used without Artillery Games, Inc.'s authorization.
#
# Author: Mark Logan

path = require 'path'
fs = require 'fs'
child_process = require 'child_process'
temp = require 'temp'

# TestDataFiles makes it easy to do data-file driven regtests.
#
# First, put your input files (if any) in a `test-data` directory,
# within the directory that contains your test, e.g.:
#
#   something/something/lib/test
#   \_ regtest.coffee
#   \_ test-data
#     \_ myinputfile
#
# Next, write your test:
#
#   exports.setUp = (cb) ->
#     @testData = new common.testlib.TestDataFiles(__filename)
#     @testData.makeTmpDir()
#     cb()
#
#   exports.testRegtest = (test) ->
#     @testData.testFile test, 'myinputfile', (testHandle) ->
#       results = processFile testHandle.inputPath
#       testHandle.writeObservedOutput results
#
# Now, generate your expected output:
#
# $ UPDATE_REGTEST_DATA=1 nodeunit regtest.coffee
#
# The expected output is stored in the test-data directory:
#
#   something/something/lib/test
#   \_ regtest.coffee
#   \_ test-data
#     \_ myinputfile
#     \_ myinputfile.expected
#
# Run the test again, it should pass:
#
# $ nodeunit regtest.coffee
#
# If you like, change `myinputfile.expected`, and verify that the test fails.
#
# Add all the new files to git, and you're done!
class TestDataFiles

  constructor: (@testPath) ->
    extension = path.extname @testPath
    @dirname = path.dirname @testPath
    @basename = path.basename @testPath, extension

    @tmpdir = temp.mkdirSync()

  testFileExpect: (test, inputFile, expected, cb) ->
    test.expect expected
    testHandle = new RegTestHandle(this, inputFile)
    cb testHandle
    if not testHandle.compareFiles()
      testHandle.printFailureReport ->
        test.fail "File contents differed"
        test.done()
    else
      test.ok "No regressions in output"
      test.done()

  testFileExpectAsync: (test, inputFile, expected, cb) ->
    test.expect expected
    testHandle = new RegTestHandle(this, inputFile)
    cb testHandle, ->
      if not testHandle.compareFiles()
        testHandle.printFailureReport ->
          test.fail "File contents differed"
          test.done()
      else
        test.ok "No regressions in output"
        test.done()

  testFile: (test, inputFile, cb) ->
    @testFileExpect test, inputFile, 1, cb

  testFileAsync: (test, inputFile, cb) ->
    @testFileExpectAsync test, inputFile, 1, cb

class RegTestHandle

  constructor: (@testData, @inputFile) ->
    @inputPath = path.join @testData.dirname, 'test-data', @inputFile
    @observedOutputPath = path.join @testData.tmpdir, @inputFile
    fs.writeFileSync @observedOutputPath, ''
    @expectedOutputPath = path.join @testData.dirname, 'test-data', "#{ @inputFile }.expected"

  writeObservedOutput: (output) ->
    if output.charAt(output.length - 1) != '\n'
      output += '\n'
    fs.writeFileSync @observedOutputPath, output
    if process.env.UPDATE_REGTEST_DATA
      fs.writeFileSync @expectedOutputPath, output

  compareFiles: ->
    observed = fs.readFileSync @observedOutputPath, 'utf8'
    expected = fs.readFileSync @expectedOutputPath, 'utf8'
    return observed == expected

  printFailureReport: (cb) ->
    cmd = "diff #{ @observedOutputPath } #{ @expectedOutputPath } || true"
    child_process.exec cmd, { maxBuffer: 5 * 1024*1024 }, (error, stdout, stderr) =>
      if error
        console.error "Error running #{ cmd }:", error
        console.error stderr
      else
        console.log "Diff report for #{ @inputFile }"
        console.log stdout
      cb()

exports.TestDataFiles = TestDataFiles
