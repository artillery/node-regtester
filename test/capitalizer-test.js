#!/usr/bin/env node

var TestDataFiles = require('../index.js').TestDataFiles;
var readFileCapitalized = require('./capitalizer.js').readFileCapitalized;

exports.testReadFileCapitalized = function(test) {
  var testData = new TestDataFiles(__filename);

  testData.testFile(test, 'input-file', function(testHandle) {
    var results = readFileCapitalized(testHandle.inputPath);
    testHandle.writeObservedOutput(results);
  });
}

exports.testReadFileCapitalizedFailure = function(test) {
  var testData = new TestDataFiles(__filename);

  // Intercept calls to the test handle so we can assert that a failure occurred,
  // rather than failing when the failure occurs.
  var failures = 0;
  var failureTest = {
    ok: function(msg) {},
    expect: function(n) {},
    fail: function(msg) {
      failures++;
    },
    done: function() {
      test.equal(failures, 1);
      test.done();
    },
  };

  testData.testFile(failureTest, 'input-file-failure', function(testHandle) {
    var results = readFileCapitalized(testHandle.inputPath);
    testHandle.writeObservedOutput(results);
  });
}
