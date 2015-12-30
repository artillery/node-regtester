# regtester

A library for doing simple input/output based regression tests.

The library exports a single class, `TestDataFiles`, which handles creation of a temporary
output directory, comparison of the observed output to the expected output, and automatically
printing the diff if the files don't match.

To use:

Install:

     npm install regtester

First, put your input files (if any) in a `test-data` directory,
within the directory that contains your test, e.g.:

     something/something/lib/test
     \_ regtest.coffee
     \_ test-data
       \_ myinputfile

Next, write your test (assumes nodeunit, see below for other test frameworks):

    var TestDataFiles = require('regtester').TestDataFiles;
    exports.setUp = function(cb) {
      this.testData = new TestDataFiles(__filename);
      cb();
    }

    // import the function you want to test.
    var processFile = require('./the-module-under-test').processFile;

    exports.testRegtest = function(test) {
      this.testData.testFile(test, 'myinputfile', function(testHandle) {
        var results = processFile(testHandle.inputPath);
        testHandle.writeObservedOutput(results);
      });
    }

Now, generate your expected output:

     $ UPDATE_REGTEST_DATA=1 nodeunit regtest.coffee

The expected output is stored in the test-data directory:

     something/something/lib/test
     \_ regtest.coffee
     \_ test-data
       \_ myinputfile
       \_ myinputfile.expected

Run the test again, it should pass:

    $ nodeunit regtest.coffee

If you like, change `myinputfile.expected`, and verify that the test fails.
Add all the new files to git, and you're done!

## nodeunit

regtester assumes that you're using nodeunit. If you want to use another framework, you'll
need to pass in an object providing the functions normally provided by nodeunit's `test` handle.

For example:

    var testStub = {
      expect: function(n) { /* expect n calls to `ok` before `done` is called */ }
      fail: function(msg) { /* print msg, cause test to fail */ },
      done: function() { /* signals that the test is over (test may be async) */ }
      ok: function(msg) { /* asserts that a particular point in the test was reached */ }
    };

    testData.testFile(testStub, 'myinputfile', function(testHandle) { ... });

