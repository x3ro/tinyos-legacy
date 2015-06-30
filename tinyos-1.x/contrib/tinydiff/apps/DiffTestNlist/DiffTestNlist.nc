// Configuration file for OnePhasePull


includes AM;
includes msg_types;
includes OnePhasePull;
configuration DiffTestNlist
{
}
implementation 
{

  components Main, 
	     DiffTestNlistM, 
	     OnePhasePullM, 
	     TxManC, 
	     GenericComm, 
	     NeighborFilterM,
	     NeighborBeacon,
	     NeighborStoreM,
	     TimerC,
	     CC1000ControlM,
	     LedsC,
	     NoLeds;

  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> GenericComm.Control;
  Main.StdControl -> TxManC.Control;
  Main.StdControl -> DiffTestNlistM.StdControl;
  Main.StdControl -> OnePhasePullM.StdControl;
  Main.StdControl -> NeighborBeacon.StdControl;
  Main.StdControl -> NeighborFilterM.StdControl;
  Main.StdControl -> NeighborStoreM.StdControl;

  NeighborBeacon.Enqueue -> TxManC;
  NeighborBeacon.ReceiveMsg -> GenericComm.ReceiveMsg[MSG_NEIGHBOR_BEACON];
  NeighborBeacon.Leds -> NoLeds;
  // Intentionally, not wired... default command makes sure it compiles...
  // OnePhasePull is the one that supplies the TxMan tick.
  //NeighborBeacon.TxManControl -> TxManC;
  NeighborBeacon.ReadNeighborStore -> NeighborStoreM;
  NeighborBeacon.WriteNeighborStore -> NeighborStoreM;
  NeighborBeacon.BeaconTimer -> TimerC.Timer[7];
  NeighborBeacon.TxManTimer -> TimerC.Timer[8];

  NeighborFilterM.UnfilteredEnqueue -> TxManC;
  NeighborFilterM.UnfilteredReceiveMsg -> GenericComm.ReceiveMsg;
  NeighborFilterM.ReadNeighborStore -> NeighborStoreM;
  NeighborFilterM.WriteNeighborStore -> NeighborStoreM;

  DiffTestNlistM.Timer -> TimerC.Timer[9];
  DiffTestNlistM.Subscribe -> OnePhasePullM;
  DiffTestNlistM.Publish -> OnePhasePullM;
  DiffTestNlistM.DiffusionControl -> OnePhasePullM;
  DiffTestNlistM.Filter1 -> OnePhasePullM.Filter[0];
  DiffTestNlistM.Filter2 -> OnePhasePullM.Filter[1];
  DiffTestNlistM.CC1000Control -> CC1000ControlM;
  DiffTestNlistM.Leds -> LedsC;

  OnePhasePullM.Timer -> TimerC.Timer[10];
  OnePhasePullM.Leds -> LedsC;
  OnePhasePullM.TxManControl -> TxManC.TxManControl;

  OnePhasePullM.TxInterestMsg -> NeighborFilterM.FilteredEnqueue; 
  OnePhasePullM.TxDataMsg -> NeighborFilterM.FilteredEnqueue;

  OnePhasePullM.RxInterestMsg -> NeighborFilterM.FilteredReceiveMsg[ESS_OPP_INTEREST];
  OnePhasePullM.RxDataMsg -> NeighborFilterM.FilteredReceiveMsg[ESS_OPP_DATA];

  TxManC.CommSendMsg -> GenericComm.SendMsg;
}












