//$Id: HCS08Timer1M.nc,v 1.1 2006/01/16 18:43:17 janflora Exp $

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

// @author Cory Sharp <cssharp@eecs.berkeley.edu>
// Adapted to evb13192 by Mads Bondo Dydensborg
// NB: This module uses Timer2, even though it is named Timer1. We may fix this
// eventually....
// NB: I believe this module assumes an 8 MHz BUSCLK!
module HCS08Timer1M
{
  provides interface StdControl;
  provides interface HCS08Timer1 as ClockFast;
  provides interface HCS08Timer1 as ClockSlow;
}
implementation
{
  enum
  {
    // each count is in units of 2us
    COUNT_FAST = 25,  
    COUNT_SLOW = 500, 
  };

  command result_t StdControl.init()
  {
    // TPM2SC = 0x05;    // Timer 1 - Cleared + Stopped.
		      //    Clicks once every 32 BUS Cycles
    TPM2SC = 0x04;    // Timer 1 - Cleared + Stopped. 
		      //    Clicks once every 16 BUS Cycles

    TPM2C0V = 1;      // Set Output Compares to initially happen in a short
    TPM2C1V = 1;      // time after we start the timer.

    // TPM2C0SC = 0x54;  // Timer 1 Channels 0 and 1
    // TPM2C1SC = 0x54;  // Set for Output Compare operation.

    TPM2C0SC = 0x50;  // MBD: Timer 1 Channels 0 and 1
    TPM2C1SC = 0x50;  // Set for no pin out - conflicts with leds.
    // May need to debug this later - they triggered in sync, I think.

    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    TPM2SC |= 0x08; //select the bus clock
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    TPM2SC &= (~0x18); //no clock, disabled
    return SUCCESS;
  }

  TOSH_SIGNAL(TPM2CH0)
  {
    TPM2C0SC &= 0x7f; // Clear O.C. Flag
    TPM2C0V += COUNT_FAST; // Setup interrupt in 50us more
    signal ClockFast.fired();
  }

  TOSH_SIGNAL(TPM2CH1)
  {
    TPM2C1SC &= 0x7f; // Clear O.C. Flag
    TPM2C1V += COUNT_SLOW; // Setup interrupt in 1ms more
    signal ClockSlow.fired();
  }

  default async event void ClockFast.fired()
  {
  }

  default async event void ClockSlow.fired()
  {
  }
}

