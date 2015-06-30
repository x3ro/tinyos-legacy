includes Greedy;
includes GreedyApp;

configuration GreedyApp {
}

implementation {
  components Main, GreedyAppM, GreedyM, LedsC, TimerC, GenericComm as Comm, RandomLFSR, TinyAlloc;

  Main.StdControl -> GreedyAppM;

  GreedyAppM.GreedyCtrl -> GreedyM.StdControl;
  GreedyAppM.PktTimer -> TimerC.Timer[unique("Timer")];
  GreedyAppM.PktRandom -> RandomLFSR;
  GreedyAppM.Leds -> LedsC;
  GreedyAppM.Greedy -> GreedyM.Greedy;

  GreedyM.BeaconRandom -> RandomLFSR;
  GreedyM.BeaconTimer -> TimerC.Timer[unique("Timer")];
  GreedyM.RouterCtrl -> Comm;
  GreedyM.RouterSend -> Comm.SendMsg[77];
  GreedyM.RouterRecv -> Comm.ReceiveMsg[77];
  GreedyM.MemAlloc -> TinyAlloc;
}
