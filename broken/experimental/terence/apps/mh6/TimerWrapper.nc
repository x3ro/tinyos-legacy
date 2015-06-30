configuration TimerWrapper {
  provides {
    interface Timer[uint8_t id];
  }
}


// old su's timer
implementation {
  components Main, TimerM, ClockC, NoLeds as Leds;
  Timer = TimerM.Timer;
  Main.StdControl -> TimerM.StdControl;
	
  TimerM.Clock -> ClockC;
  TimerM.Leds -> Leds;

}

/*
// my timer
implementation {
  components RouteTimer;
  Timer = RouteTimer.Timer;
}
*/
/*
implementation {
  components Main, TimerC;
  Main.StdControl -> TimerC;
  Timer = TimerC.Timer;


}
*/

