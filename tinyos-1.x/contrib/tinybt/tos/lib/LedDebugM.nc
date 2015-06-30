/*
  LedDebug interface - provides an interface to "debugging" with 
  the leds.

  Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/
/**
 * Define an interface for displaying debug output on the Leds, and
 * also fail while repeating a pattern. */
module LedDebugM {
  provides {
    interface LedDebugI as LedDebug;
  }
  uses {
    interface IntOutput as IntOutput;
  }
}

implementation {
  /**
   * Handle the int output complete event .. */
  event result_t IntOutput.outputComplete(result_t succes) {
    return SUCCESS;
  }
  
  /** 
   * Set the leds.
   *
   * Will set the leds (all four for the btnode) in the pattern of the
   * low four bits of the parameter.  
   *
   * @param code The pattern to set the leds, in the least significant four bits. */
  async command void LedDebug.debug(int code) {
    atomic {
      // INT_DISABLE; /* Reverse the code */
      code = code^0xFFFF;
      /* Set the output */
      call IntOutput.output(code);
      if (code & 0x8) {
	TOSH_CLR_EXTRA_LED_PIN();
      } else {
	TOSH_SET_EXTRA_LED_PIN();
      }
    }
    // INT_ENABLE;
  }
  
  /**
   * Delay approximately 0.5 sec.
   *
   * <p>This function loops a number of times, doing <code>nop</code>. This is
   * used after crashing, so we can not use the clock or interrupts. */
  static void delay() {
    long j;
    for (j=0 ; j<=1356648/2 ; j++) {//app 0.5 s at 7 Mhz
      asm volatile ("nop"::);
    }
  }
  /** Used to store the values that are flashed after failing. */
  static uint8_t failparams[5];
  
  /**
   * Fail hard while flashing leds.
   *
   * <p>Flash in a pattern; first all leds are turned off. Then each
   * of the patterns are displayed. Then over again, forever.</p>
   *
   * <p>Use the FAIL* macros to actuall call, and use the #defined
   * values to as parameters. If the first parameter needs to indicate
   * a Bluetooth devicde, then or it with <code>bt_dev_0</code> or
   * <code>bt_dev_1</code>. Remeber to organize the parameters such that
   * you avoid flashing the same value twice in succesion. You will not be 
   * able to tell the difference....</p>
   *
   * <p>See also the program <code>decode_status.pl</code> that can be used
   * to decode the error codes.</p>
   *
   * @param numparams the number of params in the params array */
  static void fail(uint8_t numparams) {
    uint8_t i;
    /* Reverse the patterns */
    for (i = 0; i < numparams; i++) {
      failparams[i] = failparams[i]^0xFFFF;
    }
    
    delay();
    delay();

    /* Flash for ever */
    while(1) {
      /* Clear all */
      TOSH_CLR_EXTRA_LED_PIN();
      atomic {
	call IntOutput.output(7);
      }
      delay();
      delay();
      delay();
      delay();
      
      /* Now, each of the params */
      for(i = 0; i < numparams; i++) {
	if (failparams[i] & 0x8) {
	  TOSH_CLR_EXTRA_LED_PIN();
	} else {
	  TOSH_SET_EXTRA_LED_PIN();
	}
	atomic {
	  call IntOutput.output(failparams[i]);
	}
	delay();
      }
    }
  }

  async command void LedDebug.fail2(uint8_t a, uint8_t b) {
    atomic {
      failparams[0] = a; 
      failparams[1] = b; 
      fail(2); 
    }
  };

  async command void LedDebug.fail3(uint8_t a, uint8_t b, uint8_t c) {
    atomic {
      failparams[0] = a; 
      failparams[1] = b; 
      failparams[2] = c; 
      fail(3); 
    }
  };
  
  async command void LedDebug.fail4(uint8_t a, uint8_t b, uint8_t c, uint8_t d) {
    atomic {
      failparams[0] = a; 
      failparams[1] = b; 
      failparams[2] = c; 
      failparams[3] = d; 
      fail(4); 
    }
  };

  async command void LedDebug.fail5(uint8_t a, uint8_t b, uint8_t c, uint8_t d, uint8_t e) {
    atomic {
      failparams[0] = a; 
      failparams[1] = b; 
      failparams[2] = c; 
      failparams[3] = d; 
      failparams[4] = e; 
      fail(5); 
    }
  };
}
