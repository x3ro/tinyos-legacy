/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 * $Id: XMTS101M.nc,v 1.3 2005/01/11 04:38:26 husq Exp $
 */

/******************************************************************************
 *
 *****************************************************************************/
#include "appFeatures.h"
includes XCommand;

includes sensorboard;

module XMTS101M {
  provides {
    interface StdControl;
  }
  uses {
  
	interface Leds;

	interface Send;
	interface RouteControl;
#ifdef XMESHSYNC
    interface Receive as DownTree; 	
#endif  	
	interface XCommand;

// Battery    
    interface ADC as ADCBATT;
    interface StdControl as BattControl;

//Temp
    interface StdControl as TempControl;
    interface ADC as Temperature;

//Light
    interface StdControl as PhotoControl;
    interface ADC as Light;
    
    interface Timer;


#if FEATURE_UART_SEND
	interface SendMsg as SendUART;
	command result_t PowerMgrEnable();
	command result_t PowerMgrDisable();
#endif
  }
}

implementation {
	
  enum { START, BUSY, BATT_DONE, TEMP_DONE, LIGHT_DONE};

  #define MSG_LEN  29 

   TOS_Msg msg_buf;
   TOS_MsgPtr msg_ptr;

   bool sending_packet;

   uint8_t state;
   XDataMsg pack; 
    uint32_t   timer_rate;  
    bool       sleeping;	       // application command state


  static void initialize() 
    {
      atomic 
      {
    	  sleeping = FALSE;
    	  sending_packet = FALSE;
    	  timer_rate = XSENSOR_SAMPLE_RATE;
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
    atomic sending_packet=TRUE;  

    data = (XDataMsg*)call Send.getBuffer(msg_ptr, &len);
	for (i=0; i<= sizeof(XDataMsg)-1; i++)
		((uint8_t*) data)[i] = ((uint8_t*)&pack)[i];
    data->xMeshHeader.board_id = SENSOR_BOARD_ID;
    data->xMeshHeader.packet_id = 1;     
    data->xMeshHeader.node_id = TOS_LOCAL_ADDRESS;
    data->xMeshHeader.parent    = call RouteControl.getParent();

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
 * Initialize the component. Initialize ADCControl, Leds
 *
 ****************************************************************************/
  command result_t StdControl.init() {
  	
  	atomic {
    msg_ptr = &msg_buf;
    }
// usart1 is also connected to external serial flash
// set usart1 lines to correct state
    TOSH_MAKE_FLASH_OUT_OUTPUT();             //tx output
    TOSH_MAKE_FLASH_CLK_OUTPUT();             //usart clk
    sending_packet=FALSE;   
    call BattControl.init();
    call Leds.init();
    call TempControl.init();
    call PhotoControl.init();
    initialize();
   	return SUCCESS;

  }
 /****************************************************************************
 * Start the component. Start the clock.
 *
 ****************************************************************************/
  command result_t StdControl.start(){
  		call Leds.redOn();
    call Leds.yellowOn();
    call Leds.greenOn();
  	
  	atomic state = START;
    call BattControl.start(); 
  	call PhotoControl.start(); 
  	call PhotoControl.start(); 
	call Timer.start(TIMER_REPEAT, timer_rate);

    return SUCCESS;	
  }
 /****************************************************************************
 * Stop the component.
 *
 ****************************************************************************/
  command result_t StdControl.stop() {
    call BattControl.stop(); 
  	call TempControl.stop();  
  	call PhotoControl.stop();  
    return SUCCESS;    
  }
/****************************************************************************
 * Measure Temp, Light  
 *
 ****************************************************************************/
event result_t Timer.fired() {
    uint8_t l_state;
        
	call Leds.redToggle();
    call Leds.yellowOff();
    call Leds.greenOn();
    atomic l_state = state;
	
    if ( l_state == LIGHT_DONE) {
          atomic {
          	state = START;
          	l_state = state;
    	  }
    }
    if ( l_state == START) {

    	atomic state = BUSY;
        call ADCBATT.getData();           //get sensor data;
        atomic l_state = state;
    }
    if (l_state == BATT_DONE){
    	
    	atomic state = BUSY;
        call Temperature.getData(); 
        atomic l_state = state;
       
   	}
    if (l_state == TEMP_DONE){
    	atomic state = BUSY;
	    call Light.getData(); 
	    atomic l_state = state; 
    }  
	  return SUCCESS;  
  }
  
/****************************************************************************
 * Battery Ref  or thermistor data ready 
 ****************************************************************************/
  async event result_t ADCBATT.dataReady(uint16_t data) {
      pack.xData.datap1.vref = data ;
      atomic state = BATT_DONE;
      return SUCCESS;
  }
    
/****************************************************************************
 * Temperature ADC data ready 
 * Read and get next channel.
 * Send data packet
 ****************************************************************************/ 
  async event result_t Temperature.dataReady(uint16_t data) {
       pack.xData.datap1.thermistor = data ;
       
       atomic state = TEMP_DONE; 
       TOSH_uwait(100); 
       return SUCCESS;
  }

  
/****************************************************************************
 * Photocell ADC data ready 
 * Read and get next channel.
 * Send data packet
 ****************************************************************************/ 
  async event result_t Light.dataReady(uint16_t data) {
       pack.xData.datap1.photo = data ;
              
       atomic state = LIGHT_DONE;   
       post send_radio_msg();
//       TOSH_uwait(100);  
       
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

	  case XCOMMAND_ACTUATE: {
	      state = opcode->param.actuate.state;
	      if (opcode->param.actuate.device != XCMD_DEVICE_SOUNDER) 
                break;
	      }
	      break;	      

	  default:
	      break;
      }    
      
      return SUCCESS;
  }

#ifdef XMESHSYNC  
  task void SendPing() {
    XDataMsg *pReading;
    uint16_t Len;

      
    if ((pReading = (XDataMsg *)call Send.getBuffer(msg_ptr,&Len))) {
      pReading->xMeshHeader.parent = call RouteControl.getParent();
      if ((call Send.send(msg_ptr,sizeof(XDataMsg))) != SUCCESS)
	atomic sending_packet = FALSE;
    }

  }


    event TOS_MsgPtr DownTree.receive(TOS_MsgPtr pMsg, void* payload, uint16_t payloadLen) {

        if (!sending_packet) {
	   call Leds.yellowToggle();
	   atomic sending_packet = TRUE;
           post SendPing();  //  pMsg->XXX);
        }
	return pMsg;
  }
#endif    

}

