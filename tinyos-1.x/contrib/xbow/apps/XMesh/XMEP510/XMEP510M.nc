/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All Rights Reserved.
 *
 * Permission to use, copy, modify and distribute, this software and 
 * documentation is granted, provided the following conditions are met:
 *   1. The above copyright notice and these conditions, along with the 
 *      following disclaimers, appear in all copies of the software.
 *   2. When the use, copying, modification or distribution is for COMMERCIAL 
 *      purposes (i.e., any use other than academic research), then the 
 *      software (including all modifications of the software) may be used 
 *      ONLY with hardware manufactured by and purchased from 
 *      Crossbow Technology, unless you obtain separate written permission 
 *      from, and pay appropriate fees to, Crossbow.  For example, no right 
 *      to copy and use the software on non-Crossbow hardware, if the use is 
 *      commercial in nature, is permitted under this license. 
 *   3. When the use, copying, modification or distribution is for 
 *      NON-COMMERCIAL PURPOSES (i.e., academic research use only), the 
 *      software may be used, whether or not with Crossbow hardware, 
 *      without any fee to Crossbow. 
 *
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN 
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED 
 * HEREUNDER IS ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS 
 * ANY OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, 
 * OR MODIFICATIONS. 
 *
 * $Id: XMEP510M.nc,v 1.2 2005/02/03 09:12:07 pipeng Exp $
 */

/******************************************************************************
 *    -Tests the MEP500 Mica2Dot Sensor Board
 *     Reads thermistor and humidity sensor  readings
 *     Sensirion SHT15 use ADC7, So DISABLE JTAG fuse before measuring
 *-----------------------------------------------------------------------------
 * Output results through mica2dot uart and radio. 
 * Use Xlisten.exe program to view data from either port:
 *  uart: mount mica2dot on mib510 with Mep500
 *        connect serial cable to PC
 *        run xlisten.exe at 19200 baud
 *  radio: run mica2dot with Mep500, 
 *         run mica2 with TOSBASE
 *         run xlisten.exe at 56K baud
 *-----------------------------------------------------------------------------
 * Data packet structure  :
 *  msg->data[0] : sensor id, MEP500 = 0x3
 *  msg->data[1] : packet id
 *  msg->data[2] : node id
 *  msg->data[3] : reserved
 *  msg->data[4,5] : thermistor adc data
 *  msg->data[6,7] : humidity adc data
 *
 *****************************************************************************/

#include "appFeatures.h"
includes XCommand;

module XMEP510M {
  provides {
    interface StdControl;
  }
  uses {
	interface Leds;
	interface Send;
	interface RouteControl;
	interface XCommand;

    interface Timer;

    interface ADC as ADCBATT;
    interface ADCControl;

    interface SplitControl as HumControl;
	interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;


#if FEATURE_UART_SEND
	interface SendMsg as SendUART;
	command result_t PowerMgrEnable();
	command result_t PowerMgrDisable();
#endif
  }
}

implementation {

  enum { STATE_START, 
         STATE_VREF, 
	 STATE_THERMISTOR, 
	 STATE_HUMIDITY, 
	 STATE_TEMPERATURE };
  #define MSG_LEN  29 

   TOS_Msg msg_buf;
   TOS_MsgPtr msg_ptr;
   XDataMsg *pack;

   bool sending_packet;
   bool bIsUart;
   uint8_t state;
   uint32_t   timer_rate;  
   bool       sleeping;	       // application command state
   uint16_t     seqno;


  static void initialize() 
    {
      atomic 
      {
    	  sleeping = FALSE;
    	  sending_packet = FALSE;
    	  timer_rate = XSENSOR_SAMPLE_RATE;
          seqno=0;
      }
    }
/****************************************************************************
 * Task to xmit radio message
 *
 ****************************************************************************/
   task void send_radio_msg(){
    uint16_t  len;
	XDataMsg *data;
    uint8_t i;
    if(sending_packet) return; 
    seqno ++;
    atomic sending_packet=TRUE;  

    data = (XDataMsg*)call Send.getBuffer(msg_ptr, &len);

	for (i=0; i<= sizeof(XDataMsg)-1; i++)
		((uint8_t*) data)[i] = ((uint8_t*)pack)[i];
    data->xMeshHeader.board_id = SENSOR_BOARD_ID;
    data->xMeshHeader.packet_id = 12;     
    data->xMeshHeader.node_id = TOS_LOCAL_ADDRESS;
    data->xMeshHeader.parent    = call RouteControl.getParent();
    data->xData.seq_no=seqno;
    #if FEATURE_UART_SEND
    	if (TOS_LOCAL_ADDRESS != 0) {
    		call Leds.yellowOn();
    	    call PowerMgrDisable();
    	    TOSH_uwait(1000);
    	    if (call SendUART.send(TOS_UART_ADDR, sizeof(XDataMsg),msg_ptr) != SUCCESS) 
    	    {
        		atomic sending_packet = FALSE;
        		call Leds.greenToggle();
        		call PowerMgrEnable();
    	    }
    	} 
    	else 
    #endif
    	{
    	    // Send the RF packet!
    	    if (call Send.send(msg_ptr, sizeof(XDataMsg)) != SUCCESS) {
        		atomic sending_packet = FALSE;
    		    call Leds.yellowOn();
        		call Leds.greenOff();
    	    }
    	}
    return;
  }


/****************************************************************************
 * Initialize this and all low level components used in this application.
 * 
 * @return returns <code>SUCCESS</code> or <code>FAIL</code>
 ****************************************************************************/
  command result_t StdControl.init() {
    atomic{
        msg_ptr = &msg_buf;
    };
    
    atomic sending_packet = TRUE;

    call Leds.init();
    atomic sending_packet = FALSE;

    MAKE_THERM_OUTPUT();             //enable thermistor power pin as output
    CLEAR_THERM_POWER();	     //and turn off

    MAKE_BAT_MONITOR_OUTPUT();       //enable voltage ref power pin as output
    CLEAR_BAT_MONITOR();	     //and turn off

    call ADCControl.init();
    call HumControl.init();
    atomic state = STATE_START;
    
    call Leds.greenOff(); 
    call Leds.yellowOff(); 
    call Leds.redOff(); 
    initialize();
   	return SUCCESS;

  }

/**
 * Start this component.
 * 
 * @return returns <code>SUCCESS</code>
 */
  command result_t StdControl.start(){
  	call HumidityError.enable();
    call TemperatureError.enable();
	call Timer.start(TIMER_REPEAT, timer_rate);

    return SUCCESS;	
  }
/**
 * Stop this component.
 * 
 * @return returns <code>SUCCESS</code>
 */
  command result_t StdControl.stop() {

    call HumControl.stop();
    return SUCCESS;    
  }

/*********************************************
event handlers
*********************************************/

/***********************************************/  
  event result_t HumControl.initDone() {
    return SUCCESS;
  }
  
/***********************************************/  
  event result_t HumControl.stopDone() {
    return SUCCESS;
  }
  
/***********************************************/  
  event result_t Timer.fired() {
   // sample
      uint8_t l_state;
      atomic l_state = state;
          
      switch(l_state) {
          case STATE_START:
	      
	      atomic state = STATE_VREF;

	      CLEAR_THERM_POWER();              //turn off thermistor power
	      SET_BAT_MONITOR();                //turn on voltage ref power
	      TOSH_uwait(255);
	      call ADCBATT.getData();           //get vref data;
	      break;
	      
	  default:
	      break;
	      
      }
      return SUCCESS;
  }

 /**********************************************
 * Battery Ref
 ***********************************************/

  async event result_t ADCBATT.dataReady(uint16_t data) {
      if(state == STATE_VREF) {
          pack->xData.vref = (data >> 1) & 0xff;
	  CLEAR_BAT_MONITOR();              //turn off power to voltage ref     
	  SET_THERM_POWER();                //turn on thermistor power
	  TOSH_uwait(255);	  

	  atomic state = STATE_THERMISTOR;
	  call ADCBATT.getData();           //get thermistor data;

      } else {
          pack->xData.thermistor = data;
	  CLEAR_BAT_MONITOR();              //turn off power to voltage ref     
	  CLEAR_THERM_POWER();              //turn off thermistor power
	  TOSH_uwait(100);	  

	  call HumControl.start();    
      }

      return SUCCESS;
  }

/*****************************************************************/


/***********************************************/  
  event result_t HumControl.startDone() {
  	atomic state = STATE_HUMIDITY;   
    call Humidity.getData();
    return SUCCESS;
  }


  event result_t HumidityError.error(uint8_t token)
  {
    pack->xData.humidity = 0xffff;
	atomic state = STATE_TEMPERATURE;   
    call Temperature.getData();
    return SUCCESS;
  }
  
  async event result_t Humidity.dataReady(uint16_t data)
  {
	pack->xData.humidity = data;
    atomic state = STATE_TEMPERATURE;   
    call Temperature.getData();
    return SUCCESS;
  }

  event result_t TemperatureError.error(uint8_t token)
  {
 	pack->xData.humtemp = 0xffff;
	post send_radio_msg();
	atomic state = STATE_START;  
    return SUCCESS;
  }

  async event result_t Temperature.dataReady(uint16_t data)
  {	
	pack->xData.humtemp = data;
    call HumControl.stop();
    post send_radio_msg();
    atomic state = STATE_START;            
    return SUCCESS;
  }

#if FEATURE_UART_SEND
 /**
  * Handle completion of sent UART packet.
  *
  * @author    Martin Turon
  * @version   2004/7/21      mturon       Initial revision
  */
  event result_t SendUART.sendDone(TOS_MsgPtr msg, result_t success) 
  {
      //      if (msg->addr == TOS_UART_ADDR) {
      atomic msg_ptr = msg;
      msg_ptr->addr = TOS_BCAST_ADDR;
      
      if (call Send.send(msg_ptr, sizeof(XDataMsg)) != SUCCESS) {
	  atomic sending_packet = FALSE;
	  call Leds.yellowOff();
      }
      
      if (TOS_LOCAL_ADDRESS != 0) // never turn on power mgr for base
	  call PowerMgrEnable();
      
      //}
      return SUCCESS;
  }
#endif

 /**
  * Handle completion of sent RF packet.
  *
  * @author    Martin Turon
  * @version   2004/5/27      mturon       Initial revision
  */
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) 
  {
      atomic {
	  msg_ptr = msg;
	  sending_packet = FALSE;
      }
      call Leds.yellowOff();
      
#if FEATURE_UART_SEND
      if (TOS_LOCAL_ADDRESS != 0) // never turn on power mgr for base
	  call PowerMgrEnable();
#endif
      
      return SUCCESS;
  }

 /** 
  * Handles all broadcast command messages sent over network. 
  *
  * NOTE: Bcast messages will not be received if seq_no is not properly
  *       set in first two bytes of data payload.  Also, payload is 
  *       the remaining data after the required seq_no.
  *
  * @version   2004/10/5   mturon     Initial version
  */
  event result_t XCommand.received(XCommandOp *opcode) {

      switch (opcode->cmd) {
	  case XCOMMAND_SET_RATE:
	      // Change the data collection rate.
	      timer_rate = opcode->param.newrate;
	      call Timer.stop();
	      call Timer.start(TIMER_REPEAT, timer_rate);
	      break;
	      
	  case XCOMMAND_SLEEP:
	      // Stop collecting data, and go to sleep.
	      sleeping = TRUE;
	      call Timer.stop();
	      call Leds.set(0);
              break;
	      
	  case XCOMMAND_WAKEUP:
	      // Wake up from sleep state.
	      if (sleeping) {
		  initialize();
		  call Timer.start(TIMER_REPEAT, timer_rate);
		  sleeping = FALSE;
	      }
	      break;
	      
	  case XCOMMAND_RESET:
	      // Reset the mote now.
	      break;

	  case XCOMMAND_ACTUATE: 
	      break;	      

	  default:
	      break;
      }    
      
      return SUCCESS;
  }


}

