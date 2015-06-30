configuration NeighborBeacon 
{
  provides {
    interface StdControl;
  }
  uses {
    interface ReceiveMsg;
    interface Enqueue;
    interface TxManControl;
    interface Leds;
    interface ReadNeighborStore;
    interface WriteNeighborStore;
    interface Timer as BeaconTimer;
    interface Timer as TxManTimer;
  }
}
implementation
{
  components NeighborBeaconM, RandomLFSR;

  StdControl = NeighborBeaconM.StdControl;

  ReadNeighborStore = NeighborBeaconM.ReadNeighborStore;
  WriteNeighborStore = NeighborBeaconM.WriteNeighborStore;

  Enqueue = NeighborBeaconM.Enqueue;
  ReceiveMsg = NeighborBeaconM.ReceiveMsg;
  Leds = NeighborBeaconM.Leds;
  TxManControl = NeighborBeaconM.TxManControl;
  
  BeaconTimer = NeighborBeaconM.BeaconTimer;
  TxManTimer = NeighborBeaconM.TxManTimer;
  NeighborBeaconM.Random -> RandomLFSR;
}
