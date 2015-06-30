// Display "TinyOS" on the screen
configuration TinyOS { }
implementation {
  components Main, Demo;

  Main.StdControl -> Demo;
}

