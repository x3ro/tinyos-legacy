module LocalizationControlM
{
  provides
  {
    interface LocalizationControl;
  }

  uses
  {
    interface ReceiveMsg as ResetMsg;
    interface ReceiveMsg as StopMsg;
    interface ReceiveMsg as StartMsg;
    interface ReceiveMsg as RangeOnceMsg;
    interface ReceiveMsg as ReportRangingHoodMsg;
    interface ReceiveMsg as ReportAnchorHoodMsg;
    interface ReceiveMsg as BuffersResetMsg;
    interface ReceiveMsg as BuffersReportMsg;
  }
}

implementation
{

  event TOS_MsgPtr ResetMsg.receive(TOS_MsgPtr msg) {
    signal LocalizationControl.reset();
    return msg;
  }

  event TOS_MsgPtr StopMsg.receive(TOS_MsgPtr msg) {
    signal LocalizationControl.stop();
    return msg;
  }
    
  event TOS_MsgPtr StartMsg.receive(TOS_MsgPtr msg) {
    signal LocalizationControl.start();
    return msg;
  }
  
  event TOS_MsgPtr RangeOnceMsg.receive(TOS_MsgPtr msg) {
    signal LocalizationControl.rangeOnce();
    return msg;
  }
  
  event TOS_MsgPtr ReportRangingHoodMsg.receive(TOS_MsgPtr msg) {
    signal LocalizationControl.reportRangingHood();
    return msg;
  }

  event TOS_MsgPtr ReportAnchorHoodMsg.receive(TOS_MsgPtr msg) {
    signal LocalizationControl.reportAnchorHood();
    return msg;
  }
  
  event TOS_MsgPtr BuffersResetMsg.receive(TOS_MsgPtr msg) {
    signal LocalizationControl.msgBuffersReset();
    return msg;
  }

  event TOS_MsgPtr BuffersReportMsg.receive(TOS_MsgPtr msg) {
    signal LocalizationControl.msgBuffersReport();
    return msg;
  }
  
}
