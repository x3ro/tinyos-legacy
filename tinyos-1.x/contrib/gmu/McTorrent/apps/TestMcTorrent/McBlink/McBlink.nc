configuration McBlink {
}
implementation {
  components Main, McBlinkM, LedsC, TimerC, McTorrentC;

  Main.StdControl -> McTorrentC;
  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> McBlinkM.StdControl;

  McBlinkM.Timer -> TimerC.Timer[unique("Timer")];
  McBlinkM.Leds -> LedsC;
}

