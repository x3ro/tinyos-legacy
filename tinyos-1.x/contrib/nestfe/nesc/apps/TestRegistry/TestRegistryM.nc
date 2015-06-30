includes Registry;

module TestRegistryM {
  provides{
    interface StdControl;
  }

  uses{
    interface Attribute<uint16_t> as Light @registry("Light");
    interface Attribute<location_t> as Location @registry("Location");
    interface Attribute<uint16_t> as SetMe @registry("SetMe");
    interface Attribute<uint32_t> as SetMeLocalTime @registry("SetMeLocalTime");
    interface Attribute<uint32_t> as SetMeGlobalTime @registry("SetMeGlobalTime");
    interface Timer;
    interface ADC as Photo;
    interface StdControl as PhotoControl;
    interface StdControl as ADCControl;
    interface Leds;
    interface GlobalTime;
  }
}
implementation {

  command result_t StdControl.init() {
    call PhotoControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    location_t location;
    location.x = (TOS_LOCAL_ADDRESS >> 4) & 0x0f;
    location.y = (TOS_LOCAL_ADDRESS >> 0) & 0x0f;
    call Location.set(location);
    call PhotoControl.start();
    call Timer.start(TIMER_REPEAT, 1000);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call PhotoControl.stop();
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired(){
    dbg(DBG_USR1,"TestRegistry: timer fired\n");
    call Photo.getData();
    return SUCCESS;
  }

  async event result_t Photo.dataReady(uint16_t data){
    dbg(DBG_USR1,"TestRegistry: photo data ready\n");
    call Light.set(data);
    return SUCCESS;
  }

  event void Light.updated(uint16_t val)  {
    dbg(DBG_USR1,"TestRegistry: Light Updated\n");
    call Leds.set(val);
  }

  event void Location.updated(location_t val)  {
    dbg(DBG_USR1,"TestRegistry: location updated\n");
    call Leds.set(7);
  }

  event void SetMe.updated(uint16_t val) {
    uint32_t lt = call GlobalTime.getLocalTime();
    uint32_t gt = ~(uint32_t)0;
    call GlobalTime.getGlobalTime(&gt);
    call SetMeLocalTime.set( lt );
    call SetMeGlobalTime.set( gt );
  }

  event void SetMeLocalTime.updated(uint32_t val) { }
  event void SetMeGlobalTime.updated(uint32_t val) { }
}

