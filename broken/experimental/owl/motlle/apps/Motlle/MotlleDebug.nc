module MotlleDebug {
  provides {
    interface Debug as MotlleDebug[uint8_t id];
  }
  uses {
    interface Debug;
    interface MotlleControl;
    interface Leds;
  }
  provides event void dbgAvailable();
}
implementation {
  uint8_t dbgOptions;

  event result_t MotlleControl.init() {
    return SUCCESS;
  }

  command void MotlleDebug.init[uint8_t id]() { 
    dbgOptions = id;
    call Debug.init();
  }

  command void MotlleDebug.setAddr[uint8_t id](uint16_t address) { 
    call Debug.setAddr(address);
  }

  command void MotlleDebug.setTimeout[uint8_t id](uint32_t timeout) { 
    // ok, ok this is a bit hacky
    dbgOptions = timeout;
  }

  command result_t MotlleDebug.dbg8[uint8_t id](uint8_t x) {
    if (id & dbgOptions)
      if (!call Debug.dbg8(x))
	call MotlleControl.waitForEvent(W_DBG);
    return SUCCESS;
  }

  command result_t MotlleDebug.dbg16[uint8_t id](uint16_t x) {
    if (id & dbgOptions)
      if (!call Debug.dbg16(x))
	call MotlleControl.waitForEvent(W_DBG);
    return SUCCESS;
  }

  command result_t MotlleDebug.dbg32[uint8_t id](uint32_t x) {
    if (id & dbgOptions)
      if (!call Debug.dbg32(x))
	call MotlleControl.waitForEvent(W_DBG);
    return SUCCESS;
  }

  command result_t MotlleDebug.dbgString[uint8_t id](char *s) {
    if (id & dbgOptions)
      if (!call Debug.dbgString(s))
	call MotlleControl.waitForEvent(W_DBG);
    return SUCCESS;
  }

  event void dbgAvailable() {
    call MotlleControl.eventOccurred(W_DBG);
  }

  void motlle_req_dbg(uint8_t x) __attribute__((C, spontaneous)) {
    call MotlleDebug.dbg8[DBG_RUN](x);
  }

}
