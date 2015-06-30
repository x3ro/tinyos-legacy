configuration TestSwitch
{

}
implementation
{
	components Main, TestSwitchM, ConsoleC, HPLKBIC, LedsC;

	Main.StdControl -> TestSwitchM.StdControl;

	TestSwitchM.ConsoleOut -> ConsoleC.ConsoleOut;
	TestSwitchM.KBI -> HPLKBIC;
	TestSwitchM.Leds -> LedsC;
}






