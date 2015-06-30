module DebugRangingActuatorM
{
  provides 
  {
    interface StdControl;
    interface AcousticRangingActuator;
  }
  uses
  {
    interface SendMsg;
  }
}
implementation
{
  TOS_Msg msg;

  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }
  
  command result_t AcousticRangingActuator.send() {
    (((AcousticBeaconMsg*)msg.data)->nodeId) = TOS_LOCAL_ADDRESS;
    return call SendMsg.send(TOS_BCAST_ADDR,sizeof(AcousticBeaconMsg),&msg);
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success) {
    signal AcousticRangingActuator.sendDone();
    return SUCCESS;
  }
  
}
