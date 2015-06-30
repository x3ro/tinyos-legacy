/**
 *  Author: Matt Welsh
 **/
includes Multihop;

abstract configuration Multihop(int handler_id) {
  provides interface Send;
}
implementation {
  components Main, MultihopM, AbstractTimerC(), LedsC, NoLeds, RandomLFSR,
    GenericCommAC(AM_MULTIHOPMSG) as Comm, QueuedSend(10);

  Send = MultihopM;

  Main.StdControl -> MultihopM.StdControl;
  Main.StdControl -> QueuedSend.StdControl;
  Main.StdControl -> Comm;

  MultihopM.Timer -> AbstractTimerC;
  MultihopM.Leds -> LedsC; // NoLeds;
  MultihopM.ReceiveMsg -> Comm.ReceiveMsg;
  MultihopM.CommControl -> Comm;
  MultihopM.Random -> RandomLFSR;

  MultihopM.SendMsg -> QueuedSend;
  QueuedSend.RealSendMsg -> Comm.SendMsg;
  QueuedSend.Leds -> NoLeds;
  QueuedSend.sendFail -> MultihopM.sendFail;
  QueuedSend.sendSucceed -> MultihopM.sendSucceed;
}

