configuration RouteTimer {
	provides {
		interface Timer[uint8_t id];
	}
}
implementation {
	components Main, RouteTimerM, ClockC;
	Main.StdControl->RouteTimerM.StdControl;
	Timer = RouteTimerM.Timer;
	RouteTimerM.Clock->ClockC.Clock;

}
