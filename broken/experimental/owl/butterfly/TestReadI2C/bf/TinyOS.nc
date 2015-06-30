configuration TinyOS { }
implementation {
  components Main, LCDC, Demo, I2CPacketC, TimerC;

  Main.StdControl -> Demo;
  Main.StdControl -> LCDC;
  Main.StdControl -> I2CPacketC;
  Main.StdControl -> TimerC;

  Demo.LCD -> LCDC;
  Demo.I2CPacket -> I2CPacketC.I2CPacket[0x42];
  Demo.Timer -> TimerC.Timer[unique("Timer")];
}

