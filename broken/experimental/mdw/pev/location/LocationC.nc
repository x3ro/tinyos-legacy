includes Location;

configuration LocationC {
  provides interface Location;
} implementation {

  components Main, LocationM, AbstractTimerC(), 
    GenericCommAC(AM_LOCATIONMSG) as Comm, RandomLFSR;

  Location = LocationM;

  Main.StdControl -> Comm;
  Main.StdControl -> RandomLFSR;

  LocationM.Timer -> AbstractTimerC;
  LocationM.ReceiveMsg -> Comm.ReceiveMsg;
  LocationM.SendMsg -> Comm.SendMsg;
  LocationM.Random -> RandomLFSR;

}
