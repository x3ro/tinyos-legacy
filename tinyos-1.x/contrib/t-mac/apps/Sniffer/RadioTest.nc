configuration RadioTest {}
implementation {

	components Main, RadioTestM, RadioControl, LedsC;
	RadioTestM.Radio -> RadioControl;
	RadioTestM.Debug -> RadioControl;
	RadioTestM.RadioState -> RadioControl;
	RadioTestM.PhyComm -> RadioControl;

	Main.StdControl -> RadioTestM;
	RadioTestM.Leds -> LedsC;
}

