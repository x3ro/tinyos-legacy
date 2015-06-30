/* Simple application to send packets periodically. */

/**
 * @author Henri Dubois-Ferriere
 */

module BlastTxM {
  provides {
    interface StdControl; 
  }
  
  uses {
    interface Leds;
    interface BareSendMsg as Send;
    interface Timer as SendTimer;
    interface Timer as ExitTimer;
    interface Random;
    interface XE1205Control;
    interface CSMAControl;
    interface XE1205LPL;
    
    async command result_t enableInitialBackoff(); 
    async command result_t disableInitialBackoff();
  }

}

implementation {

  bool setupFailed = FALSE;

  uint32_t msgs_sent;
  uint32_t msgs_acked;
  TOS_Msg m;
  bool sendfailed;
  bool postfailed;
  bool senddonefailed;
  bool timerfailed;
  uint8_t length=4;

  uint8_t fakevar=0;
  void finished_test(uint8_t i)  __attribute__ ((noinline)) {
    // this is just to make sure the compiler doesn't optimize 
    // out calls to this function, since we use it as a gdb breakpoint
    fakevar += i; 
  }

  command result_t StdControl.init() {
    uint8_t i;

    sendfailed = FALSE;
    postfailed = FALSE;
    senddonefailed = FALSE;
    timerfailed = FALSE;

    msgs_sent = 0;
    msgs_acked = 0;
    call Random.init();
    call Leds.init();

    m.group = TOS_DEFAULT_AM_GROUP;
    m.addr = 1;
    m.type = 28;
    m.length = length;
    for (i = 0; i < m.length; i++) {
      m.data[i] = i+1;
    }

    return SUCCESS;

  }

  command result_t StdControl.start() {
        
    //    call XE1205Control.SetRFPower(3);

    //    if (call CSMAControl.enableCCA() != SUCCESS) setupFailed = TRUE;
    //    if (call enableInitialBackoff() != SUCCESS) setupFailed = TRUE;
    //    if (call CSMAControl.enableAck() != SUCCESS) setupFailed = TRUE;

    if (call CSMAControl.disableCCA() != SUCCESS) setupFailed = TRUE;
    if (call disableInitialBackoff() != SUCCESS) setupFailed = TRUE;
    if (call CSMAControl.disableAck() != SUCCESS) setupFailed = TRUE;

    //    call XE1205LPL.SetListeningMode(3);
    //    call XE1205LPL.SetTransmitMode(3);

    if (call XE1205Control.SetBitrate(76170) != SUCCESS) setupFailed = TRUE;

    return call SendTimer.start(TIMER_ONE_SHOT, 100);
  }

  command result_t StdControl.stop() {
    call SendTimer.stop();
    return SUCCESS;
  }

  task void sendTask() {

    if (call Send.send(&m) != SUCCESS) { 
      call Leds.redOn();
      sendfailed = TRUE;
      signal Send.sendDone(&m, SUCCESS);
    } else {
      msgs_sent++;
      call Leds.redToggle();
    }
  }

  event result_t ExitTimer.fired() {
    finished_test(msgs_sent);
    return SUCCESS;
  }


  event result_t SendTimer.fired() {

#ifdef SCRIPTED
    call ExitTimer.start(TIMER_ONE_SHOT,  TEST_LENGTH);
#endif
    if (!post sendTask()) postfailed=TRUE;
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr p, result_t res) {
    if (res != SUCCESS) {
      senddonefailed = TRUE;
      call Leds.redOn();
    } else {
      if (p->ack) msgs_acked++;

#ifdef SCRIPTED
      if (!post sendTask()) postfailed=TRUE;
#else
      if (!call SendTimer.start(TIMER_ONE_SHOT, 100)) timerfailed=TRUE;        
#endif
    }
    return SUCCESS;
  }

}

