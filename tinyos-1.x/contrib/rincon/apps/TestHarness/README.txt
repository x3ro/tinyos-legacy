TestHarness provides support to test parts of an application
for PASS/FAIL and the approximate time it took to run the test in ms.

Here's an example of the output from the TestTemplate app:

See if the TestHarness is ready to go:
$ test -ping
Pong!
Total time: 16.0[ms]; 0.016[s]

Run some tests with the template. 
Keep in mind the mote is running in binary milliseconds,
and your computer is running in regular old milliseconds.  
So 1024 bms on the mote == 1000 ms on the computer.  I notice a 15-16 ms
delay average on my machine, which I work out of the equation by
averaging up a few tests, averaging up a few delay offsets using the template app,
and removing the delay in my analysis.

$ test -start 1024
Done
Success
Test Return Value = 1
Total time: 1015.0[ms]; 1.015[s]

$ test -start 2048
Done
Success
Test Return Value = 2
Total time: 2016.0[ms]; 2.016[s]


It requires the com.rincon.testharness.TestHarness java program located in
/contrib/rincon/tools/com/rincon/testharness

You compile the application from the actual test's directory you're testing.

To make a new test for your app, follow the TestTemplate format - 
 1. Create your test in a sub directory
 2. Make it provide the TestControl interface
 3. Implement the TestControl interface with whatever app you are testing to make it do whatever you want.
 4. After start is called and your app runs, when it's finished signal the complete(..) event with whatever
    parameters you want to show on the screen.
    Also, get a Makefile in there.
 4. Program up your mote with your test, compiling from the test's directory, not the main directory.
 5. Connect with serial forwarder, running the TestHarness java program
    in com.rincon.testharness.TestHarness.  You can -ping the mote
    to see if it has the test harness app installed, and you can
    start a test. When the test is finished, you'll see if it passed
    or failed and how long it took to run, and any value it passed back.

Make sure you have the Transceiver and State components downloaded to your computer, and that
the Makefile points to their correct locations.  They'll work with your current setup but
provide some extra features for transmitting messages.


Also, if you have a TOSBase or BaseStation or whatever connected to your computer, you can
actually have your test mote sitting off on the side.  The BaseStation mote will forward
the command from the computer, your mote under test will perform the test and automatically
respond back via radio.

David Moss
dmm@rincon.com