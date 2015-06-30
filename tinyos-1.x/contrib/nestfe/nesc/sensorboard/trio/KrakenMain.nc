// $Id: KrakenMain.nc,v 1.2 2005/08/12 00:00:45 jwhui Exp $

configuration KrakenMain
{
  uses interface StdControl as PreInitControl;
  uses interface SplitInit as Init;
  uses interface StdControl as AppControl;
}
implementation
{
  components Main;
  components MainM;
  components KrakenMainM;
  components HPLInitC;
  components CC2420RadioC;
  components BusArbitrationC;

  PreInitControl = KrakenMainM.PreInitControl;
  Init = KrakenMainM.Init;
  AppControl = KrakenMainM.AppControl;

  // any components that wire themselves to Main get put into AppControl
  KrakenMainM.RadioControl -> CC2420RadioC;
  KrakenMainM.BusArbitration -> BusArbitrationC.BusArbitration[unique("BusArbitration")];
  KrakenMainM.AppControl -> Main;

  // KrakenMainM will be called by MainM, the real main
  MainM.StdControl -> KrakenMainM;
  MainM.hardwareInit -> HPLInitC;
}

