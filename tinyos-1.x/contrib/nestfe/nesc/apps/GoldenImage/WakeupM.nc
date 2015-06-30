module WakeupM {
  provides interface StdControl;

  uses interface Leds;
  uses interface Receive;
  uses interface Drip;
  uses interface Timer;
  uses interface MSP430Event as UserButton;
  uses interface PowerSource;
}
implementation {
  
  WakeupMsg msgCache;

  uint16_t leaseTime;
  bool leaseAcquired;
  uint16_t source;

  task void acquireLease();

  command result_t StdControl.init() {
    call Drip.init();
    call Leds.init();
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event TOS_Msg* Receive.receive(TOS_Msg* msg, void* payload, uint16_t len) {
    WakeupMsg* wakeupMsg = (WakeupMsg*) payload;

    memcpy(&msgCache, payload, sizeof(WakeupMsg));
    
    call Timer.stop();
    call PowerSource.runOnCap();
    
    if (wakeupMsg->wakeupPeriod > 0 && 
	call Timer.start(TIMER_ONE_SHOT, (uint32_t)wakeupMsg->wakeupPeriod * 10)) {
      
      leaseAcquired = TRUE;
      leaseTime = wakeupMsg->wakeupPeriod;
      source = wakeupMsg->source;
      if (wakeupMsg->source == WAKEUP_SOURCE_BAT) {
	call PowerSource.runOnBat();
      } else if (wakeupMsg->source == WAKEUP_SOURCE_CAP) {
	call PowerSource.runOnCap();
      } else {
	call PowerSource.runOnBoth();
//	call Leds.greenOn(); 
      }
    }
    return msg;
  }
  
  async event void UserButton.fired() {
    post acquireLease();
  }

  task void acquireLease() {
    call PowerSource.runOnCap();
    call Timer.stop();

    if (call Timer.start(TIMER_ONE_SHOT, (uint32_t)WAKEUP_USERBUTTON_LEASE * 10)) {
//      call Leds.greenOn();
      leaseAcquired = TRUE;
      leaseTime = WAKEUP_USERBUTTON_LEASE;
      source = WAKEUP_SOURCE_BOTH;
      call PowerSource.runOnBoth();
    }
  }

  event result_t Timer.fired() {
    leaseAcquired = FALSE;
    leaseTime = 0;
    msgCache.wakeupPeriod = 0;
    source = WAKEUP_SOURCE_CAP;
    msgCache.source = WAKEUP_SOURCE_CAP;
    call Leds.greenOff();
    call PowerSource.runOnCap();
    return SUCCESS;
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, void *pData) {
    memcpy(pData, &msgCache, sizeof(WakeupMsg));
    call Drip.rebroadcast(msg, pData, sizeof(WakeupMsg));
    return SUCCESS;
  }
}
