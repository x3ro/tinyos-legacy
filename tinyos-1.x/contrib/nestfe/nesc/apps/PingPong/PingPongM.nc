module PingPongM
{
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface ReceiveMsg as ReceiveCmd;
    interface SendMsg as SendReply;
  }
}
implementation
{
  TOS_Msg replyBffr;
  PpReplyMsg *replyMsg = (PpReplyMsg *)replyBffr.data;


  command result_t StdControl.init() {
    call Leds.init();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }


  task void replyTask() {
    call SendReply.send(TOS_BCAST_ADDR, sizeof(PpReplyMsg), &replyBffr);
  }
  
  event TOS_MsgPtr ReceiveCmd.receive(TOS_MsgPtr msg) {
    PpCmdMsg *cmdMsg = (PpCmdMsg *)msg->data;
    call Leds.redToggle();
    switch (cmdMsg->cmd) {
      case PP_IMMEDIATE:
        replyMsg->reply = PP_IMMEDIATE;
        call SendReply.send(TOS_BCAST_ADDR, sizeof(PpReplyMsg), &replyBffr);
	call Leds.yellowToggle();
        break;
      case PP_TASK:
        replyMsg->reply = PP_TASK;
	post replyTask();
	call Leds.greenToggle();
        break;
      default:
        break;
    }
    return msg;
  }


  event result_t SendReply.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
}

