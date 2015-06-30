// Display "TinyOS" on the screen
configuration TinyOS { }
implementation {
  components Main, LCDC, Demo, JoystickC;

  Main.StdControl -> Demo;
  Main.StdControl -> LCDC;
  Main.StdControl -> JoystickC;

  Demo.LCD -> LCDC;
  Demo.Joystick -> JoystickC;
}

