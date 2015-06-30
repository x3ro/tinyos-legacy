configuration BlastRx {}

implementation {
  components Main, RadioCRCPacket, LedsC, BlastRxM, XE1205RadioC, XE1205RadioM;

  Main.StdControl -> RadioCRCPacket.Control;
  Main.StdControl -> BlastRxM.StdControl;

  BlastRxM.XE1205LPL -> XE1205RadioM;

  BlastRxM.Leds -> LedsC;
  BlastRxM.Receive -> RadioCRCPacket.Receive;
  BlastRxM.XE1205Control -> XE1205RadioC;
  BlastRxM.CSMAControl -> XE1205RadioC;

  BlastRxM.enableInitialBackoff -> XE1205RadioM.enableInitialBackoff; 
  BlastRxM.disableInitialBackoff -> XE1205RadioM.disableInitialBackoff; 

  BlastRxM.RadioStdControl -> XE1205RadioM.StdControl;
}
