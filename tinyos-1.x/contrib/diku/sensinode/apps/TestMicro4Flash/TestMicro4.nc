configuration TestMicro4 {

}
implementation {
	components Main,TestMicro4M, TimerC, StdOutC, FlashAccessC, HPLSpiM, 
			LedsC, BusArbitrationC;
			

	Main.StdControl -> TestMicro4M.StdControl;
	Main.StdControl -> TimerC.StdControl;

    TestMicro4M.Spi -> HPLSpiM;
	TestMicro4M.Leds -> LedsC;
	TestMicro4M.Timer -> TimerC.Timer[unique("Timer")];

	TestMicro4M.StdOut -> StdOutC;
	TestMicro4M.FlashAccess -> FlashAccessC;
	TestMicro4M.FlashControl -> FlashAccessC;

	TestMicro4M.BusArbitration 	->	BusArbitrationC.BusArbitration[unique("BusArbitration")];

}

