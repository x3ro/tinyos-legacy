includes AM;
includes msg_types;
includes OnePhasePull;
configuration OnePhasePullNlist
{
  provides 
  {
    interface StdControl;

    interface Publish;
    interface Subscribe;
    interface Filter[uint8_t priority];
#ifdef ENABLE_GRADIENT_OVERRIDE
    interface DiffusionControl;
#endif
  }
}
implementation
{
  components OnePhasePullM,
	     TxManC,
	     ExtGenericComm as GenericComm,
	     NeighborFilterM,
	     NeighborBeacon,
	     NeighborStoreM,
	     TimerC,
	     LedsC,
	     NoLeds;

  /* These are the initializations of the modules used by pretty much all the
   * other modules... so, these should be initialized at the highest level and
   * only once

  StdControl = TimerC.StdControl;
  StdControl = GenericComm.Control;

   */

  StdControl = TxManC.Control;
  StdControl = OnePhasePullM.StdControl;
  StdControl = NeighborBeacon.StdControl;
  StdControl = NeighborFilterM.StdControl;
  StdControl = NeighborStoreM.StdControl;

  NeighborBeacon.Enqueue -> TxManC;
  NeighborBeacon.ReceiveMsg -> GenericComm.ReceiveMsg[MSG_NEIGHBOR_BEACON];
  NeighborBeacon.Leds -> NoLeds;

  // Intentionally, not wired... default command makes sure it compiles...
  // OnePhasePull is the one that supplies the TxMan tick.
  //NeighborBeacon.TxManControl -> TxManC;
  NeighborBeacon.ReadNeighborStore -> NeighborStoreM;
  NeighborBeacon.WriteNeighborStore -> NeighborStoreM;
  NeighborBeacon.BeaconTimer -> TimerC.Timer[unique("Timer")];
  NeighborBeacon.TxManTimer -> TimerC.Timer[unique("Timer")];

  NeighborFilterM.UnfilteredEnqueue -> TxManC;
  NeighborFilterM.UnfilteredReceiveMsg -> GenericComm.ReceiveMsg;
  NeighborFilterM.ReadNeighborStore -> NeighborStoreM;
  NeighborFilterM.WriteNeighborStore -> NeighborStoreM;

  Subscribe = OnePhasePullM.Subscribe;
  Publish = OnePhasePullM.Publish;
  Filter = OnePhasePullM.Filter;
#ifdef ENABLE_GRADIENT_OVERRIDE
  DiffusionControl = OnePhasePullM.DiffusionControl;
#endif

  OnePhasePullM.Timer -> TimerC.Timer[unique("Timer")];
  OnePhasePullM.Leds -> LedsC;
  OnePhasePullM.TxManControl -> TxManC.TxManControl;

  OnePhasePullM.TxInterestMsg -> NeighborFilterM.FilteredEnqueue; 
  OnePhasePullM.TxDataMsg -> NeighborFilterM.FilteredEnqueue;

  OnePhasePullM.RxInterestMsg -> NeighborFilterM.FilteredReceiveMsg[ESS_OPP_INTEREST];
  OnePhasePullM.RxDataMsg -> NeighborFilterM.FilteredReceiveMsg[ESS_OPP_DATA];

  TxManC.CommSendMsg -> GenericComm.SendMsg;
}
