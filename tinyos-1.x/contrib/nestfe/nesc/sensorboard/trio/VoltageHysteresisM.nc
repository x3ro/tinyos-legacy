//$Id: VoltageHysteresisM.nc,v 1.9 2005/08/14 18:39:55 jwhui Exp $

module VoltageHysteresisM
{
  provides interface SplitInit as Init;
  uses interface Prometheus;
  uses interface Timer as InitTimer;
  uses interface Timer as DelayTimer;
  //uses interface ADC;
  uses interface Sounder;
}
implementation
{
  enum {
    CAP_MIN_VOLTAGE = 2700,
    BAT_MIN_VOLTAGE = 3100,
    STATE_IDLE = 0,
    STATE_CHECK_VOLTAGE = 1,
    STATE_INIT = 2,
    STATE_RUN = 3,
  };

  bool state;
  bool bBattVolReady = FALSE;

  command result_t Init.init()
  {
    state = STATE_INIT;
    call InitTimer.start( TIMER_ONE_SHOT, 1024 );
    //call InitTimer.start( TIMER_REPEAT, 30000 );
    return SUCCESS;
  }

  task void sounderOnTask() {
    call Sounder.setStatus(TRUE);
    call DelayTimer.start( TIMER_ONE_SHOT, 10 );
  }

  event result_t DelayTimer.fired() {
    call Sounder.setStatus(FALSE);
    return SUCCESS;
  }

  event result_t InitTimer.fired()
  {
    switch ( state ) {
    case STATE_INIT: 
      call Prometheus.Init();
      break;
    case STATE_RUN:
      post sounderOnTask();
      signal Init.initDone();
      break;
    }
    return SUCCESS;
  }
  
  event void Prometheus.automaticUpdate( bool runningOnBattery,
    bool chargingBattery, uint16_t batteryVoltage, uint16_t capVoltage ) { 

    if ( batteryVoltage >= BAT_MIN_VOLTAGE ||
	 TOSH_READ_USB_DETECT_PIN() ) {
      if ( bBattVolReady == FALSE ) { 
        bBattVolReady = TRUE;
	state = STATE_RUN;
	call InitTimer.start( TIMER_ONE_SHOT, 1024 );
      }
    }
    else {
      post sounderOnTask();
    }
  }

  event void Sounder.getStatusDone(bool high, result_t result) { }
  event void Prometheus.getADCSourceDone(bool high, result_t success) { }
  event void Prometheus.getAutomaticDone(bool high, result_t success) { }
  event void Prometheus.getBattVolDone(uint16_t _volBatt, result_t success) { }
  event void Prometheus.getCapVolDone(uint16_t _volCap, result_t success) { }
  event void Prometheus.getPowerSourceDone(bool high, result_t success) { }
  event void Prometheus.getChargingDone(bool high, result_t success) { }
}

