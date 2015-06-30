includes mcuToRadioPorts;

configuration TestRadioDriver {
}
implementation {
	components Main,
	           TestRadioDriverM,
	           SingleTimer,
	           mc13192PhyDriverM,
	           mc13192PhyInitM,
	           //mc13192ControlM,
	           mc13192PhyInterruptM,
	           mc13192PhyTimerM,
	           //mc13192HardwareM,
	           LocalTimeM,
	           HPLTimer2M,
	           HPLSPIM as McuSPI,
	           ConsoleDebugM,
	           ConsoleC;

	Main.StdControl -> McuSPI.StdControl;
	Main.StdControl -> mc13192PhyInitM.StdControl;
	Main.StdControl -> mc13192PhyTimerM.StdControl;
	Main.StdControl -> ConsoleC.StdControl;
	Main.StdControl -> SingleTimer.StdControl;
	Main.StdControl -> HPLTimer2M.StdControl;
	Main.StdControl -> TestRadioDriverM.StdControl;

	TestRadioDriverM.Timer -> SingleTimer.Timer;
	TestRadioDriverM.PhyReceive -> mc13192PhyDriverM.PhyReceive;
	TestRadioDriverM.PhyTransmit -> mc13192PhyDriverM.PhyTransmit;
	TestRadioDriverM.PhyAttributes -> mc13192PhyDriverM.PhyAttributes;
	TestRadioDriverM.PhyEnergyDetect -> mc13192PhyDriverM.PhyEnergyDetect;
	TestRadioDriverM.LocalTime -> LocalTimeM.LocalTime;
	//LocalTimeM.HPLTimer -> HPLTimer2M.HPLTimer;

	mc13192PhyDriverM.Interrupt -> mc13192PhyInterruptM.Interrupt;
	mc13192PhyDriverM.Timer -> mc13192PhyTimerM.Timer;
	
	// Wire up the SPI.
	mc13192PhyInitM.SPI -> McuSPI.SPI;
	mc13192PhyDriverM.SPI -> McuSPI.SPI;
	mc13192PhyInterruptM.SPI -> McuSPI.SPI;
	mc13192PhyTimerM.SPI -> McuSPI.SPI;
	//mc13192HardwareM.SPI -> McuSPI.SPI;

	//mc13192ControlM.Regs -> mc13192HardwareM.Regs;

	// Wire debug module.
	ConsoleDebugM.ConsoleOut -> ConsoleC.ConsoleOut;
	mc13192PhyDriverM.Debug -> ConsoleDebugM.Debug;
	mc13192PhyInterruptM.Debug -> ConsoleDebugM.Debug;
	mc13192PhyTimerM.Debug -> ConsoleDebugM.Debug;
	TestRadioDriverM.Debug -> ConsoleDebugM.Debug;
}






