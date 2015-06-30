
Deluge 2.0 Tools

By default, the Makefile attempts to compile Deluge tools using the
telosb platform. If you do not have the telos platform tools installed
and would like to compile for use with the mica platforms, do the
following:

In tinyos-1.x/tools/java/net/tinyos/deluge/Makefile, change:
  DELUGE_PLATFORM=telosb
to:
  DELUGE_PLATFORM=mica2
and comment out the include for CC2420Radio:
  -I$(TOS)/lib/CC2420Radio
