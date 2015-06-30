// Display "TinyOS" on the screen
configuration TinyOS { }
implementation {
  components Main, LCDC, Demo, JoystickC, I2CPacketC;

  Main.StdControl -> Demo;
  Main.StdControl -> LCDC;
  Main.StdControl -> JoystickC;
  Main.StdControl -> I2CPacketC;

  Demo.LCD -> LCDC;
  Demo.Joystick -> JoystickC;
  Demo.I2CPacket -> I2CPacketC.I2CPacket[0x42];
}

