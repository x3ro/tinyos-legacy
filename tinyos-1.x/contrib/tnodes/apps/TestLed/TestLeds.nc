configuration TestLeds {}
implementation {
	components Main, TestLedsM, TimerC, LedsC;

	Main.StdControl -> TimerC;
	Main.StdControl -> TestLedsM;
	TestLedsM.Leds -> LedsC;
  	TestLedsM.Timer -> TimerC.Timer[unique("Timer")];
}
