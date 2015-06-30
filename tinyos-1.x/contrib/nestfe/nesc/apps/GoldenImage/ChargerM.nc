// $Id: ChargerM.nc,v 1.7 2005/08/24 17:58:21 jwhui Exp $

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

module ChargerM {
  provides {
    interface StdControl;
    interface VoltageStatus;
  }
  uses {
    interface ADC as Bat;
    interface ADC as Cap;
    interface ADCControl;
    interface PowerSourceStatus;
    interface StdControl as Charge;
    interface Timer;
  }
}

implementation {

  enum {
    // V*4096/6000
    BAT_CHARGE_HIGH = 2798, // 4.1 Volts
    CAP_CHARGE_LOW = 2048, // 3.0 Volts
    CAP_CHARGE_HIGH = 2252, // 3.3 Volts

    CAP_CORRECTION = 239, // 0.35 Volts (Correction factor)
  };

  uint16_t voltageBat, voltageCap;
  uint16_t newVoltageBat, newVoltageCap;
  uint16_t chargeCycles;
  bool isCharging;

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call ADCControl.init();
    call ADCControl.bindPort( TOS_ADC_MUX0_PORT,
			      TOSH_ACTUAL_ADC_MUX0_VOLTAGE_1_5_PORT );
    call ADCControl.bindPort( TOS_ADC_MUX1_PORT,
			      TOSH_ACTUAL_ADC_MUX1_VOLTAGE_1_5_PORT );
    call Timer.start( TIMER_REPEAT, 5000 );
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command uint16_t VoltageStatus.voltageBat() { 
    return voltageBat;
  }

  command uint16_t VoltageStatus.voltageCap() {
    return voltageCap;
  }

  event result_t Timer.fired() {
    call Cap.getData();
    return SUCCESS;
  }

  task void runLogic() {

    bool newCharging = isCharging;

    atomic {
      voltageBat = newVoltageBat;
      voltageCap = newVoltageCap;
      if ( call PowerSourceStatus.isOnBattery() )
	voltageCap -= CAP_CORRECTION;
    }

    // CHARGING LOGIC

    if ( voltageBat < BAT_CHARGE_HIGH ) {
      // cap low, bat low
      if ( voltageCap < CAP_CHARGE_LOW )
	newCharging = FALSE;
      // cap high, bat low
      else if ( voltageCap >= CAP_CHARGE_HIGH )
	newCharging = TRUE;
    }
    else {
      // bat high
      newCharging = FALSE;
    }

    // special case if plugged in to USB
    if ( TOSH_READ_USB_DETECT_PIN() &&
	 voltageBat < BAT_CHARGE_HIGH )
      newCharging = TRUE;

    if ( newCharging != isCharging ) {
      isCharging = newCharging;
      if ( isCharging ) {
	call Charge.start();
	chargeCycles++;
      }
      else {
	call Charge.stop();
      }
    }

  }

  async event result_t Cap.dataReady( uint16_t data ) {
    atomic newVoltageCap = data;
    call Bat.getData();
    return SUCCESS;
  }

  async event result_t Bat.dataReady( uint16_t data ) {
    atomic newVoltageBat = data;
    post runLogic();
    return SUCCESS;
  }

}
