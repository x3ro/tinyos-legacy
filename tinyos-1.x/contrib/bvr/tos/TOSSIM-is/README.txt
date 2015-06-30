Internal Interrupt

Rodrigo Fonseca

Internal interrupt is a mechanism for scheduling custom events into the event
queue of TOSSIM. This is the fastest way to allow "scripting" of experiments.
To use, include the directory so that these files are linked instead of the
TOSSIM-packet files.

USING:
  1. Configure TOSSIM-packet, as described in tinyos-1.x/beta/TOSSIM-packet
  2. Add two include statements to your Makefile, and *make sure they appear
     before the TOSSIM-packet directory*:

     -I. -I(this directory)

     For example, the TestBVRSimple Makefile reads:

ifeq ($(PLATFORM), pc)
PFLAGS += -I. -I../../tos/TOSSIM-is -I%T/../beta/TOSSIM-packet
endif

  3. If you want this to do anything useful, you have to implement the
     functionality in a file called internal_interrupt.c. Again, in 
     TestBVRSimple there are a couple of such files. Choose one, and
     copy (or link) it to internal_interrupt.c. E.g.:
     
     >cd TestBVRSimple
     >ln -s internal_interrupt.regular.c internal_interrupt.c
  
  4. Things should work now.

The internal_interrupt.c in this directory is an empty template. You can copy
it to your application directory and redefine the handler for INT_EVENT_FIRST
and the main internalInterruptHandler. You can define any uint32_t id for the
event id, and create handler functions dispatched from the main handler.

Again, look at the examples are in the TestBVRSimple directory.

