/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Generic button handling code with button press detect.  See the 
 * <tt>Button</tt> interface.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
generic module ButtonM() {
  provides interface Button;
  uses interface Timer2<TMilli> as Timer;
  uses interface LocalTime<TMilli>;
  uses interface MSP430Interrupt;
}
implementation {

  norace uint8_t flags; // all uses are bit set/clr and read (atomic)

  enum {
    TIME_DEBOUNCE = 50,
  };

  enum {
    FLAG_TASKPOSTED = 0x01,
    FLAG_EDGE_LOW = 0x02,
  };

  async command void Button.enable() {
    atomic {
      call MSP430Interrupt.disable();
      call MSP430Interrupt.clear();
      call MSP430Interrupt.edge(FALSE);
      call MSP430Interrupt.enable();
      flags |= FLAG_EDGE_LOW;
    }
  }

  async command void Button.disable() {
    call MSP430Interrupt.disable();
  }

  task void startDebounceTimer() {
    call Timer.startOneShot( TIME_DEBOUNCE );
  }

  event void Timer.fired() {
    flags &= ~FLAG_TASKPOSTED;
    call MSP430Interrupt.edge(FALSE);
    call MSP430Interrupt.enable();
  }

  async event void MSP430Interrupt.fired() {
    uint32_t time = call LocalTime.get();
    call MSP430Interrupt.disable();
    call MSP430Interrupt.clear();

    if (flags & FLAG_EDGE_LOW) {
      call MSP430Interrupt.edge(TRUE);
      call MSP430Interrupt.enable();
      signal Button.pressed(time);
    }
    else {
      if (!(flags & FLAG_TASKPOSTED))
	if (post startDebounceTimer() == SUCCESS)
	  flags |= FLAG_TASKPOSTED;
      signal Button.released(time);
    }

    flags ^= FLAG_EDGE_LOW;

  }

}
