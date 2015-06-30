/**
 *  Author: Matt Welsh
 **/
includes Multihop;

configuration MultihopOld {
  provides interface Send;
}
implementation {
  components Main, MultihopM, TimerC, LedsC, NoLeds, RandomLFSR,
    GenericCommPromiscuous as Comm, QueuedSendOld as QueuedSend;

  Send = MultihopM;

  Main.StdControl -> MultihopM.StdControl;
  Main.StdControl -> QueuedSend.StdControl;
  Main.StdControl -> Comm;

  MultihopM.Timer -> TimerC.Timer[unique("Timer")];
  MultihopM.Leds -> LedsC; // NoLeds;
  MultihopM.ReceiveMsg -> Comm.ReceiveMsg[AM_MULTIHOPMSG];
  MultihopM.CommControl -> Comm;
  MultihopM.Random -> RandomLFSR;

  MultihopM.SendMsg -> QueuedSend;
  QueuedSend.RealSendMsg -> Comm.SendMsg[AM_MULTIHOPMSG];
  QueuedSend.Leds -> NoLeds;
  QueuedSend.sendFail -> MultihopM.sendFail;
  QueuedSend.sendSucceed -> MultihopM.sendSucceed;
}

