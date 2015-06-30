/*
 * Copyright (c) 2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Testing a Kobitone Audio Transducer
 *
 * The device is connected via a FET to P1.7 on the MSP.
 *
 * Andrew Christian <andrew.christian@hp.com>
 * May 2005
 */

module AudioTransducerM {
  provides {
    interface StdControl;
  }
  uses {
    interface MSP430Interrupt as UserInt;
    interface Leds;
    interface Timer;
    interface MSP430TimerControl as PWMControl;
    interface MSP430Compare as PWMCompare;
  }
}
implementation {
  uint8_t g_leds;
  int g_pwm;

  command result_t StdControl.init() 
  {
    TOSH_CLR_ADC0_PIN();
    TOSH_CLR_ADC1_PIN();
    TOSH_CLR_ADC2_PIN();

    TOSH_MAKE_ADC0_OUTPUT();
    TOSH_MAKE_ADC1_OUTPUT();
    TOSH_MAKE_ADC2_OUTPUT();

    TOSH_CLR_HUM_PWR_PIN();
    TOSH_MAKE_HUM_PWR_OUTPUT();
    TOSH_MAKE_HUM_SCL_INPUT();
    TOSH_MAKE_HUM_SDA_INPUT();

    call Leds.init();
    return SUCCESS;
  }



  command result_t StdControl.start()
  {
    atomic {
      call UserInt.disable();
      call UserInt.clear();
      call UserInt.edge(FALSE);
      call UserInt.enable();
    }

    call PWMControl.setControlAsCompare();
    call PWMCompare.setEventFromNow( 1000 );
    //    call PWMControl.enableEvents();

    call Timer.start( TIMER_REPEAT, 100 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    call PWMControl.disableEvents();

    atomic {
      call UserInt.disable();
      call UserInt.clear();
    }
    return SUCCESS;
  }

  int freq_table[8] = { 0, 
			180,  // 2.7 kHz
			220, 
			260, 
			300,
			340,
			380,
			420
  };

  async event void UserInt.fired() 
  {
    g_leds++;
    if ( g_leds > 7 )
      g_leds = 0;

    if ( g_leds == 1 ) {  // Enable the tmier
      call PWMCompare.setEventFromNow( 100 );
      call PWMControl.enableEvents();
    }

    call Leds.set( g_leds & 0x07 );
    call UserInt.clear();
  }

  async event void PWMCompare.fired()
  {
    int delta = freq_table[g_leds];

    TOSH_SET_ADC1_PIN();

    if ( !delta )
      call PWMControl.disableEvents();

    if ( g_pwm || delta == 0 ) {
      TOSH_CLR_HUM_PWR_PIN();
      g_pwm = 0;
    }
    else {
      TOSH_SET_HUM_PWR_PIN();
      g_pwm = 1;
    }

    if ( delta )
      call PWMCompare.setEventFromNow( delta );

    TOSH_CLR_ADC1_PIN();
  }

  event result_t Timer.fired()
  {
    TOSH_SET_ADC0_PIN();
    TOSH_CLR_ADC0_PIN();
    return SUCCESS;

  }
}


