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
 * $Id: XSensorMTS300M.nc,v 1.3 2005/01/27 06:48:58 husq Exp $
 */

/******************************************************************************
 *
 *****************************************************************************/
#include "appFeatures.h"
includes sensorboard;
module XSensorMTS300M {
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
	
// Mic
	interface StdControl as MicControl;
	interface Mic;
	interface ADC as MicADC;
	
// Sounder
	interface StdControl as Sounder;
	
// Accel   
	interface StdControl as AccelControl;
	interface ADC as AccelX;
	interface ADC as AccelY;
	
// Mag
	interface StdControl as MagControl;
	interface ADC as MagX;
	interface ADC as MagY;
	
	interface Timer;
	interface Leds;
    }
}

implementation {
    
  enum { START, BUSY, SERIALID_DONE,SOUND_DONE};
    
  TOS_Msg msg_buf_uart;
  TOS_MsgPtr msg_uart;
    
  char main_state;
  bool sound_state, sending_packet, IsUART;
        
  XDataMsg *pack;
	
/****************************************************************************
 * Task to uart as message
 ****************************************************************************/
  task void send_msg(){
    
    if (sending_packet) return;
    atomic sending_packet = TRUE;
    
    call Leds.yellowToggle();
    if (IsUART) call Send.send(TOS_UART_ADDR,sizeof(XDataMsg),msg_uart);
    else call Send.send(TOS_BCAST_ADDR,sizeof(XDataMsg),msg_uart);
    return;
  }
    
/****************************************************************************
 * Initialize the component. 
 ****************************************************************************/
  command result_t StdControl.init() {
      
      atomic {
	  msg_uart = &msg_buf_uart;
      }

      call BattControl.init();    
      call Leds.init();
      call CommControl.init();
      call TempControl.init();
      call MicControl.init();
      call Mic.gainAdjust(64);  // Set the gain of the microphone. 
      
#if FEATURE_SOUNDER
      call Sounder.init();
#endif
      atomic {
	  main_state = START;
  	  sound_state = TRUE;
	  sending_packet = FALSE;
	  pack = (XDataMsg *)msg_uart->data;
      }
      
#ifdef MTS310
      call AccelControl.init();
      call MagControl.init();
#endif
      
      return SUCCESS;
      
  }
 /****************************************************************************
 * Start the component. Start the clock.
 ****************************************************************************/
  command result_t StdControl.start()
  {
      call Leds.redOn();
  	
#ifdef MTS310
      call AccelControl.start();
      call MagControl.start();
#endif
      call CommControl.start();
      call Timer.start(TIMER_REPEAT, 1000);
      pack->xSensorHeader.board_id = SENSOR_BOARD_ID;
      pack->xSensorHeader.node_id = TOS_LOCAL_ADDRESS;
      pack->xSensorHeader.rsvd = 0;
      IsUART = TRUE;
      
      call Leds.greenOn();

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
#ifdef MTS310
      call AccelControl.stop();
      call MagControl.stop();
#endif 
      call CommControl.stop();
       return SUCCESS;    
  }
/****************************************************************************
 * Measure Temp, Light, Mic, toggle sounder  
 ****************************************************************************/
  event result_t Timer.fired() {
      char l_state;
       
      call Leds.redToggle();
      
      atomic l_state = main_state;
      
      if (sending_packet) 
	  return SUCCESS;                //don't overrun buffers

      switch (l_state) {
      case SOUND_DONE:
	atomic main_state = START;
	
      case START:
	atomic main_state = BUSY; 
	pack->xSensorHeader.packet_id = 1;      
	call BattControl.start(); 
	call ADCBATT.getData();     //get sensor data;
	break;
		
      case BUSY:
      default:
	      break;
      }

      return SUCCESS;
  }
  
/****************************************************************************
 * Battery Ref ADC data ready 
 * Issue a command to sample the Temperature ADC data. 
 ****************************************************************************/
  async event result_t ADCBATT.dataReady(uint16_t data) {
    
    pack->xData.datap1.vref = data;
    call BattControl.stop(); 
    call Temperature.getData(); 
    return SUCCESS;
  }
  
    
/****************************************************************************
 * Temperature ADC data ready 
 * Issue a command to sample the Photocell ADC data. 
 ****************************************************************************/ 
  async event result_t Temperature.dataReady(uint16_t data) {
    
    pack->xData.datap1.thermistor = data;	
    call TempControl.stop();  
    call PhotoControl.start(); 
    call Light.getData(); 
    return SUCCESS;
  }

  
/****************************************************************************
 * Photocell ADC data ready 
 * Issue a command to sample the MicroPhone ADC data. 
 ****************************************************************************/ 
  async event result_t Light.dataReady(uint16_t data) {
       pack->xData.datap1.light = data;
              
       call PhotoControl.stop(); 
       call TempControl.start(); 
       call MicADC.getData(); 

       return SUCCESS;
  }

/****************************************************************************
 * MicroPhone ADC data ready 
 *****************************************************************************/   
 async event result_t MicADC.dataReady(uint16_t data) {
      bool local_sound_state;
      pack->xData.datap1.mic = data;            
#ifdef MTS310
      call AccelX.getData();
#else      
      // This is the final sensor reading for the MTS300...

      if (!sending_packet)
	  post send_msg();
      atomic main_state = START;

#if FEATURE_SOUNDER
	atomic local_sound_state = sound_state;
	if (local_sound_state) 
	  call Sounder.start();
	else 
	  call Sounder.stop();
	atomic {
	  sound_state = SOUND_STATE_CHANGE;
	  atomic main_state = SOUND_DONE;
      }
#endif
#endif
      return SUCCESS;
  } 
  
 
/****************************************************************************
 *  ADC data ready 
 *  Issue a command to sample the accelerometer's Y axis. 
 ****************************************************************************/
  async event result_t AccelX.dataReady(uint16_t data) {

      pack->xData.datap1.accelX = data;
       
      call AccelY.getData();   
      return SUCCESS;
  }

/****************************************************************************
 *  ADC data ready 
 *  Issue a command to sample the magnetometer's X axis. 
 *  (Magnetometer A pin) 
 ****************************************************************************/
  async event result_t AccelY.dataReady(uint16_t data) {

      pack->xData.datap1.accelY = data;
      call MagX.getData();
      return SUCCESS;
  }

 /**
  * ADC data ready 
  * Issue a command to sample the magnetometer's Y axis. 
  * (Magnetometer B pin)
  */
  async event result_t MagX.dataReady(uint16_t data){

      pack->xData.datap1.magX = data;
      call  MagY.getData(); //get data for MagnetometerB
      return SUCCESS;  
  }

 /**
  * ADC data ready 
  * Issue a task to send uart packet.
  */
  async event result_t MagY.dataReady(uint16_t data){
    bool local_sound_state;
    pack->xData.datap1.magY = data;

    if (!sending_packet)
      post send_msg();
       	atomic main_state = START;      
	
#if FEATURE_SOUNDER
    atomic local_sound_state = sound_state;
    if (local_sound_state) call Sounder.start();
    else call Sounder.stop();
    atomic {
      sound_state = SOUND_STATE_CHANGE;
      atomic main_state = SOUND_DONE;
    }
#endif
    return SUCCESS;  
  }


  
  
/****************************************************************************
 * if Uart msg xmitted,Xmit same msg over radio
 * if Radio msg xmitted, issue a new round measuring
 ****************************************************************************/
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
      //atomic msg_uart = msg;
      atomic {
      	msg_uart = msg;
	sending_packet = FALSE;
      }
      if(IsUART){
	IsUART = FALSE;
	post send_msg();      
      }
      else{
    	IsUART = TRUE;
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

