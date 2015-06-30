module RadioCRCPacketM {
  provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
  }
  uses {
    interface Leds;

    interface StdControl as LowerControl;
    interface BareSendMsg as LowerSend;
    interface ReceiveMsg as LowerReceive;
  }
}
implementation {
  bool outstanding;
  bool stopWaiting;

  command result_t Control.init() {
    return call LowerControl.init();
  }

  command result_t Control.start() {
    return call LowerControl.start();
  }

  command result_t Control.stop() {
    if (!outstanding) {
      return call LowerControl.stop();
    } else {
      stopWaiting = TRUE;
    }
    return SUCCESS;
  }

  command result_t Send.send(TOS_MsgPtr pMsg) {
    result_t result;

    result = call LowerSend.send(pMsg);
    
    if (result == SUCCESS) {
      call Leds.greenOn();
      outstanding = TRUE;
    }

    return result;
  }

  event result_t LowerSend.sendDone(TOS_MsgPtr pMsg, result_t result) {
    result_t callResult;

    outstanding = FALSE;
    callResult = signal Send.sendDone(pMsg, result);

    call Leds.greenOff();

    if (stopWaiting) {
      stopWaiting = FALSE;
      call LowerControl.stop();
    }

    return callResult;
  }

  event TOS_MsgPtr LowerReceive.receive(TOS_MsgPtr pMsg) {
    return signal Receive.receive(pMsg);
  }
}



