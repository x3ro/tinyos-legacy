//$Id: PrometheusM.nc,v 1.10 2005/08/15 20:57:45 jwhui Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Implementation file for Prometheus <p>
 *
 * @modified 6/6/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;

module PrometheusM
{
  provides {
    interface StdControl;
    interface Prometheus;
  }
  uses {
    interface ADCControl;
    interface ADC as CapADC;
    interface ADC as BattADC;

    interface StdControl  as PWSwitchControl;
    interface BytePort    as PWSwitchPort;
    interface StdControl  as IOSwitch1Control;
    interface IOSwitch    as IOSwitch1;
    interface Timer;
  }

}
implementation 
{
  enum {
    STATE_IDLE = 0,
    STATE_READ_POWER_SOURCE,
    STATE_READ_CHARGING,
    STATE_SET_POWER_SOURCE,
    STATE_SET_CHARGING,
    STATE_AUTO_POWER_SOURCE,
    STATE_AUTO_CHARGING,
    STATE_AUTO_ADC_SW,

    // REFVOL in mV
#ifndef REFVOL_2500
    volRef = 1500,
#else
    volRef = 2500,
#endif

    // Power source thresholds
    CAP_RUN_LOW = 2700,
    CAP_RUN_HIGH = 3100,
    CAP_RUN_THRESH = 3800,
    BAT_RUN_LOW = 2800,
    BAT_RUN_HIGH = 3200,

    // Charging thresholds
    CAP_CHARGE_LOW = 2800,
    CAP_CHARGE_HIGH = 3300,
    BAT_CHARGE_HIGH = 4100,
  };

  bool bRunningOnBatt = FALSE;
  bool bCharging      = FALSE;
  bool bAutomatic     = FALSE;
  bool bGetBattADC    = FALSE;
  bool bGetCapADC     = FALSE;
  bool bBattOnCapLow  = TRUE;

  uint16_t adcBatt;
  uint16_t adcCap;

  // capacitor voltage in mV
  uint16_t volCap  = 0;
  // battery voltage in mV
  uint16_t volBatt = 0;

  uint8_t state = STATE_IDLE;

  command result_t StdControl.init() {

    call ADCControl.init();

    call PWSwitchControl.init();
    call IOSwitch1Control.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {

    // REFVOL
#ifndef REFVOL_2500
    call ADCControl.bindPort( TOS_ADC_MUX0_PORT, 
                              TOSH_ACTUAL_ADC_MUX0_VOLTAGE_1_5_PORT);
    call ADCControl.bindPort( TOS_ADC_MUX1_PORT, 
                              TOSH_ACTUAL_ADC_MUX1_VOLTAGE_1_5_PORT);
#else
    call ADCControl.bindPort( TOS_ADC_MUX0_PORT, 
                              TOSH_ACTUAL_ADC_MUX0_VOLTAGE_2_5_PORT);
    call ADCControl.bindPort( TOS_ADC_MUX1_PORT, 
                              TOSH_ACTUAL_ADC_MUX1_VOLTAGE_2_5_PORT);
#endif

    call PWSwitchControl.start();
    call IOSwitch1Control.start();

    return SUCCESS;
  }

  command result_t StdControl.stop() {

    call PWSwitchControl.stop();
    call IOSwitch1Control.stop();

    atomic bAutomatic = FALSE;
    call Timer.stop();
    return SUCCESS;
  }

  command result_t Prometheus.Init() {
    bRunningOnBatt = FALSE;
    bCharging = FALSE;
    call Prometheus.setAutomatic(TRUE);
    return SUCCESS;
  }

  // If TRUE, select Prometheus.
  // If FALSE, select external ADC.
  command result_t Prometheus.selectADCSource(bool high) { 
    if (high) {
      return call PWSwitchPort.setPort(PWSWITCH_V_BAT | PWSWITCH_V_CAP);
    }
    else {
      return call PWSwitchPort.setPort(PWSWITCH_ADC_EXP1 | PWSWITCH_ADC_EXP2);
    }
  }

  command result_t Prometheus.getADCSource() {
    return call PWSwitchPort.getPort(); 
  }

  event void PWSwitchPort.getPortDone(uint8_t bits, result_t result) {
    // Prometheus battery and capacitor are selected for ADC
    if (bits == (PWSWITCH_V_BAT | PWSWITCH_V_CAP)) {
      signal Prometheus.getADCSourceDone(TRUE, result);
    }
    // External sources are selected for ADC
    else if (bits == (PWSWITCH_ADC_EXP1 | PWSWITCH_ADC_EXP2)) {
      signal Prometheus.getADCSourceDone(FALSE, result);
    }
    else {
      signal Prometheus.getADCSourceDone(FALSE, FAIL);
    }
  }

  command result_t Prometheus.getBattVol() {
    if ( bAutomatic == FALSE ) {
      bGetBattADC = TRUE;
      call BattADC.getData();
    }
    else {
      signal Prometheus.getBattVolDone(volBatt, SUCCESS);
    }
    return SUCCESS;
  }

  command result_t Prometheus.getCapVol() { 
    if ( bAutomatic == FALSE ) {
      bGetCapADC = TRUE;
      call CapADC.getData();
    }
    else {
      signal Prometheus.getCapVolDone(volCap, SUCCESS);
    }
    return SUCCESS;
  }

  command result_t Prometheus.setAutomatic(bool high) { 
    if( high != bAutomatic ) {
      bAutomatic = high;
      if( high ) {
        call Timer.start( TIMER_REPEAT, 5000 );
      } else {
        call Timer.stop();
      }
    }
    return SUCCESS;
  }

  command result_t Prometheus.getAutomatic() { 
    signal Prometheus.getAutomaticDone(bAutomatic, SUCCESS);
    return SUCCESS;
  }

  // If TRUE, set to battery.
  // If FALSE, set to capacitor.

  command result_t Prometheus.setPowerSource(bool high) { 
    if (state == STATE_IDLE) {
      state = STATE_SET_POWER_SOURCE;
      bRunningOnBatt = high;
      return call IOSwitch1.setPort0Pin(IOSWITCH1_PWR_SW, high);
    }
    else {
      return FAIL;
    }
  }

  command result_t Prometheus.getPowerSource() { 
    if (state == STATE_IDLE) {
      state = STATE_READ_POWER_SOURCE;
      return call IOSwitch1.getPort();
    }
    else {
      return FAIL;
    }
  }

  command result_t Prometheus.setCharging(bool high) { 
    if (state == STATE_IDLE) {
      state = STATE_SET_CHARGING;
      bCharging = high;
      return call IOSwitch1.setPort0Pin(IOSWITCH1_CHARGE_SW, !high);
    }
    else {
      return FAIL;
    }
  }

  command result_t Prometheus.getCharging() { 
    if (state == STATE_IDLE) {
      state = STATE_READ_CHARGING;
      return call IOSwitch1.getPort();
    }
    else {
      return FAIL;
    }
  }

  event void IOSwitch1.getPortDone(uint16_t _bits, result_t _success) {
    if (state == STATE_READ_POWER_SOURCE) {
      state = STATE_IDLE;
      if ( (_bits & IOSWITCH1_PWR_SW) != 0 ) {
        bRunningOnBatt = TRUE;
        signal Prometheus.getPowerSourceDone(TRUE, _success);
      }
      else {
        bRunningOnBatt = FALSE;
        signal Prometheus.getPowerSourceDone(FALSE, _success);
      }
    }
    else if (state == STATE_READ_CHARGING) {
      state = STATE_IDLE;
      // reverse logic
      if ( (_bits & IOSWITCH1_CHARGE_SW) == 0 ) {
        bCharging = TRUE;
        signal Prometheus.getChargingDone(TRUE, _success);
      }
      else {
        bCharging = FALSE;
        signal Prometheus.getChargingDone(FALSE, _success);
      }
    }
  }

  task void battADCReadyTask() {
    // REFVOL
#ifndef REFVOL_2500
    atomic volBatt = ((uint32_t)adcBatt) * ((uint32_t)volRef) * 4 / 4096;
#else
    atomic volBatt = ((uint32_t)adcBatt) * ((uint32_t)volRef) * 2 / 4096;
#endif

    if (bAutomatic) {

      // The battery's primary lifetime across its discharge curve is
      // dominantly above 3.5V until a sharp drop at the end.  
      // The battery cuts out at around 2.8V.
      //
      // 2.7V is the datasheet spec for writing to the internal flash or
      // reading/writing the external flash
      // 
      // In the future, we could add to to only switch to the battery 
      // if the caps are below 2.1V.  But, then we need logic 
      // to switch to the battery when using flash.

      bool runOnBattery = bRunningOnBatt;
      bool chargeBattery = bCharging;

      // POWER SOURCE LOGIC

      if ( volCap < CAP_RUN_LOW ) {
	// cap low, batt low
	if ( volBatt < BAT_RUN_LOW )
	  runOnBattery = FALSE;
	// cap low, batt high
	else if ( volBatt >= BAT_RUN_HIGH &&
		  bBattOnCapLow )
	  runOnBattery = TRUE;
      }
      else if ( volCap >= CAP_RUN_HIGH ) {
	// cap way too high
	if ( volCap >= CAP_RUN_THRESH )
	  runOnBattery = TRUE;
	// cap high, batt low
	if ( volBatt < BAT_RUN_LOW )
	  runOnBattery = FALSE;
	// cap high, batt high
	else if ( volBatt >= BAT_RUN_HIGH )
	  runOnBattery = FALSE;
      }

      // CHARGING LOGIC

      if ( volBatt < BAT_CHARGE_HIGH ) {
	// cap low, batt low
        if ( volCap < CAP_CHARGE_LOW )
          chargeBattery = FALSE;
	// cap high, batt low
        else if ( volCap >= CAP_CHARGE_HIGH ) 
          chargeBattery = TRUE;
      } else {
	// batt high
        chargeBattery = FALSE;
      }

      if ( runOnBattery != bRunningOnBatt )
        call Prometheus.setPowerSource( runOnBattery );

      if ( chargeBattery != bCharging )
        call Prometheus.setCharging( chargeBattery );

      signal Prometheus.automaticUpdate( bRunningOnBatt, bCharging, 
					 volBatt, volCap );
    }

    if (bGetBattADC) {
      bGetBattADC = FALSE;
      signal Prometheus.getBattVolDone(volBatt, SUCCESS);
    }
  }

  async event result_t BattADC.dataReady (uint16_t data) {
    adcBatt = data;
    post battADCReadyTask();

    return SUCCESS;
  }

  task void capADCReadyTask() {
    // REFVOL
#ifndef REFVOL_2500
    atomic volCap = ((uint32_t)adcCap) * ((uint32_t)volRef) * 4 / 4096;
#else
    atomic volCap = ((uint32_t)adcCap) * ((uint32_t)volRef) * 2 / 4096;
#endif
    
    if (bGetCapADC) {
      bGetCapADC = FALSE;
      signal Prometheus.getCapVolDone(volCap, SUCCESS);
    }

    call BattADC.getData();
  }

  async event result_t CapADC.dataReady (uint16_t data) {
    adcCap = data;
    post capADCReadyTask();
    return SUCCESS;
  }

  event result_t Timer.fired() {
    if ( state == STATE_IDLE ) {
      state = STATE_AUTO_POWER_SOURCE;
      return call IOSwitch1.setPort0Pin(IOSWITCH1_PWR_SW, bRunningOnBatt);
    }
    return SUCCESS;
  }

  event void IOSwitch1.setPortDone(result_t result) { 
    if (state == STATE_SET_POWER_SOURCE) {
      state = STATE_IDLE;
    }
    else if (state == STATE_SET_CHARGING) {
      state = STATE_IDLE;
    }
    else if (state == STATE_AUTO_POWER_SOURCE) {
      state = STATE_AUTO_CHARGING;
      // Charging switch
      // 0 - charging / 1 - no charging / default - 1
      call IOSwitch1.setPort0Pin(IOSWITCH1_CHARGE_SW, !bCharging);
    }
    else if (state == STATE_AUTO_CHARGING) {
      state = STATE_AUTO_ADC_SW;
      // Select Battery Voltage and Cap Voltage for the power switch
      call PWSwitchPort.setPort(PWSWITCH_V_BAT | PWSWITCH_V_CAP);
    }
  }

  event void PWSwitchPort.setPortDone(result_t result) { 
    if (state == STATE_AUTO_ADC_SW) {
      state = STATE_IDLE;
      call CapADC.getData();
    }
  }

}


