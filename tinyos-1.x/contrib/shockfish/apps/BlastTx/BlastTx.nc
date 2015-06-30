configuration BlastTx {}

implementation {
  components Main, RadioCRCPacket, LedsC, BlastTxM, TimerC, XE1205RadioC, RandomLFSR, XE1205RadioM;

  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> BlastTxM.StdControl;
  Main.StdControl -> RadioCRCPacket.Control;
  
  BlastTxM.SendTimer -> TimerC.Timer[unique("Timer")];
  BlastTxM.ExitTimer -> TimerC.Timer[unique("Timer")];
  BlastTxM.Leds -> LedsC;
  BlastTxM.Random -> RandomLFSR;
  BlastTxM.Send -> RadioCRCPacket.Send;

  BlastTxM.XE1205Control -> XE1205RadioC;
  BlastTxM.CSMAControl -> XE1205RadioC;
  BlastTxM.XE1205LPL -> XE1205RadioM;

  BlastTxM.enableInitialBackoff -> XE1205RadioM.enableInitialBackoff; 
  BlastTxM.disableInitialBackoff -> XE1205RadioM.disableInitialBackoff; 
}
