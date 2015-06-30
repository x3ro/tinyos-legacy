module NoDebug {
  provides interface Debug;
  uses {
    interface SendMsg;
    interface Timer;

    event void available();
  }
}
implementation {
  command void Debug.init() {
  }

  command void Debug.setAddr(uint16_t addr) {
  }

  command void Debug.setTimeout(uint32_t timeout) {
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr data, result_t success) {
    return SUCCESS;
  }

  event result_t Timer.fired() {
    return SUCCESS;
  }

  command result_t Debug.dbg8(uint8_t x) {
    return FAIL;
  }

  command result_t Debug.dbg16(uint16_t x) {
    return FAIL;
  }

  command result_t Debug.dbg32(uint32_t x) {
    return FAIL;
  }

  command result_t Debug.dbgString(char *s) {
    return FAIL;
  }
}
