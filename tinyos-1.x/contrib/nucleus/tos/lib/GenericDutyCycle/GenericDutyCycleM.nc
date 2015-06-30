module GenericDutyCycleM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as CommControl;
    interface Timer;
    interface Leds;
    interface Receive;
    interface Drip;
  }
}
implementation {

  bool started;
  bool isAsleep;
  bool isAwake;
  uint8_t sleepCounter;
  uint16_t wakePeriod;
  uint16_t wakeLength;

  GenericDutyCycleMsg dripCache;

  command result_t StdControl.init() {
    isAwake = TRUE;
    isAsleep = TRUE;
    wakePeriod = WAKE_PERIOD;
    wakeLength = WAKE_LENGTH;
    call Drip.init();
    return call CommControl.init();
  }
  
  command result_t StdControl.start() {
    started = TRUE;
    call Timer.start(TIMER_ONE_SHOT, wakeLength);
    call Leds.greenOn();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    started = FALSE;
    call Timer.stop();
    call CommControl.start();
    return SUCCESS;
  }

  event result_t Timer.fired() {

    /*
      uint32_t globalTime;
      uint32_t timeDiff = 0;
    */

    if (isAwake) {

      // Node is awake. Stop the comm stack, then sleep for 
      // wakePeriod - wakeLength

      if (call CommControl.stop()) {
	isAwake = FALSE;
	call Leds.greenOff();
	sleepCounter++;
      }

      call Timer.start(TIMER_ONE_SHOT, wakePeriod - wakeLength);

    } else {

      // Node is asleep. Start the comm stack, then stay awake for
      // wakeLength

      if (call CommControl.start()) {
	isAwake = TRUE;
	call Leds.greenOn();
      }

      call Timer.start(TIMER_ONE_SHOT, wakeLength);      
    }
    return SUCCESS;
  }

  void setAwake(bool awake) {
    if (awake) {
      call Timer.stop();
      call CommControl.start();
      isAwake = TRUE;
      isAsleep = FALSE;
    } else {
      call Timer.stop();
      call Timer.start(TIMER_ONE_SHOT, wakeLength);
      isAsleep = TRUE;
    }    
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, void* payload, 
				   uint16_t payloadLen) {

    GenericDutyCycleMsg* gdcMsg = (GenericDutyCycleMsg*) payload;

    if (started) {
      memcpy(&dripCache, payload, sizeof(dripCache));
      setAwake(gdcMsg->awake);
    }

    return msg;
  }

  
  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, void *pData) {
    memcpy(pData, &dripCache, sizeof(dripCache));
    call Drip.rebroadcast(msg, pData, sizeof(dripCache));
    return SUCCESS;
  }

  task void swapState() {
    if (isAsleep) {
      setAwake(TRUE);
    } else {
      setAwake(FALSE);
    }
  }
}
