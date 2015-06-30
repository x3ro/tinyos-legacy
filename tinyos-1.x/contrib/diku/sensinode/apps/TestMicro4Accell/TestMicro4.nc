configuration TestMicro4 {

}
implementation {
	components Main,TestMicro4M, 
			TimerC, 
			LedsC, 
			StdOutC, 
			AccelerometerC, 
			BusArbitrationC,
			LocalTimeMicroC,
			HPLSpiM;

	Main.StdControl -> TimerC.StdControl;
	Main.StdControl -> TestMicro4M.StdControl;
	Main.StdControl -> BusArbitrationC.StdControl;

	TestMicro4M.Leds -> LedsC;
	TestMicro4M.Spi -> HPLSpiM;
	TestMicro4M.StdOut -> StdOutC.StdOutUart;
	TestMicro4M.Timer -> TimerC.Timer[unique("Timer")];
	TestMicro4M.LocalTime		->	LocalTimeMicroC.LocalTime;

	TestMicro4M.ThreeAxisAccel	->	AccelerometerC.ThreeAxisAccel;
	
	AccelerometerC.StdOut -> StdOutC.StdOutUart;

}

