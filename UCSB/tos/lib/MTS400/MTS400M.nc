/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	MTS400M.nc
**
**	Purpose:	This Module allows users to interface 
**				with MTS400Interface to merely call 
**				startSensing() to acquire data from all 
**				of the components on an MTS400 sensor. 
**
**	Future:		Allow users to use either the MTS420 or 
**				MTS400 with #define macro
**
*********************************************************/
includes CmdMsg;

module MTS400M {
	provides interface StdControl;
	provides interface MTS400Interface;
	
	uses {
		// Battery
		interface ADC as ADCBATT;
		interface StdControl as BattControl;
		
		// Sensirion
		interface SplitControl as TempHumControl;
		interface ADC as Humidity;
		interface ADC as Temperature;
		interface ADCError as HumidityError;
		interface ADCError as TemperatureError;
		
		// Taos
		interface SplitControl as TaosControl;
		interface ADC as TaosCh0;
		interface ADC as TaosCh1;
		
		// Accel
		interface StdControl as AccelControl;
		interface I2CSwitchCmds as AccelCmd;
		interface ADC as AccelX;
		interface ADC as AccelY;
		
		// Intersema
		interface SplitControl as PressureControl;
		interface ADC as IntersemaTemp;
		interface ADC as IntersemaPressure;
		interface Calibration as IntersemaCal;
		
		// Timer
		interface Timer;
		
	}
}
implementation {
	MTS400DataMsg mts400Data;
	MTS400DataMsgPtr pMts400Data;
	uint8_t count;
	uint16_t calibration[4];
	
	command result_t StdControl.init() {
		atomic pMts400Data = & mts400Data;
		count = 0;
		call BattControl.init();		
		call PressureControl.init();
		call AccelControl.init();
		
		call TaosControl.init();
		call TempHumControl.init();
		
		return SUCCESS;
	}
	command result_t StdControl.start() {
		call HumidityError.enable();
		call TemperatureError.enable();
		
		call BattControl.start();
		
		return SUCCESS;
	}
	command result_t StdControl.stop() {
		call BattControl.stop();
		return SUCCESS;
	}
	command result_t MTS400Interface.startSensing() {
		call ADCBATT.getData();
		return SUCCESS;
	}
	default event result_t MTS400Interface.sensingDone(MTS400DataMsgPtr pData) {
		//pMts400Data = pData;
			
		return SUCCESS;
	}
	/************************************************************
	**  Take BatteryReading
	************************************************************/
	task void ADCBATTDone() {
		call TempHumControl.start();
		return;
	}
	async event result_t ADCBATT.dataReady(uint16_t data) {
		atomic pMts400Data->vref = data;
		//call TempHumControl.start();
		post ADCBATTDone();
		return SUCCESS;
	}
	
	/************************************************************
	**  Take Sensirion SHT11 humidity/temperature sensor
	** 	- Humidity data is 12 bit
	**	- Temperature data is 14 bit
	************************************************************/
	task void TempHumControlStop() {
		call TempHumControl.stop();
		return;
	}
	async event result_t Temperature.dataReady(uint16_t data) {
		atomic pMts400Data->temperature = data;
		//call TempHumControl.stop();	
		post TempHumControlStop();
		return SUCCESS;
	}
	async event result_t Humidity.dataReady(uint16_t data) {
		atomic pMts400Data->humidity = data;
		call Temperature.getData();
		return SUCCESS;
	}
	event result_t TempHumControl.startDone() {
		call Humidity.getData();
		return SUCCESS;
	}
	event result_t TempHumControl.initDone() {
		return SUCCESS;
	}
	event result_t TempHumControl.stopDone() {
		call AccelCmd.PowerSwitch(1);
		return SUCCESS;
	}
	event result_t HumidityError.error(uint8_t token) {
		call Temperature.getData();
		return SUCCESS;
	}
	event result_t TemperatureError.error(uint8_t token) {
		call TempHumControl.stop();
		return SUCCESS;
	}
	
	
	/************************************************************
	**  Accelerometer
	************************************************************/
	task void AccelDone() {
		call AccelCmd.PowerSwitch(0);
		return;
	}
	async event result_t AccelX.dataReady(uint16_t data) {
		atomic pMts400Data->accel_x = data;
		call AccelY.getData();
		return SUCCESS;
	}
	async event result_t AccelY.dataReady(uint16_t data) {
		atomic pMts400Data->accel_y = data;	
		//call AccelCmd.PowerSwitch(0);
		post AccelDone();
		return SUCCESS;
	}
	event result_t AccelCmd.SwitchesSet(uint8_t PowerState) {
		if(PowerState) {
			call AccelX.getData();
		}
		else {
			call PressureControl.start();		
		}
		return SUCCESS;
	}
	
	/************************************************************
	**  Intersema barometric pressure/temperature sensor
	**	- Temperature Measurement
	**	- Pressure Measurement
	************************************************************/
	task void StopPressure() {
		call PressureControl.stop();
		return;
	}
	async event result_t IntersemaPressure.dataReady(uint16_t data) {
		atomic pMts400Data->pressure = data;
		call IntersemaTemp.getData();
		return SUCCESS;
	}
	async event result_t IntersemaTemp.dataReady(uint16_t data) {
		atomic pMts400Data->intersematemp = data;
		//call PressureControl.stop();
		post StopPressure();
		return SUCCESS;
	}
	
	// Not quite sure how this one works, or what it means
	event result_t IntersemaCal.dataReady(char word, uint16_t data) {
		count++;
		calibration[word-1] = data;
		if(count == 4) {
			atomic {
				pMts400Data->cal_wrod1 = calibration[0];
				pMts400Data->cal_wrod2 = calibration[1];
				pMts400Data->cal_wrod3 = calibration[2];
				pMts400Data->cal_wrod4 = calibration[3];
			}	
			call IntersemaPressure.getData();
		}
		else {
			call IntersemaCal.getData();
		}
		return SUCCESS;
	}
	event result_t PressureControl.initDone() {
		return SUCCESS;
	}
	event result_t PressureControl.stopDone() {
		call TaosControl.start();
		return SUCCESS;
	}
	event result_t PressureControl.startDone() {
		count = 0;
		call IntersemaCal.getData();
		return SUCCESS;
	}
	
	/************************************************************
	**  Taos -ts12250 light sensor
	**	Two ADC channels: taosch0, taosch1
	************************************************************/
	task void TaosStop() {
		call TaosControl.stop();
	}
	async event result_t TaosCh1.dataReady(uint16_t data) {
		atomic pMts400Data->taosch1 = data & 0x00ff;
		//call TaosControl.stop();
		post TaosStop();
		return SUCCESS;
	}
	async event result_t TaosCh0.dataReady(uint16_t data) {
		atomic pMts400Data->taosch0 = data & 0x00ff;
		call TaosCh1.getData();
		return SUCCESS;
	}
	event result_t TaosControl.startDone() {
		return call TaosCh0.getData();
	}
	event result_t TaosControl.initDone() {
		return SUCCESS;
	}
	event result_t TaosControl.stopDone() {
		signal MTS400Interface.sensingDone(pMts400Data);
		return SUCCESS;
	}
	
	/*************************************************************
	**	Timer: For the sake of testing, not currently in use
	*************************************************************/
	event result_t Timer.fired() {
		return SUCCESS;
	}
	
	
	
}





























