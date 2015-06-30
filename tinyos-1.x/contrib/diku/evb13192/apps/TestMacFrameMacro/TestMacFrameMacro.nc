includes macFrame;
includes mcuToRadioPorts;

configuration TestMacFrameMacro {
}
implementation {
	components Main,
	           TestMacFrameMacroM,
	           LedsC,
	           mc13192RawRadioC,
	           mc13192ControlM,
	           //mc13192DataM,
	           SingleTimer,
	           HPLSPIM as McuSPI,
	           ConsoleC;

	Main.StdControl -> McuSPI.StdControl;
	Main.StdControl -> ConsoleC.StdControl;
	Main.StdControl -> mc13192RawRadioC.StdControl;
	Main.StdControl -> SingleTimer.StdControl;
	Main.StdControl -> TestMacFrameMacroM.StdControl;
	TestMacFrameMacroM.Leds -> LedsC;
	TestMacFrameMacroM.ConsoleOut -> ConsoleC.ConsoleOut;
	TestMacFrameMacroM.Receive -> mc13192RawRadioC.Receive;
	TestMacFrameMacroM.Send -> mc13192RawRadioC.Send;
	TestMacFrameMacroM.RadioControl -> mc13192RawRadioC.Control;
	TestMacFrameMacroM.Timer -> SingleTimer.Timer;
	
	mc13192RawRadioC.SPI -> McuSPI.SPI;
	McuSPI.Leds -> LedsC;
}
