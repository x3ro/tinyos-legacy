configuration TestMicro4 {

}
implementation {
	components Main,TestMicro4M, 
		TimerC, 
		LedsC, 
		ExtLedsC, 
		HPLKBIC, 
		StdOutC,
		BusArbitrationC,
		SimpleMacC,
		LocalTimeMicroC,
		HPLSpiM;

	Main.StdControl -> TimerC.StdControl;
	Main.StdControl -> BusArbitrationC.StdControl;
	Main.StdControl -> TestMicro4M.StdControl;

	TestMicro4M.Leds -> LedsC;
	TestMicro4M.ExtLeds -> ExtLedsC;
	TestMicro4M.StdOut -> StdOutC.StdOutUart;
	TestMicro4M.Timer -> TimerC.Timer[unique("Timer")];

	TestMicro4M.BusArbitration -> BusArbitrationC.BusArbitration[unique("BusArbitration")];
	
	TestMicro4M.SimpleMac -> SimpleMacC.SimpleMac;
	TestMicro4M.SimpleMacControl -> SimpleMacC.StdControl;

	TestMicro4M.LocalTime -> LocalTimeMicroC.LocalTime;

	SimpleMacC.StdOut -> StdOutC.StdOutUart;
  
	TestMicro4M.KBI -> HPLKBIC.KBI;
	HPLKBIC.Timer -> TimerC.Timer[unique("Timer")];
}

