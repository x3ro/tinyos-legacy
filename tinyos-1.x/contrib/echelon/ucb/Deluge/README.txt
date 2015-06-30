README for Deluge Network Reprogramming Demonstration

This directory contains all of the necessary components to run the
demonstration of the Deluge Network Reprogramming system. For basic
installation instructions for Deluge, read README-Deluge.txt first.

** TestDeluge TinyOS Program

This program is the one you should actually compile and install on the
motes. The Makefile includes each of the necessary components. For the
purposes of our demo, the Makefile sets the AM Group ID to a unique
value. Please be aware of this, and modify if necessary.

** Deluge TinyOS Library

This is the actual Deluge code. By default, the code runs as a pure
network reprogramming service. If you define DELUGE_REPORTING_MHOP,
then Deluge will use the MintRoute library to send progress reports as
the dissemination runs. This is necessary for the demo, so
TestDeluge/Makefile defines DELUGE_REPORTING_MHOP.

** Deluge Visualiser (Surge)

The "surge" directory contains a copy of the Surge network visualiser
with all of the necessary modifications to interpret the progress
reports sent by DELUGE_REPORTING_MHOP.

Copy the surge directory to "tinyos-1.x/tools/java/net/tinyos", or any
other net.tinyos directory in your CLASSPATH. You also need to be sure
that this is the only copy of "surge" existing in the classpath. This
will probably require renaming the "surge" directory that arrives in
the standard tree.

To compile Surge, run make in the "surge" directory after copying it.
NOTE: your TinyOS tree needs to have the "contrib" section installed
in order to compile this fork of Surge, because it depends on the
existence of a TinyOS header file in a subdirectory of "contrib/xbow". 

To run the visualizer, connect a Serial Forwarder to Mote 0, by serial
or Ethernet, then execute "java net.tinyos.surge.MainClass <group ID>".

** MintRoute and Queue TinyOS Libraries

Correct operation of DELUGE_REPORTING_MHOP requires these slightly
modified versions of the standard MintRoute and Queue libraries.
TestDeluge/Makefile points to these modified versions, instead of the
versions in "tinyos-1.x/tos/lib". The new version of Queue fixes a
serious bug, so you may be interested in replacing your version of the
standard Queue with this version. Eventually these changes will make
it into the real tree, but for now, Deluge depends on these copies.

Mail Gilman Tolle <get@eecs.berkeley.edu> with questions.





