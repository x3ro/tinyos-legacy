// Display "TinyOS" on the screen
configuration TinyOS { }
implementation {
  components Main, LCDC, Demo;

  Main.StdControl -> Demo;
  Main.StdControl -> LCDC;

  Demo.LCD -> LCDC;
}

