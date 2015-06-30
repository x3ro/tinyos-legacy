README for Tsync 
Author/Contact: herman@cs.uiowa.edu (Ted Herman, OSU Group, @ Iowa)

Description:

Here you'll find the TsyncC component (and its helpers, the
AlarmC component, plus some customized Clock and Timer implementations).

The files Tsync.tex and Tsync.pdf explain its design.

The NestArch supported interface is called "Time".

The customization of Clock is to support a new interface;  the 
standard Clock interface is unchanged -- only a new ReadClock
interface has been added.

*** WARNING ****  I'm using Vanderbilt's Clock and Timer
components for this version.  Also, I've stepped up the Timer
frequency to firing every 2 milliseconds.  This could be a 
performance burden;  it's easy to change this to any larger
desired period, but then the accuracy mentioned below may
change.

The TsyncM implementation supports Time and StdControl interfaces.
It was developed using GenericComm to send and receive messages, 
but any equivalent interface could easily be wired in.

The Leds interface is used just for debugging.  A test application
(which does nothing) has also been included.  Running this test
application along with a base station is useful for observing 
behavior of Tsync.  If you "make mica install.0" you get a 
basestation mote for observing beacons from other Tsync motes.

Tools:

The Java program spy.java can be set up, using say the SerialForward,
to print Tsync's Beacon messages and watch the time pass.  Use the
"mica install.0" as the basestation for spy.

Known bugs/limitations:

The constant BOUND_DIAMETER, defined in Beacon.h, sets an upper 
bound on the number of hops between motes in the network.  This is
used to detect "root mote" failure and elect a new root, using the
standard "count to infinity" method of distance-vector routing
algorithms.  However, after time has been synchronized, there isn't
any catastrophic consequence of loops implied by hop-distance fields
-- these are mainly used for eventual stability of time.

I conjecture that motes are synchronized to within somewhere around
(2.5 * d) milliseconds of the "root mote", which is the mote with
the least Id in the network, where d is the number of hops to reach
the root mote.  This version corrects for MAC delay of Beacon messages,
and my measurements show a 2.5 millisecond agreement (on average; it
varies nondeterministically up to about 10 milliseconds sometimes 
during execution, but then self-corrects;  the oscillation is like
TCP congestion window behavior).  I calibrated the inherent drift
of a typical mote to be about 0.01 percent in a minute by comparison 
to a GPS pulse (my developmental version provides
a hook to a GPS, see forGPS). 

Several constants in TsyncM's StdControl.start and mainTask() 
define the frequency of Beacon messages.  This should be tuned
based on experience.  Too slow implies that synchronization and
fault tolerance occur slowly.  Too fast means more overhead, 
disrupting other components.
