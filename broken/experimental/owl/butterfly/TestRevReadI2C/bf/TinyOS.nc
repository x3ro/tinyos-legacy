configuration TinyOS { }
implementation {
  components Main, LCDC, Demo, I2CPacketSlaveC;

  Main.StdControl -> Demo;
  Main.StdControl -> LCDC;
  Main.StdControl -> I2CPacketSlaveC;

  Demo.LCD -> LCDC;
  Demo.I2CPacketSlave -> I2CPacketSlaveC;
}

