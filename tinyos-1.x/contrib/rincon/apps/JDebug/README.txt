This is JDebug v.2.0

It requires the /contrib/rincon/tools/com/rincon/jdebug Java app

It lets you write debug messages from your mote to your screen.

Here's some output from the test program that comes with it. The test program
simply demonstrates that it works and can output long, int, and short values
in decimal or hexadecimal format depending on what the text on your mote
says:
    compiled JDebugTestC to build/telosb/main.exe
           12796 bytes in ROM
             815 bytes in RAM
             
$ jdebug
JDebug Test 0x64=100 0xA=10 0x1=1
JDebug Test 0xC8=200 0x14=20 0x2=2
JDebug Test 0x12C=300 0x1E=30 0x3=3
JDebug Test 0x190=400 0x28=40 0x4=4
JDebug Test 0x1F4=500 0x32=50 0x5=5
JDebug Test 0x258=600 0x3C=60 0x6=6
JDebug Test 0x2BC=700 0x46=70 0x7=7
JDebug Test 0x320=800 0x50=80 0x8=8

The mote is running a timer incrementing numbers and printing them to your screen
with the command:

call JDebug.jdbg("JDebug Test %xl=%l %xi=%i %xs=%s", dlong, dint, dshort)



The cool thing about using this component to send debug messages is it
can buffer up a whole slew of messages to send by using the Transceiver component,
making sure all your messages get through.  Make sure your Makefile
points to the correct location of the Transceiver and State components. Just download
the Transceiver and State components to your system.  They should be compatible with
whatever else you've got running. 

Also make sure you allocate enough MAX_TOS_MSGS in the Transceiver component,
or at compile time by using the flag:

-DMAX_TOS_MSGS=10

10 or more is better than the default 4 for JDebug, but uses way more RAM.  I use 100+
on some of my apps.  That way, all my debug messages get through.

In your application, just include the JDebugC component and wire up the JDebug interface.

You can then print messages from your mote to your screen with the command:
call JDebug.jdbg("debug output: long=%l, hex long=%xl, int=%i, hex int=%xi, short=%s, hex short=%xs", 
    <uint32_t (long)>,
    <uint16_t (int)>,
    <uint8_t (short)>);

On your computer, you need to have an open serial forwarder connection to the mote,
and you need to be running the JDebug java app, which just sits there and gathers
messages and prints them to your screen.

Easy.  Let me know if you have questions.


David Moss
dmm@rincon.com