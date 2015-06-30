CC2420 Radio Beta Project

- This directory houses a CC2420 based radio stack for beta testing
  new radio features/capabilities/interfaces for eventual rollup into
  the standard release

- Goal: Create a radio stack with hardware abstraction to run on any
  platform that has a CC2420Radio.  Initial supported platforms are
  avr (micaz) and msp430 (telos).

Structure of the CC2420 Radio Stack:

           CC2420RadioC
           |          |
           |          |
           v          v
   CC2420ControlM  CC2420RadioM
              |      |     |                 hardware abstraction
-----------------------------------------------------------------
              |      |     |
              v      v     v
             HPLCC2420C   uTimer/RandomLFSR

Interfaces:
  CC2420RadioC provides:
    StdControl - init/start/stop
    CC2420Control - control parameters of the radio
    BareSendMsg - Send messages
    ReceiveMsg - Receive messages
  CC2420ControlM provides:
    StdControl - init/start/stop
    CC2420Control - control parameters of the radio
  HPLCC2420C provides:
    StdControl - init/start/stop
   *HPLCC2420 - send command strobes, write registers, read registers
   *HPLCC2420FIFO - read RXFIFO into a buffer, write TXFIFO into CC2420

Provided by the CC2420 library (hardware independent):
  configurations
    CC2420RadioC
  modules
    CC2420RadioM
    CC2420ControlM
  interfaces
    CC2420Control
    HPLCC2420
    HPLCC2420FIFO

* interfaces implemented are hardware specific and implemented in
  platform/xxx and not by the CC2420 hardware abstracted library

- Timing
    An initial stack will be available by 2/28/2004 and moved to the
    main tree.  The CC2420 stack will be part of the TinyOS 1.1.5 release
    in late march.

- Project members/groups:
	  UCB (Joe Polastre)
          Crossbow (Alan Broad)
	  IRB (Phil Buonadonna)


- People to email on changes:
  Phil Buonadonna <pbuonado@intel-research.net>
  Joe Polastre <polastre@cs.berkeley.edu>
  Alan Broad <abroad@xbow.com>

