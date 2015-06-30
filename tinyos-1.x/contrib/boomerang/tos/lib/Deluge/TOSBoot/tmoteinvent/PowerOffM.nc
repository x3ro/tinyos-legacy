// $Id: PowerOffM.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $

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

module PowerOffM {
  provides {
    command void PluginStartup( tosboot_args_t* args );
  }
  uses {
    interface Leds;
    interface StdControl as SubControl;
    interface HPLUSARTControl;
    interface InternalFlash as IntFlash;
  }
}

implementation {

#define POT1_ADDR 0x2C
#define POT2_ADDR 0x2D
#define POT3_ADDR 0x2F

  void resetPotentiometer(uint8_t addr) {
    I2CSA = addr;
    I2CNDAT = 1;

    // start condition and stop condition need to be sent
    I2CTCTL |= (I2CSTP | I2CSTT);

    while ((I2CIFG & TXRDYIFG) == 0) ;
    I2CDR = 0x60; // reset command byte (reset pots, shutdown system)
    while ((I2CDCTL & I2CBB)) ;
  }    

  void disablePots() {
    static const uint8_t potAddrs[3] = { POT1_ADDR, POT2_ADDR, POT3_ADDR };
    const uint8_t* pot = potAddrs;
    const uint8_t* potEnd = potAddrs+3;

    for( ; pot != potEnd; pot++ ) {
      call HPLUSARTControl.setModeI2C();
      resetPotentiometer( *pot );
      call HPLUSARTControl.disableI2C();
    }
  }

  void deepSleep() {
    uint16_t _lpmreg;

    U0CTL = 0;
    _lpmreg = LPM4_bits;
    _lpmreg |= SR_GIE;
    for(;;) {
      __asm__ __volatile__( "bis  %0, r2" : : "m" ((uint16_t)_lpmreg) );
      wait(0xffff);
    }
  }

  void haltsystem() {
    call Leds.glow(0x7, 0x0);
    call SubControl.stop();
    disablePots();
    TOSH_SET_PIN_DIRECTIONS();
    deepSleep();
  }

  command void PluginStartup( tosboot_args_t* args ) {
    bool powerdown;

    if( !(args->flags & TOSBOOT_FLAGS_NOPOWERDOWN) ) {
      args->flags |= TOSBOOT_FLAGS_NOPOWERDOWN;
      call IntFlash.write((uint8_t*)TOSBOOT_ARGS_ADDR, args, sizeof(*args));
      powerdown = TRUE;
    }
    else {
      // wait a short period for things to stabilize
      // TOSH_MAKE_USERINT_INPUT();  // input by default
      longwait(4);
      powerdown = !TOSH_READ_USERINT_PIN();
    }

    // if user button is pressed, power down
    if( powerdown )
      haltsystem();
  }
}

