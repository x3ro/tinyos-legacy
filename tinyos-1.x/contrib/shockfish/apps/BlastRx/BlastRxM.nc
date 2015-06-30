module BlastRxM {
  provides {
    interface StdControl; 
  }

  uses {
    interface Leds;
    interface ReceiveMsg as Receive;
    interface XE1205Control;
    interface CSMAControl;
    interface XE1205LPL;
    async command result_t enableInitialBackoff(); 
    async command result_t disableInitialBackoff();

    interface StdControl as RadioStdControl;
  }

}

implementation {

  uint32_t msgs_received;

  bool setupFailed = FALSE;

  uint16_t bad_msg(uint8_t i)  __attribute__ ((noinline)) {
    return i + 1;
  }


  command result_t StdControl.init() {
    msgs_received = 0;
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start()   __attribute__ ((noinline))  {


    //    call XE1205LPL.SetTransmitMode(3);
    //    call XE1205LPL.SetListeningMode(3);

    if (call CSMAControl.disableCCA() != SUCCESS) setupFailed = TRUE;
    if (call disableInitialBackoff() != SUCCESS) setupFailed = TRUE;
    // if (call CSMAControl.enableCCA() != SUCCESS) setupFailed = TRUE;
    // if (call enableInitialBackoff() != SUCCESS) setupFailed = TRUE;
    // if (call CSMAControl.enableAck() != SUCCESS) setupFailed = TRUE;

    if (call XE1205Control.SetBitrate(76170) != SUCCESS) setupFailed = TRUE;

    
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr m) __attribute__ ((noinline)) {
  
    if (m->crc == 1)
    {
      msgs_received++;
      call Leds.redToggle();
    }

    return m;
  }
}

