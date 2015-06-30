includes NativeCode;

module NativeCodeM {
  provides interface StdControl;
  uses {
    interface ReceiveMsg as ReceiveState;
    interface ReceiveMsg as ReceiveCode;
    interface SendMsg as SendState;
    interface SendMsg as SendCode;
    interface Leds;
  }
}
implementation {
  TOS_Msg _msg;

  command result_t StdControl.init() {
    return call Leds.init();
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  task void sendReply() {
    call SendState.send(TOS_UART_ADDR, sizeof(StateMsg), &_msg);
  }
  
  task void sendCode() {
      call SendCode.send(TOS_UART_ADDR, sizeof(CodeMsg), &_msg);
  }
  
  event result_t SendState.sendDone(TOS_MsgPtr msg, result_t success) {
    return post sendCode();
  }
   
  event result_t SendCode.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
  
  event TOS_MsgPtr ReceiveState.receive(TOS_MsgPtr m) {
    return m;
  }
  
  event TOS_MsgPtr ReceiveCode.receive(TOS_MsgPtr m) {
    post sendReply();
    return m;
  }
}
