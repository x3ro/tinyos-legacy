includes mcuToRadioPorts;

configuration TestTosRadioStack {
}
implementation {
	components Main,
	           TestTosRadioStackM,
	           /*GenericComm,*/
	           SingleTimer,
	           LedsC,
	           mc13192TOSRadioC as RadioCRCPacketC,
	           mc13192ControlM,
	           mc13192DataM,
	           HPLSPIM as McuSPI,
	           ConsoleDebugM,
	           ConsoleC;

	Main.StdControl -> McuSPI.StdControl;
	Main.StdControl -> RadioCRCPacketC.Control;
	Main.StdControl -> ConsoleC.StdControl;
	Main.StdControl -> SingleTimer.StdControl;
	//Main.StdControl -> GenericComm.Control;
	Main.StdControl -> TestTosRadioStackM.StdControl;

	TestTosRadioStackM.Timer -> SingleTimer.Timer;
	TestTosRadioStackM.Leds -> LedsC;
	//TestTosRadioStackM.Send -> GenericComm.SendMsg[60];
	//TestTosRadioStackM.Receive -> GenericComm.ReceiveMsg[60];

	// Wire debug module.
	ConsoleDebugM.ConsoleOut -> ConsoleC.ConsoleOut;
	TestTosRadioStackM.ConsoleOut -> ConsoleC.ConsoleOut;

	TestTosRadioStackM.Send -> RadioCRCPacketC.Send;
	TestTosRadioStackM.Receive -> RadioCRCPacketC.Receive;
	TestTosRadioStackM.RadioControl -> mc13192ControlM.RadioControl;
	TestTosRadioStackM.RadioCCA -> mc13192DataM.CCA;
	TestTosRadioStackM.RadioPowerMng -> mc13192ControlM.PowerMng;

	RadioCRCPacketC.SPI -> McuSPI.SPI;
	RadioCRCPacketC.Debug -> ConsoleDebugM.Debug;
	RadioCRCPacketC.ConsoleOut -> ConsoleC.ConsoleOut;
	McuSPI.Leds -> LedsC;
}






