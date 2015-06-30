configuration TinyOS { }
implementation {
  components Main, Fun, LedsC;

  Main.StdControl -> Fun;

  Fun.Leds -> LedsC;
}
