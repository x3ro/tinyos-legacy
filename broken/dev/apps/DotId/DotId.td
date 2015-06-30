configuration DotId { }
implementation {

  components Main, DotIdM, GenericComm as Comm, Logger, LedsC;

  Main.StdControl -> DotIdM;
  DotIdM.Leds -> LedsC;

  DotIdM.LoggerWrite -> Logger.LoggerWrite;
  DotIdM.LoggerRead -> Logger.LoggerRead;
  DotIdM.LoggerControl->Logger.StdControl;

  DotIdM.CommControl -> Comm;
  DotIdM.SendDotIdMsg -> Comm.SendMsg[100];

}
