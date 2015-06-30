configuration Atm128EnergyHandlerC {
	provides {
		interface Atm128EnergyHandler;
	}
}

implementation {
	components Atm128EnergyHandlerP, McuSleepC;

	Atm128EnergyHandler = Atm128EnergyHandlerP;

//	MainC.SoftwareInit -> McuSleepC;

	McuSleepC.Atm128EnergyHandler -> Atm128EnergyHandlerP;
}
