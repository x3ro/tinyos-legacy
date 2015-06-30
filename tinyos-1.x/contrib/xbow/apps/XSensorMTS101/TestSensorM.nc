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
 * $Id: TestSensorM.nc,v 1.7 2004/12/22 06:09:08 pipeng Exp $
 */

/******************************************************************************
 *
 *****************************************************************************/
#include "appFeatures.h"
includes sensorboard;
module TestSensorM {
  provides {
    interface StdControl;
  }
  uses {
  
//communication
	interface StdControl as CommControl;
	interface SendMsg as Send;
	interface ReceiveMsg as Receive;

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
    interface Leds;
  }
}

implementation {
	
  enum { START, BUSY, BATT_DONE, TEMP_DONE, LIGHT_DONE};

  #define MSG_LEN  29 

   TOS_Msg msg_buf;
   TOS_MsgPtr msg_ptr;

   bool sending_packet;
   bool bIsUart;
   uint8_t state;
   XDataMsg *pack; 

/****************************************************************************
 * Task to xmit radio message
 *
 ****************************************************************************/
   task void send_radio_msg(){
    if(sending_packet) return; 
    atomic sending_packet=TRUE;  
    call Send.send(TOS_BCAST_ADDR,sizeof(XDataMsg),msg_ptr);
    return;
  }
/****************************************************************************
 * Task to uart as message
 *
 ****************************************************************************/
   task void send_uart_msg(){
    if(sending_packet) return;    
    atomic sending_packet=TRUE;
    call Leds.yellowToggle();
    call Send.send(TOS_UART_ADDR,sizeof(XDataMsg),msg_ptr);
    return;
  }

 /****************************************************************************
 * Initialize the component. Initialize ADCControl, Leds
 *
 ****************************************************************************/
  command result_t StdControl.init() {
  	
  	atomic {
    msg_ptr = &msg_buf;
    pack=(XDataMsg *)msg_ptr->data;
    }
// usart1 is also connected to external serial flash
// set usart1 lines to correct state
    TOSH_MAKE_FLASH_OUT_OUTPUT();             //tx output
    TOSH_MAKE_FLASH_CLK_OUTPUT();             //usart clk
    sending_packet=FALSE;   
    call BattControl.init();
    call Leds.init();
	call CommControl.init();
    call TempControl.init();
    call PhotoControl.init();
    
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
    call CommControl.start();
	call Timer.start(TIMER_REPEAT, 2000);
    pack->xSensorHeader.board_id = SENSOR_BOARD_ID;
    pack->xSensorHeader.packet_id = 1;     // Only one packet for MDA500
    pack->xSensorHeader.node_id = TOS_LOCAL_ADDRESS;
    pack->xSensorHeader.rsvd = 0;
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
    call CommControl.stop();
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
    bIsUart=TRUE;
	
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
      pack->xData.datap1.vref = data ;
      atomic state = BATT_DONE;
      return SUCCESS;
  }
    
/****************************************************************************
 * Temperature ADC data ready 
 * Read and get next channel.
 * Send data packet
 ****************************************************************************/ 
  async event result_t Temperature.dataReady(uint16_t data) {
       pack->xData.datap1.thermistor = data ;
       
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
       pack->xData.datap1.photo = data ;
              
       atomic state = LIGHT_DONE;   
       post send_uart_msg();
//       TOSH_uwait(100);  
       
       return SUCCESS;
  }
/****************************************************************************
 * if Uart msg xmitted,Xmit same msg over radio
 * if Radio msg xmitted, issue a new round measuring
 ****************************************************************************/
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
      //atomic msg_uart = msg;

      
	  sending_packet = FALSE;
      //if message have sent by UART, send the message once again by radio.
      if(bIsUart)
      { 
        bIsUart=!bIsUart;  
        post send_radio_msg();
      }
      else
      {
        atomic msg_ptr = msg;
      }
      return SUCCESS;
  }

/****************************************************************************
 * Uart msg rcvd. 
 * This app doesn't respond to any incoming uart msg
 * Just return
 ****************************************************************************/
  event TOS_MsgPtr Receive.receive(TOS_MsgPtr data) {
      return data;
  }
}

