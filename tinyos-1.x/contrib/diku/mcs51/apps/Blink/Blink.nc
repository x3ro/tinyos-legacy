/* 
*/

configuration Blink {
}
implementation {
  components Main, BlinkM, LedsC;
  Main.StdControl -> BlinkM.StdControl;
  BlinkM.Leds -> LedsC;
}

