// Display "TinyOS" on the screen
configuration TinyOS { }
implementation {
  components Main, LCDC, Debugger, JoystickC, I2CPacketC, I2CPacketSlaveC;

  Main.StdControl -> Debugger;
  Main.StdControl -> LCDC;
  Main.StdControl -> JoystickC;
  Main.StdControl -> I2CPacketC;
  Main.StdControl -> I2CPacketSlaveC;

  Debugger.LCD -> LCDC;
  Debugger.Joystick -> JoystickC;
  Debugger.I2CPacket -> I2CPacketC.I2CPacket[0x42];
  Debugger.I2CPacketSlave -> I2CPacketSlaveC;
}

