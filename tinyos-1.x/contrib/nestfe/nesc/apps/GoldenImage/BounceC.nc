configuration BounceC {
  provides interface StdControl;
}
implementation {
  components RadioCRCPacket;
  components TimerC;
  components BounceM;
  components NoLeds as Leds;

  StdControl = BounceM;
  StdControl = TimerC;

  BounceM.Leds -> Leds;

  BounceM.Timer -> TimerC.Timer[unique("Timer")];
  BounceM.CommControl -> RadioCRCPacket;
}
