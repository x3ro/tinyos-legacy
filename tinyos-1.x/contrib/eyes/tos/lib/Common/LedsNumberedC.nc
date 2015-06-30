/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Controls the LEDs on the Infineon node
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/01/26 14:13:59 $
 * @author: Vlado Handziski
 * ========================================================================
 */
module LedsNumberedC {
  provides interface LedsNumbered;
}

implementation
{
  uint8_t ledsOn;

  enum {
    LED0_BIT = 1,
    LED1_BIT = 2,
    LED2_BIT = 4,
    LED3_BIT = 8
  };

  async command result_t LedsNumbered.init() {
    atomic {
      ledsOn = 0;
      dbg(DBG_BOOT, "LEDS: initialized.\n");
      TOSH_CLR_LED0_PIN();
      TOSH_CLR_LED1_PIN();
      TOSH_CLR_LED2_PIN();
      TOSH_CLR_LED3_PIN();
    }
    return SUCCESS;
  }


  async command result_t LedsNumbered.led0On() {
    dbg(DBG_LED, "LEDS: Led0 on.\n");
    atomic {
      TOSH_SET_LED0_PIN();
      ledsOn |= LED0_BIT;
    }
    return SUCCESS;
  }

  async command result_t LedsNumbered.led0Off() {
    dbg(DBG_LED, "LEDS: Led0 off.\n");
     atomic {
       TOSH_CLR_LED0_PIN();
       ledsOn &= ~LED0_BIT;
     }
     return SUCCESS;
  }

  async command result_t LedsNumbered.led0Toggle() {
    result_t rval;
    atomic {
      if (ledsOn & LED0_BIT)
	rval = call LedsNumbered.led0Off();
      else
	rval = call LedsNumbered.led0On();
    }
    return rval;
  }

  async command result_t LedsNumbered.led1On() {
    dbg(DBG_LED, "LEDS: Led1 on.\n");
    atomic {
      TOSH_SET_LED1_PIN();
      ledsOn |= LED1_BIT;
    }
    return SUCCESS;
  }

  async command result_t LedsNumbered.led1Off() {
    dbg(DBG_LED, "LEDS: Led1 off.\n");
     atomic {
       TOSH_CLR_LED1_PIN();
       ledsOn &= ~LED1_BIT;
     }
     return SUCCESS;
  }

  async command result_t LedsNumbered.led1Toggle() {
    result_t rval;
    atomic {
      if (ledsOn & LED1_BIT)
	rval = call LedsNumbered.led1Off();
      else
	rval = call LedsNumbered.led1On();
    }
    return rval;
  }

  async command result_t LedsNumbered.led2On() {
    dbg(DBG_LED, "LEDS: Led2 on.\n");
    atomic {
      TOSH_SET_LED2_PIN();
      ledsOn |= LED2_BIT;
    }
    return SUCCESS;
  }

  async command result_t LedsNumbered.led2Off() {
    dbg(DBG_LED, "LEDS: Led2 off.\n");
     atomic {
       TOSH_CLR_LED2_PIN();
       ledsOn &= ~LED2_BIT;
     }
     return SUCCESS;
  }

  async command result_t LedsNumbered.led2Toggle() {
    result_t rval;
    atomic {
      if (ledsOn & LED2_BIT)
	rval = call LedsNumbered.led2Off();
      else
	rval = call LedsNumbered.led2On();
    }
    return rval;
  }

  async command result_t LedsNumbered.led3On() {
    dbg(DBG_LED, "LEDS: Led3 on.\n");
    atomic {
      TOSH_SET_LED3_PIN();
      ledsOn |= LED3_BIT;
    }
    return SUCCESS;
  }

  async command result_t LedsNumbered.led3Off() {
    dbg(DBG_LED, "LEDS: Led3 off.\n");
     atomic {
       TOSH_CLR_LED3_PIN();
       ledsOn &= ~LED3_BIT;
     }
     return SUCCESS;
  }

  async command result_t LedsNumbered.led3Toggle() {
    result_t rval;
    atomic {
      if (ledsOn & LED3_BIT)
	rval = call LedsNumbered.led3Off();
      else
	rval = call LedsNumbered.led3On();
    }
    return rval;
  }


  async command uint8_t LedsNumbered.get() {
    uint8_t rval;
    atomic {
      rval = ledsOn;
    }
    return rval;
  }

  async command result_t LedsNumbered.set(uint8_t ledsNum) {
    atomic {
      ledsOn = (ledsNum & 0xF);
      if (ledsOn & LED0_BIT)
	TOSH_SET_LED0_PIN();
      else
	TOSH_CLR_LED0_PIN();
      if (ledsOn & LED1_BIT )
	TOSH_SET_LED1_PIN();
      else
	TOSH_CLR_LED1_PIN();
      if (ledsOn & LED2_BIT)
	TOSH_SET_LED2_PIN();
      else
	TOSH_CLR_LED2_PIN();
      if (ledsOn & LED3_BIT)
	TOSH_SET_LED3_PIN();
      else
	TOSH_CLR_LED3_PIN();
    }

    return SUCCESS;
  }
}
