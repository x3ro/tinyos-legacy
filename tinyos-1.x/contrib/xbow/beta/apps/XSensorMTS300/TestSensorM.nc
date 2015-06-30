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
 * $Id: TestSensorM.nc,v 1.4 2004/08/20 15:02:08 mturon Exp $
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

// RF Mesh Networking
	interface Send;
	interface RouteControl;

	interface ADC as ADCBATT;

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
	
	interface ADCControl;   
	interface Timer;
	interface Leds;
    }
}

implementation {
    
    enum { START, BUSY, SOUND_DONE};
    
#define MSG_LEN  29 
    
    TOS_Msg    gMsgBuffer;
    TOS_Msg    msg_buf_radio;
    TOS_MsgPtr msg_radio;

    norace XDataMsg   readings;
    
    char main_state;
    bool sound_state, sending_packet;
    
/****************************************************************************
 * Task to xmit radio message
 *
	    msg_radio->addr = TOS_BCAST_ADDR;
	    msg_radio->type = 0;
	    msg_radio->length = MSG_LEN;
	    msg_radio->group = TOS_AM_GROUP;
 ****************************************************************************/
    task void send_radio_msg(){
	uint8_t   i;
	uint16_t  len;
	XDataMsg *data;

        call Leds.yellowOn();
	
        // Fill the given data buffer.	    
	data = (XDataMsg*)call Send.getBuffer(msg_radio, &len);
	    
        for (i = 0; i <= sizeof(XDataMsg)-1; i++) 
	    ((uint8_t*)data)[i] = 
		((uint8_t*)&readings)[i];
	
	data->board_id  = SENSOR_BOARD_ID;
	data->packet_id = 1;    
	data->node_id   = TOS_LOCAL_ADDRESS;
	data->parent    = call RouteControl.getParent();

	// Send the RF packet!
	if (call Send.send(msg_radio, sizeof(XDataMsg)) != SUCCESS) {
	    atomic sending_packet = FALSE;
	    call Leds.yellowOff();
	}

	return;
    }

/****************************************************************************
 * Initialize the component. Initialize ADCControl, Leds
 *
 ****************************************************************************/
  command result_t StdControl.init() {
      
      atomic msg_radio = &msg_buf_radio;
      
      MAKE_BAT_MONITOR_OUTPUT();  // enable voltage ref power pin as output
      MAKE_ADC_INPUT();           // enable ADC7 as input
      
// usart1 is also connected to external serial flash
// set usart1 lines to correct state
//  TOSH_MAKE_FLASH_SELECT_OUTPUT();
      TOSH_MAKE_FLASH_OUT_OUTPUT();             //tx output
      TOSH_MAKE_FLASH_CLK_OUTPUT();             //usart clk
//  TOSH_SET_FLASH_SELECT_PIN();
      
      call ADCControl.init();
      call Leds.init();

      call TempControl.init();
      call PhotoControl.init();
      call MicControl.init();
      call Mic.gainAdjust(64);  // Set the gain of the microphone.  (refer to Mic.ti)

#if FEATURE_SOUNDER
      call Sounder.init();
#endif
      atomic {
	  main_state = START;
  	  sound_state = TRUE;
	  sending_packet = FALSE;
      }
      
#ifdef MTS310
      call AccelControl.init();
      call MagControl.init();
#endif
      
      return SUCCESS;
      
  }
 /****************************************************************************
 * Start the component. Start the clock.
 *
 ****************************************************************************/
  command result_t StdControl.start()
  {
      call Leds.greenOn();
  	
//    call TempControl.start(); 
#ifdef MTS310
      call AccelControl.start();
      call MagControl.start();
#endif

      call Leds.yellowOn();

      call Timer.start(TIMER_REPEAT, XSENSOR_SAMPLE_RATE);

      return SUCCESS;	
  }

/****************************************************************************
 * Stop the component.
 *
 ****************************************************************************/
  command result_t StdControl.stop() {
      call TempControl.stop();  
      call PhotoControl.stop(); 
#ifdef MTS310
      call AccelControl.stop();
      call MagControl.stop();
#endif 

      return SUCCESS;
  }
/****************************************************************************
 * Measure Temp, Light, Mic, toggle sounder  
 *
 ****************************************************************************/
  event result_t Timer.fired() {
      char l_state;
       
      call Leds.greenOn();
      
      atomic l_state = main_state;
      
      if (sending_packet) 
	  return SUCCESS;             //don't overrun buffers

      l_state = START;

      switch (l_state) {
	  case SOUND_DONE:
	      atomic main_state = START;

	  case START:
	      atomic main_state = BUSY;

	      SET_BAT_MONITOR();          //turn on voltage ref power
	      TOSH_uwait(1000);           //allow time to turn on
	      call ADCBATT.getData();     //get sensor data;

	      break;

	  case BUSY:
	  default:
	      break;
      }

      return SUCCESS;
  }
  
  /****************************************************************************
 * Battery Ref  or thermistor data ready 
 ****************************************************************************/
  async event result_t ADCBATT.dataReady(uint16_t data) {
      readings.vref = data;
      CLEAR_BAT_MONITOR();
      call Temperature.getData(); 
        
      return SUCCESS;
  }
  
    
/****************************************************************************
 * Temperature ADC data ready 
 * Read and get next channel.
 ****************************************************************************/ 
  async event result_t Temperature.dataReady(uint16_t data) {
      readings.thermistor = data;
      
      call TempControl.stop();  
      call PhotoControl.start(); 
      call Light.getData(); 
      
      return SUCCESS;
  }

  
/****************************************************************************
 * Photocell ADC data ready 
 * Read and get next channel.
 ****************************************************************************/ 
  async event result_t Light.dataReady(uint16_t data) {
      readings.light = data;
      
      call PhotoControl.stop(); 
      call TempControl.start(); 
      call MicADC.getData(); 
      
      return SUCCESS;
  }

/****************************************************************************
 * MicroPhone ADC data ready 
 * Read and toggle sounder.
 * send uart packet
 ****************************************************************************/   async event result_t MicADC.dataReady(uint16_t data) {
     readings.mic = data;
      
#ifdef MTS310
     call AccelX.getData();
#else      
     // This is the final sensor reading for the MTS300...
     atomic {
	 if (!sending_packet) {
	     sending_packet = TRUE;
	      post send_radio_msg();
	 }
     }
     
#if FEATURE_SOUNDER
     if (sound_state) call Sounder.start();
     else call Sounder.stop();
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
 * Read and toggle sounder.
 * send uart packet
 ****************************************************************************/
  async event result_t AccelX.dataReady(uint16_t data) {
      readings.accelX = data;

      call AccelY.getData();   
      return SUCCESS;
  }

/****************************************************************************
 *  ADC data ready 
 * Read and toggle sounder.
 * send uart packet
 ****************************************************************************/
  async event result_t AccelY.dataReady(uint16_t data) {
      readings.accelY = data;

      call MagX.getData();
      return SUCCESS;
  }

 /**
  * In response to the <code>MagX.dataReady</code> event, it stores the sample
  * and issues command to sample the magnetometer's Y axis. 
  * (Magnetometer B pin)
  *  
  * @return returns <code>SUCCESS</code>
  */
  async event result_t MagX.dataReady(uint16_t data){
      readings.magX = data;

      call  MagY.getData(); //get data for MagnetometerB
      return SUCCESS;  
  }

 /**
  * In response to the <code>MagY.dataReady</code> event, it stores the sample
  * and issues a task to filter and process the stored magnetometer data.
  *
  * It also has a schedule which starts sampling the Temperture and 
  * Accelormeter depending on the stepdown counter.
  * 
  * @return returns <code>SUCCESS</code>
  */
  async event result_t MagY.dataReady(uint16_t data){
      readings.magY = data;
	
      atomic {
	  if (!sending_packet) {
	      sending_packet = TRUE;
		post send_radio_msg();
	  }
      }
      
#if FEATURE_SOUNDER
      if (sound_state) call Sounder.start();
      else call Sounder.stop();
      atomic {
	  sound_state = SOUND_STATE_CHANGE;
	  atomic main_state = SOUND_DONE;
      }
#endif
      return SUCCESS;  
  }
  

/****************************************************************************
 * Radio msg xmitted. 
 ****************************************************************************/
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
      atomic {
	  msg_radio = msg;
	  main_state = START;
	  sending_packet = FALSE;
      }
      call Leds.yellowOff();
      call Leds.greenOff();
      
      return SUCCESS;
  }

/****************************************************************************
 * Radio msg rcvd. 
 * This app doesn't respond to any incoming radio msg
 * Just return
 ****************************************************************************/
//  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr data) {
//      return data;
//  }

}

