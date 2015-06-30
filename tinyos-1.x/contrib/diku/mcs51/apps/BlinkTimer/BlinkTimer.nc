/* 
*/

configuration BlinkTimer {
}
implementation {
  components Main, BlinkTimerM, LedsC, SingleTimer;
  Main.StdControl -> BlinkTimerM.StdControl;
  Main.StdControl -> SingleTimer.StdControl;
  BlinkTimerM.Timer -> SingleTimer.Timer;
  BlinkTimerM.Leds -> LedsC;
}
