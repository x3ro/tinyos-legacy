configuration PingPong {}

implementation {
  components Main, RadioCRCPacket, LedsC, PingPongM, TimerC, XE1205ControlM, XE1205RadioC, XE1205RadioM;

  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> PingPongM.StdControl;
  Main.StdControl -> RadioCRCPacket.Control;
  
  PingPongM.SendTimer -> TimerC.Timer[unique("Timer")];
  PingPongM.BlinkTimer -> TimerC.Timer[unique("Timer")];
  PingPongM.Leds -> LedsC;
  PingPongM.Send -> RadioCRCPacket.Send;
  PingPongM.Receive -> RadioCRCPacket.Receive;

  PingPongM.XE1205Control -> XE1205ControlM;
  PingPongM.CSMAControl -> XE1205RadioC;

  PingPongM.enableInitialBackoff -> XE1205RadioM.enableInitialBackoff; 
  PingPongM.disableInitialBackoff -> XE1205RadioM.disableInitialBackoff; 
}
