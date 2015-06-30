// Display "TinyOS" on the screen
configuration TinyOS { }
implementation {
  components Main, LCDC, Demo, TimerC;

  Main.StdControl -> Demo;
  Main.StdControl -> LCDC;
  Main.StdControl -> TimerC;

  Demo.LCD -> LCDC;
  Demo.Timer -> TimerC.Timer[unique("Timer")];
}

