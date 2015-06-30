$Id: README.txt,v 1.1 2004/12/03 23:55:10 szewczyk Exp $

README for JTAG support over USB for Telos rev B. 

Description: 

The goal of this set of tools is to provide JTAG interface support over the
USB connection for Telos rev. B.   At the current time, only the publicly
documented functions from TI are supported -- as a result JTAG interface may
primarily be used to program the device.  The end result is to produce a
replacement for the MSP430mspgcc.dll that will talk to USB device directly;
that library can then be linked against msp430-jtag and other Python-based
tools from mspgcc developers. 

To install these tools, you will need 
- Telos rev B
- FTDI D2XX drivers (a version of them is included in this repository)

Installation:

1.  Uninstall FTDI VCP drivers:
    - unplug all Telos devices
    - open Control Panel\Add/Remove Programs
    - Select FTDI VCP drivers
    - click on uninstall
2. If you're using Windows XP, unplug the machine from any Internet
connections
3. Plug in Telos.  When asked for a driver, point the driver installation to
the D2XX drivers (included in this directory, under d2xx). 
4. Import FTDI drivers into the development enironment in cygwin
    - cd to d2xx
    - run:
      make; make install
5. Build the libraries:
    - cd to jtag
    - run make

Tools:

These libraries are meant to be used by developers.  Python msp430-jtag is an
example of a tool that uses the MSP430mspgcc library.  Make sure that you have
ctypes installed. 

Known bugs/limitations:

Currently the erase functionality has been verified -- that involves a pass
through most of the functions exported by the interface.  More testing and
stress testing is needed, but this is a reasonable time to check it into
contrib, before my machine dies a horrible death. 

