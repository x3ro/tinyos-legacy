// Display "TinyOS" on the screen
configuration TinyOS { }
implementation {
  components Main, Sounder, Demo, TimerC, LCDC, JoystickC;

  Main.StdControl -> Demo;
  Main.StdControl -> Sounder;
  Main.StdControl -> LCDC;
  Main.StdControl -> JoystickC;
  Main.StdControl -> TimerC;

  Demo.Sound -> Sounder;
  Demo.Joystick -> JoystickC;
  Demo.LCD -> LCDC;
  Demo.Timer -> TimerC.Timer[unique("Timer")];
}

