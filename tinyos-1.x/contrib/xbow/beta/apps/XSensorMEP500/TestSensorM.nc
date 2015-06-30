/**
 * An application to send readings from the MEP401 environmental package
 * over a multihop mesh network.
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.
 *
 *   @author    Hu SiQuan, Martin Turon 
 * 
 * $Id: TestSensorM.nc,v 1.8 2004/08/16 21:12:47 ammbot Exp $
 */

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
 */

/******************************************************************************
 *  - Tests the Mep401 Mica2 Sensor Board
 *  - Read Accel, Light, Pressure, Temperature,
 *    and Humidity (Internal and External) sensor readings
 *-----------------------------------------------------------------------------
 * Output results through mica2 uart and radio. 
 * Use Xlisten.exe program to view data from either port:
 *  uart: mount mica2 on mib510 with Mep401
 *        connect serial cable to PC
 *        run xlisten.exe at 56K baud
 *  radio: run mica2 with Mep401, 
 *         run mica2 with TOSBASE
 *         run xlisten.exe at 56K baud
 *-----------------------------------------------------------------------------
 * Data packet structure  :   see sensorboardApp.h
 *****************************************************************************/

#include "appFeatures.h"

includes sensorboard;

module TestSensorM {
  provides {
    interface StdControl;
  }

  uses { 
    interface Timer;
    interface Leds;

// RF Mesh Networking
    interface Send;
    interface RouteControl;

    interface ADC as ADCBATT;
    interface ADCControl;

    interface SplitControl as HumControl;
    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;
  }
}

implementation {

  enum { STATE_START, 
         STATE_VREF, 
	 STATE_THERMISTOR, 
	 STATE_HUMIDITY, 
	 STATE_TEMPERATURE };

   TOS_Msg     msg_buf_radio;
   TOS_MsgPtr  msg_radio;

   uint8_t     doleds;
   bool        sending_packet;
   uint8_t     state;

   norace XDataMsg   readings;
   char count;

/****************************************************************************
 * Task to xmit radio message
 ****************************************************************************/
    task void send_radio_msg(){
	uint16_t  len;
	uint8_t   i;
	XDataMsg *data;
	
        // Fill the given data buffer.	    
	data = (XDataMsg*)call Send.getBuffer(msg_radio, &len);
	    
        for (i = 0; i <= sizeof(XDataMsg)-1; i++) 
	    ((uint8_t*)data)[i] = 
		((uint8_t*)&readings)[i];
	
	data->board_id  = SENSOR_BOARD_ID;
	data->packet_id = 1;    
	data->node_id   = TOS_LOCAL_ADDRESS;
	data->parent    = call RouteControl.getParent();

        IFLEDSON(call Leds.redOn());

	// Send the RF packet!
	if (call Send.send(msg_radio, sizeof(XDataMsg) /* len */) != SUCCESS) {
	    atomic sending_packet = FALSE;
	    call Leds.redOff();
	}
   }

/****************************************************************************
 * Initialize this and all low level components used in this application.
 * 
 * @return returns <code>SUCCESS</code> or <code>FAIL</code>
 ****************************************************************************/
  command result_t StdControl.init() {
    atomic {
	sending_packet = FALSE;
     	msg_radio = &msg_buf_radio;
	state = STATE_START;
	doleds = DOLEDSN;
    };

    MAKE_THERM_OUTPUT();             //enable thermistor power pin as output
    CLEAR_THERM_POWER();	     //and turn off

    MAKE_BAT_MONITOR_OUTPUT();       //enable voltage ref power pin as output
    CLEAR_BAT_MONITOR();	     //and turn off

    call ADCControl.init();
    call HumControl.init();
    call Leds.init();

    return SUCCESS;
  }

/**
 * Start this component.
 * 
 * @return returns <code>SUCCESS</code>
 */
  command result_t StdControl.start(){
    IFLEDSON(call Leds.redOn());
    call HumidityError.enable();
    call Timer.start(TIMER_REPEAT, XSENSOR_SAMPLE_RATE);
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
      uint8_t l_state;
      atomic l_state = state;

      // conditional leds activity
      IFLEDSON(call Leds.redToggle());
      IFLEDSOFF(call Leds.redOff());

      if (TOS_LOCAL_ADDRESS == 0)
	  return SUCCESS;             //no basestation sensing
          
      if (sending_packet) 
	  return SUCCESS;             //don't risk buffer overruns

      if(doleds > 0)
          doleds--;		      //enable leds for a few minutes

      switch(l_state) {
          case STATE_START:
	      readings.seq_no ++;
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
  
/***********************************************/  

 /**********************************************
 * Battery Ref
 ***********************************************/

  async event result_t ADCBATT.dataReady(uint16_t data) {
      if(state == STATE_VREF) {
          readings.vref = (data >> 1) & 0xff;
	  CLEAR_BAT_MONITOR();              //turn off power to voltage ref     
	  SET_THERM_POWER();                //turn on thermistor power
	  TOSH_uwait(255);	  

	  atomic state = STATE_THERMISTOR;
	  call ADCBATT.getData();           //get thermistor data;

      } else {
          readings.thermistor = data;
	  CLEAR_BAT_MONITOR();              //turn off power to voltage ref     
	  CLEAR_THERM_POWER();              //turn off thermistor power
	  TOSH_uwait(100);	  

	  call HumControl.start();    
      }

      return SUCCESS;
  }

/*****************************************************************/

 /**********************************************
 * External Sensirion Temperature and Humidity
 ***********************************************/

  event result_t HumControl.startDone() {
      atomic state = STATE_HUMIDITY;   
      call Humidity.getData();
      return SUCCESS;
  }

  async event result_t Humidity.dataReady(uint16_t data)
  {
      readings.humid = data;
      atomic state = STATE_TEMPERATURE;   
      call Temperature.getData();
      return SUCCESS;
  }
  
   event result_t HumidityError.error(uint8_t token)
  {
      readings.humid = 0xff;
      atomic state = STATE_TEMPERATURE;   
      call Temperature.getData();
      return SUCCESS;
  }
  
  task void stopHumidityControl()
  {
      call HumControl.stop();
  }

  async event result_t Temperature.dataReady(uint16_t data)
  {	
      // This is the final sensor reading
      readings.humtemp = data;      
      post stopHumidityControl();

      atomic {
	  if (!sending_packet) {
	      sending_packet = TRUE;
	      post send_radio_msg();
	  }
      }
      return SUCCESS;
  }
  
  event result_t TemperatureError.error(uint8_t token)
  {
      // This is the final sensor reading
      readings.humtemp = 0xff;            
      post stopHumidityControl();

      atomic {
	  if (!sending_packet) {
	      sending_packet = TRUE;
	      post send_radio_msg();
	  }
      }
      return SUCCESS;
  }

/*****************************************************************/

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) 
  {
      atomic {
          sending_packet = FALSE;
	  state = STATE_START;
      }
      call Leds.redOff();
      return SUCCESS;
  }
}
