configuration TinyOS { }
implementation {
  components Main, I2CPacketC, Fun, LedsC, TimerC, IntToLeds;

  Main.StdControl -> Fun;
  Main.StdControl -> I2CPacketC;
  Main.StdControl -> TimerC;
  Main.StdControl -> IntToLeds;

  Fun.I2CPacket -> I2CPacketC.I2CPacket[0x41];
  Fun.Leds -> LedsC;
  Fun.Timer -> TimerC.Timer[unique("Timer")];
  Fun.IntOutput -> IntToLeds;
}
