/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	MTS310.nc
**
**	Purpose:	This Configuration allows users to wire 
**				the MTS310/300 sensorboards to the  
**				mica2 mote.  Look at MTS310M.nc for more 
**				information on how the sensing is done.
*********************************************************/
includes CmdMsg;

configuration MTS310 {
	provides interface MTS310Interface;
}
implementation {
	components Main, MTS310M, TimerC, LedsC;
	components Voltage, MicC, PhotoTemp, Accel, Mag, Sounder;
	
	
	Main.StdControl -> MTS310M;
	Main.StdControl -> TimerC;
	
	// Wiring for voltage control/battery
	MTS310M.BattControl -> Voltage;
	MTS310M.ADCBATT -> Voltage;
	
	// Wiring for Temp
	MTS310M.TempControl -> PhotoTemp.TempStdControl;
	MTS310M.Temperature -> PhotoTemp.ExternalTempADC;
	
	// Wiring for Photo/Light
	MTS310M.PhotoControl -> PhotoTemp.PhotoStdControl;
	MTS310M.Light -> PhotoTemp.ExternalPhotoADC;
	
	// Wiring for Sounder
	MTS310M.Sounder -> Sounder;
	
	// Wiring for Mic
	MTS310M.MicControl -> MicC;
	MTS310M.Mic -> MicC;
	MTS310M.MicADC -> MicC;
	
	#ifndef MTS300
		// Wiring for Accel
		MTS310M.AccelControl -> Accel;
		MTS310M.AccelX -> Accel.AccelX;
		MTS310M.AccelY -> Accel.AccelY;
		
		// Wiring for Magnotometer
		MTS310M.MagControl -> Mag;
		MTS310M.MagX -> Mag.MagX;
		MTS310M.MagY -> Mag.MagY;
	#endif
	
	// Wiring for Leds
	MTS310M.Leds -> LedsC;
		
	// Wiring for Timer
	MTS310M.Timer -> TimerC.Timer[unique("Timer")];
	
	// Wiring for Sensor Component
	MTS310Interface = MTS310M.MTS310Interface;
}
