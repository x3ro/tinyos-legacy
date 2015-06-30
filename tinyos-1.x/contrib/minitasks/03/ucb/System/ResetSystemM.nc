
module ResetSystemM
{
  provides interface StdControl;
  uses interface Reset;
  uses interface ReceiveMsg as ResetMsg;
}
implementation
{
  void reset()
  {
    call Reset.reset();
  }

  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    reset();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  event TOS_MsgPtr ResetMsg.receive( TOS_MsgPtr msg )
  {
    reset();
    return msg;
  }
}

