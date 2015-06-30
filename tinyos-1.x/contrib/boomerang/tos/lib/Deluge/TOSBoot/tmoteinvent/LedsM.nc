// $Id: LedsM.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#include "longwait.h"

module LedsM {
  provides interface Leds;
  provides interface StdControl;
  uses interface HPLUSARTControl;
}

implementation {

#define MAX7315_ADDR 0x20

  void transmit(uint8_t cmd, uint8_t val) {
    I2CSA = MAX7315_ADDR;
    I2CNDAT = 2;

    // start condition and stop condition need to be sent
    I2CTCTL |= (I2CSTP | I2CSTT);

    while ((I2CIFG & TXRDYIFG) == 0) ;
    I2CDR = cmd;
    while ((I2CIFG & TXRDYIFG) == 0) ;
    I2CDR = val;
    while ((I2CDCTL & I2CBB)) ;
  }

  command void Leds.set(uint8_t ledsOn) {
    call HPLUSARTControl.setModeI2C();
    transmit(0x01, ~ledsOn);
    call HPLUSARTControl.setModeSPI();
  }

  command void Leds.flash(uint8_t a) {
    uint8_t i;
    uint8_t atoggle = 0;
    for ( i = 6; i; i-- ) {
      call Leds.set( atoggle^=a );
      longwait(4);
    }
  }

  command void Leds.glow(uint8_t a, uint8_t b) {
    int i;
    for (i = 1536; i > 0; i -= 4) {
      call Leds.set(a);
      wait(i);
      call Leds.set(b);
      wait(1536-i);
    }
  }

  command result_t StdControl.init() {
    //call HPLUSARTControl.disableSPI(); // removing this line adds 30 bytes!
    call HPLUSARTControl.setModeI2C();
    // set output
    transmit(0x03, ~0x07);
    //call HPLUSARTControl.disableI2C();
    call HPLUSARTControl.setModeI2C(); //why is this line necessary? to flush the i2c bus?
    // turn all leds off
    transmit(0x01, ~0x00);
    call HPLUSARTControl.setModeSPI();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

}
