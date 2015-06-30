// $Id: VoltageCheckM.nc,v 1.8 2005/08/24 17:57:39 gtolle Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/*
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module VoltageCheckM {
  provides {
    interface PowerSource;
    interface SplitInit as Init;
  }
  uses {
    interface ADC;
    interface ADCControl;
    interface StdControl as Sounder;
    interface Timer;
    interface StdControl as Battery;
    interface VoltageStatus;
  }
}

implementation {

  enum {
    //VTHRESH_HI = 2228, // 2.72 Volts
    //VTHRESH_LO = 2212, // 2.70 Volts
    //VTHRESH_HI = 3714, // 2.72 Volts
    VTHRESH_HI = 3755, // 2.75 Volts
    VTHRESH_LO = 3686, // 2.70 Volts
    CHIRP_COUNT = 3,

    CAP_RUN_LOW = VTHRESH_HI,
    CAP_RUN_HIGH = 2048, // 3.0 Volts
  };

  enum {
    S_WAIT,
    S_WAIT_SOUNDER,
    S_SOUNDER_ON,
    S_SIGNAL,
    S_ON,
  };
  
  uint16_t voltage;
  uint8_t state;
  bool sounderOn;

  uint8_t mode;

  enum {
    M_RUN_ON_CAP,
    M_RUN_ON_BAT,
    M_RUN_ON_BOTH,
  };

  static const uint8_t chirp[ CHIRP_COUNT ] = {
    8, 8, 8,
  };
  uint8_t count;

  enum {
    VOLTAGE_ACTUAL_ADC_INTERNAL_VOLTAGE_PORT_1_5 = 
    ASSOCIATE_ADC_CHANNEL( INTERNAL_VOLTAGE,
			   REFERENCE_VREFplus_AVss,
			   REFVOLT_LEVEL_1_5 ),
    VOLTAGE_ACTUAL_ADC_INTERNAL_VOLTAGE_PORT_2_5 = 
    ASSOCIATE_ADC_CHANNEL( INTERNAL_VOLTAGE,
			   REFERENCE_VREFplus_AVss,
			   REFVOLT_LEVEL_2_5 ),
  };



  command result_t Init.init() {
    call ADCControl.init();
    call ADCControl.bindPort( TOS_ADC_VOLTAGE_PORT, 
			      VOLTAGE_ACTUAL_ADC_INTERNAL_VOLTAGE_PORT_1_5 );
    call Timer.start( TIMER_ONE_SHOT, 2048 );
    state = S_WAIT;
    return SUCCESS;
  }

  void chooseSource() {
    uint16_t tmpVoltage;

    atomic tmpVoltage = voltage;

    switch( mode ) {
    case M_RUN_ON_CAP:
      call Battery.stop();
      break;
    case M_RUN_ON_BAT:
      call Battery.start();
      break;
    case M_RUN_ON_BOTH:
      // cap is low
      if ( tmpVoltage < CAP_RUN_LOW )
	call Battery.start();
      // cap is high
      else if ( call VoltageStatus.voltageCap() >= CAP_RUN_HIGH )
	call Battery.stop();
      break;
    }
  }

  command void PowerSource.runOnCap() {
    mode = M_RUN_ON_CAP;
  }

  command void PowerSource.runOnBat() {
    mode = M_RUN_ON_BAT;
  }

  command void PowerSource.runOnBoth() {
    mode = M_RUN_ON_BOTH;    
  }

  event result_t Timer.fired() {

    switch( state ) {
    case S_WAIT:
      state = S_WAIT_SOUNDER;
      call Sounder.start();
      call Timer.start( TIMER_ONE_SHOT, 8 );
      break;
    case S_WAIT_SOUNDER:
      state = S_WAIT;
      call Sounder.stop();
      call ADC.getData();
      call Timer.start( TIMER_ONE_SHOT, 2048 );
      break;
    case S_SOUNDER_ON:
      if ( !sounderOn ) {
	sounderOn = TRUE;
	call Sounder.start();
	call Timer.start( TIMER_ONE_SHOT, chirp[ count++ ] );
      }
      else {
	sounderOn = FALSE;
	call Sounder.stop();
	call Timer.start( TIMER_ONE_SHOT, 196 );
	if ( count >= CHIRP_COUNT )
	  state = S_SIGNAL;
      }
      break;
    case S_SIGNAL:
      state = S_ON;
      call Timer.start( TIMER_REPEAT, 4096 );
      signal Init.initDone();
      break;
    case S_ON:
      call ADC.getData();
      break;
    }

    return SUCCESS;

  }

  task void voltageDone() {

    uint16_t tmpVoltage;

    atomic tmpVoltage = voltage;

    chooseSource();

    if ( tmpVoltage >= VTHRESH_HI ) {
      if ( state == S_WAIT ) {
	state = S_SOUNDER_ON;
	call Timer.stop();
	call Timer.start( TIMER_ONE_SHOT, 2 );
      }
    }
    else if ( tmpVoltage < VTHRESH_LO && state == S_ON ) {
      // reboot not using watchdog
      WDTCTL = WDTPW | WDTHOLD;
      __asm__ __volatile__ ("br #0x4000\n\t" ::);
    }

  }

  async event result_t ADC.dataReady( uint16_t data ) {
    atomic voltage = data;
    post voltageDone();
    return SUCCESS;
  }

}
