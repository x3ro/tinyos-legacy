module BounceM {
  provides interface StdControl;

  provides interface Attr<uint8_t> as BounceEnabled 
    @nucleusAttr("BounceEnabled");
  provides interface AttrSet<uint8_t> as BounceEnabledSet
    @nucleusAttr("BounceEnabled");

  provides interface Attr<uint16_t> as BounceAwakeTime 
    @nucleusAttr("BounceAwakeTime");
  provides interface AttrSet<uint16_t> as BounceAwakeTimeSet 
    @nucleusAttr("BounceAwakeTime");

  provides interface Attr<uint16_t> as BounceTotalTime 
    @nucleusAttr("BounceTotalTime");
  provides interface AttrSet<uint16_t> as BounceTotalTimeSet 
    @nucleusAttr("BounceTotalTime");

  uses interface Timer;
  uses interface StdControl as CommControl;
  uses interface Leds;
}
implementation {
  bool enabled;

  bool isAsleep;

  uint16_t awakeTime = 1024;
  uint16_t totalTime = 2048;

  task void startTimer();

  command result_t StdControl.init() {
    isAsleep = FALSE;
    return SUCCESS;
  }
  command result_t StdControl.start() {
    enabled = TRUE;
    post startTimer();
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    call Timer.stop();
    isAsleep = FALSE;
    enabled = FALSE;
    call CommControl.start();
    return SUCCESS;
  }

  task void startTimer() {
    call Timer.start(TIMER_ONE_SHOT, awakeTime);
  }

  event result_t Timer.fired() {
    if (isAsleep) {
      isAsleep = FALSE;
      call CommControl.start();
      call Leds.yellowOn();
      call Timer.start(TIMER_ONE_SHOT, awakeTime);
    } else {
      isAsleep = TRUE;
      call CommControl.stop();
      call Leds.yellowOff();
      call Timer.start(TIMER_ONE_SHOT, totalTime - awakeTime);
    }
    return SUCCESS;
  }

  command result_t BounceEnabled.get(uint8_t* buf) {
    memcpy(buf, &enabled, sizeof(uint8_t));
    signal BounceEnabled.getDone(buf);
    return SUCCESS;
  }

  command result_t BounceEnabledSet.set(uint8_t* buf) {
    memcpy(&enabled, buf, sizeof(uint8_t));

    isAsleep = FALSE;
    call Timer.stop();

    if (enabled) {
      post startTimer();
    } else {
      call CommControl.start();
    }
    
    signal BounceEnabledSet.setDone(buf);
    return SUCCESS;
  }

  command result_t BounceAwakeTime.get(uint16_t* buf) {
    memcpy(buf, &awakeTime, sizeof(uint16_t));
    signal BounceAwakeTime.getDone(buf);
    return SUCCESS;
  }

  command result_t BounceAwakeTimeSet.set(uint16_t* buf) {
    memcpy(&awakeTime, buf, sizeof(uint16_t));
    signal BounceAwakeTimeSet.setDone(buf);
    return SUCCESS;
  }

  command result_t BounceTotalTime.get(uint16_t* buf) {
    memcpy(buf, &totalTime, sizeof(uint16_t));
    signal BounceTotalTime.getDone(buf);
    return SUCCESS;
  }

  command result_t BounceTotalTimeSet.set(uint16_t* buf) {
    memcpy(&totalTime, buf, sizeof(uint16_t));
    signal BounceTotalTimeSet.setDone(buf);
    return SUCCESS;
  }
}







