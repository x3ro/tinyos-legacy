// Display "TinyOS" on the screen
configuration TinyOS { }
implementation {
  components Main, LCDC, Demo, Photo, Temp, TimerC, JoystickC;

  Main.StdControl -> Demo;
  Main.StdControl -> LCDC;
  Main.StdControl -> TimerC;
  Main.StdControl -> Photo;
  Main.StdControl -> Temp;
  Main.StdControl -> JoystickC;

  Demo.LCD -> LCDC;
  Demo.Timer -> TimerC.Timer[unique("Timer")];
  Demo.Joystick -> JoystickC;
  Demo.Photo -> Photo;
  Demo.Temp -> Temp;
}

