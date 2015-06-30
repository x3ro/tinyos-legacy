// $Id: PowerButtonM.nc,v 1.1 2004/11/06 05:17:01 jpolastre Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Joe Polastre <tinyos-help@millennium.berkeley.edu>

module PowerButtonM
{
  provides interface StdControl;
  uses {
    interface MSP430Interrupt as NMI;
    interface Leds;
  }
}
implementation
{
  bool on;

  void haltsystem();
  void shutdown();

  task void taskhaltsystem() {
    haltsystem();
  }

  void haltsystem() {
    int i;
    uint16_t _lpmreg;

    atomic {
      on=FALSE;
      TOSH_SET_PIN_DIRECTIONS();
    }

    call Leds.set(0);
    for (i = 1024; i > 0; i=i-4) {
	call Leds.set(0x7);
	TOSH_uwait(i);
	call Leds.set(0);
	TOSH_uwait(1024-i);
    }

    _lpmreg = LPM4_bits;
    _lpmreg |= SR_GIE;
    // re-enable NMI for the "turn on" command"
    atomic {
      call NMI.disable();
    }
    __asm__ __volatile__( "bis  %0, r2" : : "m" ((uint16_t)_lpmreg) );
  }

  void shutdown() {
    if (!post taskhaltsystem())
      haltsystem();
  }

  command result_t StdControl.init() {
    atomic {
      on = TRUE;
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    atomic {
      call NMI.disable();
      call NMI.clear();
      call NMI.edge(FALSE);
      call NMI.enable();
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    atomic {
      call NMI.disable();
      call NMI.clear();
    }
    return SUCCESS;
  }

  async event void NMI.fired() {
    if (on) {
      shutdown();
    }
  }

}
