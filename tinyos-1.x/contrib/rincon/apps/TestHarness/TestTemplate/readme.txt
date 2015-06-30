This is a template to get started in building a test.
The test module implements the TestControl interface.

You can even compile this and run it to see how it works.

1. compile it to the mote.
2. running com.rincon.testharness.TestHarness (and I alias that to just "test") use a command like:

test -start 1024

That will make your test run a timer that lasts for 1024 binary milliseconds, so in 1 second, you should
get a response from the mote saying the test passed and the computer's system time will show how much
time elapsed from the start to finish.

Very useful for analyzing algorithms and functions in your applications.

David Moss
dmm@rincon.com