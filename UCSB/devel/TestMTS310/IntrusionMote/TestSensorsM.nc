/*********************************************************
**	Author: 	Greg Moore - UCSB SensorNetProject
**
**	FileName:	TestSensorsM.nc
**
**	Purpose:	This module is set up as the communication 
**				and power management portion of the 
**				application.  Its allows MTS310M to take
**				care of the sensing and just receives the
**				data after the command MTS310Interface.startSensing
**				is called.  The application also allows the user to
**				change the Rate of collection, and radioPower 
**				dynamically.
**
**	Future:		-Time synchronization
**				-Allowance of smart user injected command timing
**				-User injected mic gain.
*********************************************************/
includes CmdMsg;

module TestSensorsM {
	provides interface StdControl;
	uses {
	  
	// Radio Power  
		interface Pot;
	    
	// Try Power Saving Modes
		interface CC1000Control;   
	   
	   
	//communication
		interface StdControl as CommControl;
		interface SendMsg as Send;
		interface ReceiveMsg as Receive;
		
	// Sensing
		interface MTS310Interface;
		
	// Leds
		interface Leds;
		
	// Timers
		interface Timer as SampleTimer;
		interface Timer as SleepTimer;
	}
}
	
implementation {  
	#define TIMER_PERIOD 5000            // timer period in msec
	  
	char count;
	uint8_t global_power;     
	uint32_t global_interval; 
	uint8_t sleep;
	TOS_Msg msg_buf;
	TOS_MsgPtr msg_ptr;
	  
	bool sending_packet, WaitingForSend;
	MTS310DataMsgPtr pMts310Data;
	MTS310DataMsgPtr gMts310Data;
	task void send_msg();
	  
	command result_t StdControl.init() {
	  	
		atomic {
			msg_ptr = &msg_buf;
			sending_packet = FALSE;
			WaitingForSend = FALSE;
		}    
	     
		TOSH_MAKE_FLASH_OUT_OUTPUT();             //tx output
		TOSH_MAKE_FLASH_CLK_OUTPUT();             //usart clk
	      
		call CommControl.init();
		   
		call Leds.init();
				      
		global_power = call CC1000Control.GetRFPower();
		global_interval = TIMER_PERIOD;
		sleep = 0;
		return SUCCESS;
	}
	command result_t StdControl.start() {
		call CommControl.start();
	       
		call SampleTimer.start(TIMER_REPEAT, global_interval);  // Start up sensing
	      
		return SUCCESS;
	}
	command result_t StdControl.stop() {
		call SampleTimer.stop();
		call CommControl.stop();      
		return SUCCESS;
	}
	task void send_msg() {
		pMts310Data = (MTS310DataMsg *)msg_ptr->data;
		pMts310Data->vref = gMts310Data->vref;
		pMts310Data->temp = gMts310Data->temp;
		pMts310Data->light = gMts310Data->light;
		pMts310Data->mic = gMts310Data->mic;
		#ifndef MTS300
			pMts310Data->accelX = gMts310Data->accelX;
			pMts310Data->accelY = gMts310Data->accelY;
			pMts310Data->magX = gMts310Data->magX;
			pMts310Data->magY = gMts310Data->magY;
		#else
			pMts310Data->accelX = 0;
			pMts310Data->accelY = 0;
			pMts310Data->magX = 0;
			pMts310Data->magY = 0;
		#endif		
		call CommControl.start();
		call Send.send(TOS_BCAST_ADDR, sizeof(MTS310DataMsg), msg_ptr);
		//call SleepTimer.stop();
		return;
	}
	  
	
	/******************************************************************************
	 * Timer fired, 
	 * Starts the test for the sensor
	 * Calls retrieveData which 
	 *****************************************************************************/
	event result_t SampleTimer.fired() {
	  	//call Leds.redToggle();
	    call MTS310Interface.startSensing();
		return SUCCESS;
	}
	event result_t SleepTimer.fired() {
		if(sleep%2 == 1) {
			call CommControl.stop();
		}
		else { 
			call CommControl.start();
		}
	      
		sleep++;
		return SUCCESS;
	}
	  
	event result_t MTS310Interface.sensingDone(MTS310DataMsgPtr mts310Data) {
		//call Leds.greenToggle();
		gMts310Data = mts310Data;
		
		post send_msg();
		return SUCCESS;
	}    
	  
	
	/****************************************************************************
	* Radio msg xmitted. 
	****************************************************************************/
	event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
	    
	    msg_ptr = msg;
	    msg_ptr->length = 0;
	    msg->length = 0;
	    //call Leds.yellowToggle();	     
		return SUCCESS;
	}
	  
	void cmdInterpret(TOS_MsgPtr msgIn_ptr) {
	    struct CmdMsg *cmdMsg = (struct CmdMsg *)msgIn_ptr->data;
	    
	    switch(cmdMsg->action) {
	      	case LED_ON:
	        	call Leds.yellowOn();
		        break;
	      	case LED_OFF:
	        	call Leds.yellowOff();
		        break;
	      	case RADIO_POWER:
	 	//       call Pot.set(cmdMsg->power);
	 	//       global_power = cmdMsg->power;
	 	    	call Leds.greenToggle();
	        	call CC1000Control.SetRFPower(cmdMsg->power);
	        break;
	      	case DATA_RATE:
	        	call Leds.greenToggle();
	        	call SampleTimer.stop();
	        	if(cmdMsg->interval != 0)
	        	  	call SampleTimer.start(TIMER_REPEAT, cmdMsg->interval);
	        	break;
	      	default:
	        	call Leds.greenOff();
	        	call Leds.yellowOff();
	        	call Leds.redOn();        
	    }
		if(cmdMsg->power == (call Pot.get())) 
			call Leds.redToggle();
	}
	  
	 /****************************************************************************
	 * Radio Msg received.  
	 * For now turn on LED and work from there
	 ****************************************************************************/
	event TOS_MsgPtr Receive.receive(TOS_MsgPtr data) {
	  	//msgIn_ptr = data;
		cmdInterpret(data);
		return data;
	}
}

