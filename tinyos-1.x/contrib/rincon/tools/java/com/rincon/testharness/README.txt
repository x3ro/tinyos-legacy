TestHarness provides support to test parts of an application
for PASS/FAIL and the time it took to run the test in ms.

It works with the com.rincon.testharness.TestHarness nesC program.

To use it, follow the TestTemplate format - 
 1. Create your test in a sub directory
 2. Make it provide the TestControl interface
 3. Implement the TestControl interface with whatever app you are testing to make it do whatever you want.
 4. After start is called and your app runs, when it's finished signal the complete(..) event with whatever
    parameters you want to show on the screen.
 4. Program up your mote with your test
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