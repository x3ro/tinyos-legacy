abstract configuration AbstractTimerC() {
  provides interface StdControl;
  provides interface Timer;
} implementation {

  components AbstractTimerM(), ClockC, NoLeds;

  AbstractTimerM.Clock -> ClockC;
  AbstractTimerM.Leds -> NoLeds;

  StdControl = AbstractTimerM;
  Timer = AbstractTimerM;
}
