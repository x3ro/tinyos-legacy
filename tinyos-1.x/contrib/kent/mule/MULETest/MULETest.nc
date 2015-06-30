/** MULETest.nc
 *
 * This app sends counter values out over the radio, and tracks the number
 * of packets that have been lost.
 * Probably on works under TOSSIM, which is fine because I don't care if it
 * doesn't work on real motes.
 * 
**/

includes IntMsg;

configuration MULETest {
}
implementation {
  components Main, MyCounter as Counter, 
    IntToRfm, TimerC, GenericComm, MULETestM;

  Main.StdControl -> Counter.StdControl;
  Main.StdControl -> IntToRfm.StdControl;
  Main.StdControl -> MULETestM;

  Counter.Timer -> TimerC.Timer[unique("Timer")];
  Counter.IntOutput -> IntToRfm.IntOutput;

  MULETestM.ReceiveIntMsg -> GenericComm.ReceiveMsg[AM_INTMSG];
  MULETestM.CommControl -> GenericComm;
}
