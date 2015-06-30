includes msg_types;
configuration NeighborTest
{
}
implementation
{
  components Main, NeighborBeacon, 
    NeighborFilterM, NeighborTestM,
    GenericComm, TxManC, NeighborStoreM, LedsC, TimerC;

  Main.StdControl -> TimerC;
  Main.StdControl -> GenericComm;
  Main.StdControl -> TxManC;
  Main.StdControl -> NeighborBeacon;
  Main.StdControl -> NeighborStoreM;

  TxManC.CommSendMsg -> GenericComm.SendMsg;
  
  NeighborBeacon.Enqueue -> TxManC;
  NeighborBeacon.ReceiveMsg -> GenericComm.ReceiveMsg[MSG_NEIGHBOR_BEACON];
  NeighborBeacon.Leds -> LedsC;
  NeighborBeacon.TxManControl -> TxManC;
  NeighborBeacon.ReadNeighborStore -> NeighborStoreM;
  NeighborBeacon.WriteNeighborStore -> NeighborStoreM;
  NeighborBeacon.BeaconTimer -> TimerC.Timer[unique("Timer")];
  NeighborBeacon.TxManTimer -> TimerC.Timer[unique("Timer")];
  
  Main.StdControl -> NeighborTestM;
  NeighborTestM.ReceiveMsg -> NeighborFilterM.FilteredReceiveMsg[MSG_NEIGHBOR_TEST];
  NeighborTestM.Enqueue -> NeighborFilterM.FilteredEnqueue;
  NeighborTestM.Leds -> LedsC;
  NeighborTestM.Timer -> TimerC.Timer[unique("Timer")];

  Main.StdControl -> NeighborFilterM;
  NeighborFilterM.UnfilteredEnqueue -> TxManC;
  NeighborFilterM.UnfilteredReceiveMsg -> GenericComm.ReceiveMsg;
  NeighborFilterM.ReadNeighborStore -> NeighborStoreM;
  NeighborFilterM.WriteNeighborStore -> NeighborStoreM;


//  NeighborBeaconTestM.configureThresholds -> NeighborFilterM;

  
}
