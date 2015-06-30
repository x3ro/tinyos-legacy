README for RadioCountToLeds
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

RadioCountToLeds maintains a 4Hz counter, broadcasting its value in 
an AM packet every time it gets updated. A RadioCountToLeds node that 
hears a counter displays the bottom three bits on its LEDs. This 
application is a useful test to show that basic AM communication and 
timers work.

Tools:

After compiling, RadioCountMsg.java and RadioCountMsg.py files will be
created.  RadioCountMsg.java is a Java class representing the message that
this application sends.  RadioCountMsg.py is a Python class representing
the message that this application sends.

Known bugs/limitations:

None.


$Id: README.txt,v 1.2 2009/02/14 00:07:37 rfonseca76 Exp $
