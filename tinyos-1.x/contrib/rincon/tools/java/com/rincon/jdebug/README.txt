This is JDebug v.2.0

It uses the Transceiver to do all the message buffering.  Make sure your Makefile
points to the correct location of the Transceiver and State components. Just download
the Transceiver and State components to your system.  They should be compatible with
whatever else you've got running. 



The cool thing about using this component to send debug messages is it
can buffer up a whole slew of messages to send by using the Transceiver component,
making sure all your messages get through.  

Make sure you allocate enough MAX_TOS_MSGS in the Transceiver component,
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