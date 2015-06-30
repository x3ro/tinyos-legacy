includes topo;
includes Zone;

configuration ZoneApp {
}
implementation {
  components Main, ZoneAppM, BeaconM, LedsC, TimerC, ZoneM, GenericComm as Comm, RandomLFSR;

  Main.StdControl -> ZoneAppM;

  ZoneAppM.BeaconControl -> BeaconM.StdControl;
  ZoneAppM.Beacon -> BeaconM;
  ZoneAppM.Zone -> ZoneM;
  ZoneAppM.Leds -> LedsC;
  
  BeaconM.BeaconComm -> Comm;
  BeaconM.BeaconSend -> Comm.SendMsg[66];
  BeaconM.BeaconRcv -> Comm.ReceiveMsg[66];
  BeaconM.BeaconTimer -> TimerC.Timer[unique("Timer")];
  BeaconM.BeaconRandom -> RandomLFSR;
}
