//$Id: AMStandard.nc,v 1.1 2005/06/29 05:06:47 cssharp Exp $

configuration AMStandard
{
  provides interface StdControl as Control;
  provides interface SendMsg[uint8_t id];
  provides interface ReceiveMsg[uint8_t id];

  uses event result_t sendDone();

  uses interface StdControl as UARTControl;
  uses interface BareSendMsg as UARTSend;
  uses interface ReceiveMsg as UARTReceive;

  uses interface StdControl as RadioControl;
  uses interface BareSendMsg as RadioSend;
  uses interface ReceiveMsg as RadioReceive;
  uses interface PowerManagement;

  provides command uint16_t activity();
  uses interface StdControl as TimerControl;
  uses interface Timer as ActivityTimer;

  uses interface MsgFilter as PreSendFilter;
  uses interface MsgFilter as PostSendFilter;
  uses interface MsgTestAll as IntegrityTest;
  uses interface MsgTestAny as GroupTest;
  uses interface MsgTestAny as AddressTest;
}
implementation
{
  components AMStandardM;
  components AMTestsC;

  Control = AMStandardM.Control;
  SendMsg = AMStandardM.SendMsg;
  ReceiveMsg = AMStandardM.ReceiveMsg;
  activity = AMStandardM.activity;

  // just make GenericComm happy
  sendDone = AMStandardM.sendDone;
  TimerControl = AMStandardM.TimerControl;
  ActivityTimer = AMStandardM.ActivityTimer;

  UARTControl = AMStandardM.UARTControl;
  UARTSend = AMStandardM.UARTSend;
  UARTReceive = AMStandardM.UARTReceive;

  RadioControl = AMStandardM.RadioControl;
  RadioSend = AMStandardM.RadioSend;
  RadioReceive = AMStandardM.RadioReceive;
  PowerManagement = AMStandardM.PowerManagement;

  PreSendFilter = AMStandardM.PreSendFilter;
  PostSendFilter = AMStandardM.PostSendFilter;
  IntegrityTest = AMStandardM.IntegrityTest;
  GroupTest = AMStandardM.GroupTest;
  AddressTest = AMStandardM.AddressTest;

  AMStandardM.IntegrityTest -> AMTestsC.CrcTest;
  AMStandardM.GroupTest -> AMTestsC.LocalGroupTest;
  AMStandardM.AddressTest -> AMTestsC.LocalAddressTest;
  AMStandardM.AddressTest -> AMTestsC.BroadcastAddressTest;
}

