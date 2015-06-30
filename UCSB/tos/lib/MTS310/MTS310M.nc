/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	MTS310M.nc
**
**	Purpose:	This Module allows users to interface 
**				with MTS310Interface to merely call 
**				startSensing() to acquire data from all 
**				of the components on an MTS310 sensor. 
**
**	Future:
**
*********************************************************/
includes CmdMsg;
includes sensorboard;

module MTS310M {
	provides {
		interface MTS310Interface;
		interface StdControl;
	}
	uses {
		// Battery
		interface ADC as ADCBATT;
		interface StdControl as BattControl;	
		
		// Temp
		interface StdControl as TempControl;
		interface ADC as Temperature;
		
		// Light
		interface StdControl as PhotoControl;
		interface ADC as Light;
		
		// Mic
		interface StdControl as MicControl;
		interface Mic;
		interface ADC as MicADC;
		
		// Sounder
		interface StdControl as Sounder;
		
		#ifndef MTS300	
			// Accel
			interface StdControl as AccelControl;
			interface ADC as AccelX;
			interface ADC as AccelY;
			
			// Mag
			interface StdControl as MagControl;
			interface ADC as MagX;
			interface ADC as MagY;
		#endif
	
		// Timer ans Leds
		interface Timer;
		interface Leds;
	}
}
implementation {
	MTS310DataMsg dataMsg;
	MTS310DataMsgPtr pDataMsg;
	
	command result_t StdControl.init() {
		atomic pDataMsg = &dataMsg;
		call BattControl.init();
		call TempControl.init();
		call MicControl.init();
		call Mic.gainAdjust(64);
	
		#ifndef MTS300
			call AccelControl.init();
			call MagControl.init();
		#endif
	
		call Leds.init();
		return SUCCESS;
	}
	command result_t StdControl.start() {
	
		#ifndef MTS300
			call AccelControl.start();
			call MagControl.start();
		#endif
	
		return SUCCESS;
	}
	command result_t StdControl.stop() {
		call BattControl.stop();
		call TempControl.stop();
		call PhotoControl.stop();
		
		#ifndef MTS300
			call AccelControl.stop();
			call MagControl.stop();
		#endif
		
		return SUCCESS;
	}
	/*********************************************************
	**	Provided Content to start the sensing process 
	*********************************************************/
	command result_t MTS310Interface.startSensing() {
		call BattControl.start();
		call ADCBATT.getData();
		return SUCCESS;
	}
	
	/*********************************************************
	**	signaled event returning acquired data from 
	**	startSensing command
	*********************************************************/
	default event result_t MTS310Interface.sensingDone(MTS310DataMsgPtr pMsg) {
		return SUCCESS;
	}
	
	/*********************************************************
	**	Battery 
	*********************************************************/
	task void BattDone() {
		call BattControl.stop();
		call TempControl.start();
		call Temperature.getData();
		return;
	}
	async event result_t ADCBATT.dataReady(uint16_t data) {
		atomic pDataMsg->vref = data;
		post BattDone();
		return SUCCESS;
	}
	
	
	/*********************************************************
	**	Temperature
	*********************************************************/
	task void TempDone() {
		call TempControl.stop();
		call PhotoControl.start();
		call Light.getData();
		return;
	}
	async event result_t Temperature.dataReady(uint16_t data) {
		atomic pDataMsg->temp = data;
		post TempDone();
		return SUCCESS;
	}
	
	
	/*********************************************************
	**	Light
	*********************************************************/
	task void LightDone() {
		call PhotoControl.stop();
		call MicADC.getData();
		return;
	}
	async event result_t Light.dataReady(uint16_t data) {
		atomic pDataMsg->light = data;
		post LightDone();
		return SUCCESS;
	}
	
	/*********************************************************
	**	Microphone
	*********************************************************/
	task void MicDone() {
		#ifndef MTS300
			call AccelX.getData();
		#else
			signal MTS310Interface.sensingDone(pDataMsg);
		#endif
	}
	async event result_t MicADC.dataReady(uint16_t data) {
		atomic pDataMsg->mic = data;
		post MicDone();
		return SUCCESS;
	}
	
	/*********************************************************
	**	The following is done only if the user has declared 
	**	the sensor board to be the MTS310 instead of MTS300
	*********************************************************/
	
	#ifndef MTS300
		
		/*********************************************************
		**	Accel
		*********************************************************/
		task void AccelXDone() {
			call AccelY.getData();
			return;
		}
		task void AccelYDone() {
			call MagX.getData();
			return;
		}
		async event result_t AccelX.dataReady(uint16_t data) {
			atomic pDataMsg->accelX = data;
			post AccelXDone();
			return SUCCESS;
		}
		async event result_t AccelY.dataReady(uint16_t data) {
			pDataMsg->accelY = data;
			post AccelYDone();
			return SUCCESS;
		}
		
		/*********************************************************
		**	Magnotometer
		*********************************************************/
		task void MagXDone() {
			call MagY.getData();
			return;
		}
		task void MagYDone() {
			signal MTS310Interface.sensingDone(pDataMsg);
			return;
		}
		async event result_t MagX.dataReady(uint16_t data) {
			atomic pDataMsg->magX = data;
			post MagXDone();
			return SUCCESS;
		}
		async event result_t MagY.dataReady(uint16_t data) {
			atomic pDataMsg->magY = data;
			post MagYDone();
			return SUCCESS;
		}
	#endif
	event result_t Timer.fired() {
		return SUCCESS;
	}
}

