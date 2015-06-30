/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	MTS400.nc
**
**	Purpose:	This Configuration allows users to wire 
**				the MTS400 sensorboards to the  
**				mica2 mote.  Look at MTS400M.nc for more 
**				information on how the sensing is done.
**
**	Future:		Allow users to use either the MTS420 or 
**				MTS400 with #define macro
**
*********************************************************/
includes CmdMsg;

configuration MTS400 {
	provides interface MTS400Interface;
}
implementation {
	components MTS400M, Main;
	components MicaWbSwitch, Voltage, TaosPhoto, ADCC;
	components Accel, IntersemaPressure, SensirionHumidity;
	components TimerC;
	components LedsC;
	
	Main.StdControl -> MTS400M;
	Main.StdControl -> TimerC;
	
	// Wiring for Accelerometer
	MTS400M.AccelControl -> Accel.StdControl;
	MTS400M.AccelCmd -> Accel.AccelCmd;
	MTS400M.AccelX -> Accel.AccelX;
	MTS400M.AccelY -> Accel.AccelY;
	
	// Wiring for Intersema barometric Pressure / temperateure sensor
	MTS400M.IntersemaCal -> IntersemaPressure;
	MTS400M.PressureControl -> IntersemaPressure;
	MTS400M.IntersemaPressure -> IntersemaPressure.Pressure;
	MTS400M.IntersemaTemp -> IntersemaPressure.Temperature;
	
	// Wiring for BatteryReference
	MTS400M.BattControl -> Voltage;
	MTS400M.ADCBATT -> Voltage;
	
	// Wiring for Taos Light Sensor
	MTS400M.TaosControl -> TaosPhoto;
	MTS400M.TaosCh0 -> TaosPhoto.ADC[0];
	MTS400M.TaosCh1 -> TaosPhoto.ADC[1];
	
	// Wiring for Sensirion Humidity/temperature sensor
	MTS400M.TempHumControl -> SensirionHumidity;
	MTS400M.Humidity -> SensirionHumidity.Humidity;
	MTS400M.Temperature -> SensirionHumidity.Temperature;
	MTS400M.HumidityError -> SensirionHumidity.HumidityError;
	MTS400M.TemperatureError -> SensirionHumidity.TemperatureError;
	
	// Wiring for SensorTimer	
	MTS400M.Timer -> TimerC.Timer[unique("Timer")];
	
	// Wiring for SensorComponent
	MTS400Interface = MTS400M.MTS400Interface;	
}

