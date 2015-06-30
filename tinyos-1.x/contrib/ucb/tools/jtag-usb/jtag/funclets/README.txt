Funclets
--------
A funclet is a small programm that is downloaded to the MSP430 RAM and
is executed there. They are used for erase and write operations in the
parallel port JTAG library MSP430mspgcc.dll/so.

A funclet must have a special memory layout. It cannot use any interrupts
and it has to setup everything itself. There is no stack init, no variable
init and no library.

Of course they need to be small, so that they fit in the RAM of smaller
devices (256B or even 128B).

As a further restriction every funclet must end with a "jmp $" instruction.
This is used by the download library to detect if the funclet is finished.
Only one such exit is allowed as the end address has to be given in the
table (see below).

Memory Layout
-------------
Funclets usualy start at 0x200, but that is optional.
All entries are words (unsigned short /.word):
    download address
    start address of executable code
    end address, where the final "jmp $" is located.
    ...optional space for arguments...
    executable code of any size
    jmp $
    ...optional space for data...

Look at the files .S, it's may be easier to get the facts when looking at
actual sources.

Building
--------
To build funclets, a special linker script is needed to place code in the RAM.
The file msp430xRAM.x contains the needed changes. It's written for 2k RAM so
you won't get any errors when compiling for a smaller device.

Usage
-----
Look at the sources and at the makefile for more information on how to
build them.

They can be run with the -f or --funclet option of jtag.py
Example:
    jtag.py -f blinking.a43

To embed the funclets in the download libarary, the code must be translated
into a C array. This is done by converting a Intel-Hex with ihex2c.py.


part of http://mspgcc.sf.net
 chris <cliechti@gmx.net>
