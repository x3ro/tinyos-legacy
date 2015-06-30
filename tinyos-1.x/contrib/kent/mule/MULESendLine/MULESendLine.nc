/** MULETest.nc
 *
 * This app sends counter values out over the radio, and tracks the number
 * of packets that have been lost.
 * Probably on works under TOSSIM, which is fine because I don't care if it
 * doesn't work on real motes.
 * 
**/

includes IntMsg;

configuration MULESendLine {
}
implementation {
  components Main, MyCounter as Counter, MyCounter2 as Counter2,
    MyIntToRfm, MyIntToRfm2, TimerC, GenericComm, MULESendLineM, LedsC;

  MULESendLineM.CounterControl -> Counter.StdControl;
  MULESendLineM.Counter2Control -> Counter2.StdControl;
  Main.StdControl -> MyIntToRfm.StdControl;
  Main.StdControl -> MULESendLineM;

  Counter.Timer -> TimerC.Timer[unique("Timer")];
  Counter.IntOutput -> MyIntToRfm.IntOutput;
  
  Counter2.Timer -> TimerC.Timer[unique("Timer")];
  Counter2.IntOutput -> MyIntToRfm2.IntOutput;

  MULESendLineM.ReceiveIntMsg -> GenericComm.ReceiveMsg[AM_INTMSG];
  MULESendLineM.CommControl -> GenericComm;
  MULESendLineM.Leds -> LedsC;
}
