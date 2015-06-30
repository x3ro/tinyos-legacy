configuration RadioTest {}
implementation {
	components ClockMSM;

	components Main, RadioTestM, RadioSPIC, LedsC;
	RadioTestM.RadioSPI -> RadioSPIC;
	RadioTestM.Debug -> RadioSPIC;
	RadioTestM.Clock -> ClockMSM.Clock[unique("ClockMSM")];
	RadioTestM.ClockControl -> ClockMSM;

	Main.StdControl -> RadioTestM;
	RadioTestM.Leds -> LedsC;
}

