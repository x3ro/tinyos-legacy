

includes spotlight;

configuration spotlight { }
implementation
{
  components Main, spotlightM, ResetC, TimeSyncC,TimerC, LedsC,  GenericComm as Comm,RandomLFSR;
  
  #ifdef PLATFORM_XSM2
  components PhotoC as Photo;
  #else
  components Photo;
  #endif
  Main.StdControl -> spotlightM;
  Main.StdControl -> TimerC;
  Main.StdControl -> TimeSyncC;
  
    
  spotlightM.samplingTimer -> TimerC.Timer[unique("Timer")];
  spotlightM.ReTransmissionTimer -> TimerC.Timer[unique("Timer")];      
  spotlightM.WaitForAckTimer -> TimerC.Timer[unique("Timer")];

  spotlightM.Leds -> LedsC;
  spotlightM.SensorControl -> Photo;
  spotlightM.ADC -> Photo;
  
  #ifdef PLATFORM_XSM2  
  spotlightM.Photo -> Photo;
  #endif
  
  spotlightM.CommControl -> Comm;
  
  spotlightM.ResetCounterMsg -> Comm.ReceiveMsg[AM_OSCOPERESETMSG];
  spotlightM.ReportAckMsg -> Comm.ReceiveMsg[AM_REPORTACKMSG];
  
  spotlightM.TxDataMsg -> Comm.SendMsg[AM_REPORTMSG];
  //  spotlightM.RxDataMsg -> Comm.ReceiveMsg[AM_REPORTMSG];  

  spotlightM.RxConfigMsg -> Comm.ReceiveMsg[AM_CONFIGMSG];  
    
  spotlightM.GlobalTime -> TimeSyncC;
  spotlightM.Reset->ResetC;
  spotlightM.Random ->RandomLFSR;
  
}
