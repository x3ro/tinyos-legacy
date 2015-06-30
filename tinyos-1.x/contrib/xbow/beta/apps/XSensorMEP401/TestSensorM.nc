/**
 * An application to send readings from the MEP401 environmental package
 * over a multihop mesh network.
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.
 *
 *   @author    Hu SiQuan, Martin Turon 
 * 
 * $Id: TestSensorM.nc,v 1.14 2004/08/16 22:23:19 mturon Exp $
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

module TestSensorM
{
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

    interface SplitControl as AccelControl;
    interface ADC as AccelX;
    interface ADC as AccelY;
    
    interface SplitControl as PhotoControl;
    interface ADC as Photo1;
    interface ADC as Photo2;
    interface ADC as Photo3;
    interface ADC as Photo4;
    
    interface SplitControl as HumControl;
    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;

    interface SplitControl as IntHumControl;
    interface ADC as IntHumidity;
    interface ADC as IntTemperature;
    interface ADCError as IntHumidityError;
    interface ADCError as IntTemperatureError;
    
    interface SplitControl as IntersemaControl;
    interface ADC as Pressure;
    interface ADC as IntersemaTemperature;
    interface ADCError as PressureError;
    interface ADCError as IntersemaTemperatureError;
    interface Calibration;
  }
}

implementation
{
  enum { STATE_START,
	 STATE_VREF, 
	 STATE_ACCELX, 
	 STATE_ACCELY,
	 STATE_PHOTO1, 
	 STATE_PHOTO2, 
	 STATE_PHOTO3, 
	 STATE_PHOTO4,
	 STATE_HUMIDITY, 
	 STATE_TEMPERATURE, 
	 STATE_INTHUMIDITY, 
	 STATE_INTTEMPERATURE,
	 STATE_CALIBRATION, 
	 STATE_PRESSURE, 
	 STATE_PRESSURE_TEMP,};

  TOS_Msg     msg_buf_radio;
  TOS_MsgPtr  msg_radio;
  uint16_t    msg_len;

  uint8_t     doleds;
  bool        sending_packet;
  uint8_t     state;

  norace XDataMsg   readings;
  char count;

/****************************************************************************
 * Task to xmit radio message
 ****************************************************************************/
  task void send_radio_msg(){
      uint8_t   i;
      XDataMsg *data;

      // Fill the given data buffer.	    
      data = (XDataMsg*)call Send.getBuffer(msg_radio, &msg_len);
    
      for (i = 0; i <= sizeof(XDataMsg)-1; i++) 
          ((uint8_t*)data)[i] =
	      ((uint8_t*)&readings)[i];
	
      data->board_id  = SENSOR_BOARD_ID;
      data->node_id   = TOS_LOCAL_ADDRESS;
      data->parent    = call RouteControl.getParent();
      data->packet_id = 1;    

      if (doleds) 
	  call Leds.yellowOn();

      // Send the RF packet!
      if (call Send.send(msg_radio, sizeof(XDataMsg) /* msg_len */) != SUCCESS) {
          atomic sending_packet = FALSE;
	  call Leds.yellowOff();
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
    
    MAKE_BAT_MONITOR_OUTPUT();  // enable voltage ref power pin as output
    MAKE_ADC_INPUT();           // enable ADC7 as input
    
    // usart1 is also connected to external serial flash
    // set usart1 lines to correct state
    TOSH_MAKE_FLASH_OUT_OUTPUT();             //tx output
    TOSH_MAKE_FLASH_CLK_OUTPUT();             //usart clk
    
    call HumControl.init();
    call IntHumControl.init();
    call AccelControl.init();
    call PhotoControl.init();
    call IntersemaControl.init();
    call Leds.init();

    return SUCCESS;
  }

/**
 * Start this component.
 * 
 * @return returns <code>SUCCESS</code>
 */
  command result_t StdControl.start(){
    call Leds.greenOn();
    call HumidityError.enable();
    call TemperatureError.enable();
    call IntHumidityError.enable();
    call IntTemperatureError.enable();
    call PressureError.enable();
    call IntersemaTemperatureError.enable();
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
    call IntHumControl.stop();
    call AccelControl.stop();
    call PhotoControl.stop();
    call IntersemaControl.stop();
    return SUCCESS;    
  }

/*********************************************
	     event handlers
*********************************************/

/***********************************************/  
  event result_t AccelControl.initDone() {
    return SUCCESS;
  }
  
/***********************************************/  
  event result_t AccelControl.stopDone() {
    return SUCCESS;
  }
  
/***********************************************/  
  event result_t PhotoControl.initDone() {
    return SUCCESS;
  }
  
/***********************************************/  
  event result_t PhotoControl.stopDone() {
    return SUCCESS;
  }
  
/***********************************************/  
  event result_t HumControl.initDone() {
    return SUCCESS;
  }
  
/***********************************************/  
  event result_t HumControl.stopDone() {
    return SUCCESS;
  }
  
/***********************************************/  
  event result_t IntHumControl.initDone() {
    return SUCCESS;
  }
  
/***********************************************/  
  event result_t IntHumControl.stopDone() {
    return SUCCESS;
  }
  
/***********************************************/  
  event result_t IntersemaControl.initDone() {
    return SUCCESS;
  }
  
/***********************************************/  
  event result_t IntersemaControl.stopDone() {
    return SUCCESS;
  }
  
/***********************************************/  

  event result_t Timer.fired() {
      uint8_t l_state;
      atomic l_state = state;

      // conditional leds activity
      if(doleds > 0) {
          doleds--;		      //enable leds for a few minutes
	  call Leds.redToggle();
      } else {
	  call Leds.redOff();
	  call Leds.greenOff();
	  call Leds.yellowOff();  
      }

      if (TOS_LOCAL_ADDRESS == 0) {
	  doleds = 1;
	  return SUCCESS;             //no basestation sensing
      }

      if (sending_packet) 
	  return SUCCESS;             //don't risk buffer overruns

      // state machine
      switch(l_state) {
	  case STATE_START:
	      readings.seq_no ++;
	      atomic state = STATE_VREF;	
	      SET_BAT_MONITOR();                //turn on voltage ref power
	      TOSH_uwait(100);                  //allow time to turn on
	      call ADCBATT.getData();           //get vref data;
	      break;
	      
	  default:
	      break;
      }
      return SUCCESS;
  }
  
/*****************************************************************/

 /**********************************************
 * Battery Ref
 ***********************************************/

  async event result_t ADCBATT.dataReady(uint16_t data) {
      readings.vref = (data >> 1) & 0xff;
      call HumControl.start();    
      return SUCCESS;
  }

/*****************************************************************/

 /**********************************************
 * External and Internal Sensirion Temperature and Humidity
 ***********************************************/

  event result_t HumControl.startDone() {
      atomic state = STATE_HUMIDITY;   
      call IntHumControl.start();    
      return SUCCESS;
  }

  event result_t IntHumControl.startDone() {
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
  
  async event result_t Temperature.dataReady(uint16_t data)
  {	
      readings.humtemp = data;      
      atomic state = STATE_INTHUMIDITY; 
      call IntHumidity.getData();
      return SUCCESS;
  }
  
  event result_t TemperatureError.error(uint8_t token)
  {
      readings.humtemp = 0xff;            
      atomic state = STATE_INTHUMIDITY; 
      call IntHumidity.getData();
      return SUCCESS;
  }
  
  async event result_t IntHumidity.dataReady(uint16_t data)
  {
      readings.inthum = data;            
      atomic state = STATE_INTTEMPERATURE;   
      call IntTemperature.getData();
      return SUCCESS;
  }
  
   event result_t IntHumidityError.error(uint8_t token)
  {
      readings.inthum = 0xff;            
      atomic state = STATE_INTTEMPERATURE;   
      call IntTemperature.getData();
      return SUCCESS;
  }
  
  async event result_t IntTemperature.dataReady(uint16_t data)
  {	
      readings.inttemp = data;                  
      call HumControl.stop();
      call IntHumControl.stop();
      atomic state = STATE_ACCELX;	
      call AccelControl.start();
      return SUCCESS;
  }
 
  event result_t IntTemperatureError.error(uint8_t token)
  {
      readings.inttemp = 0xff;            
      call HumControl.stop();
      call IntHumControl.stop();
      atomic state = STATE_ACCELX;	
      call AccelControl.start();
      return SUCCESS;
  }

/*****************************************************************/

 /**********************************************
 * ADXL202 Accelerometer
 ***********************************************/
  
  event result_t AccelControl.startDone() {
      atomic state = STATE_ACCELX;   
      call AccelX.getData();
      return SUCCESS;
  }

  async event result_t AccelX.dataReady(uint16_t data)
  {
      readings.accel_x = data >> 2;
      atomic state = STATE_ACCELY;   
      call AccelY.getData();
      return SUCCESS;
  }
  
  async event result_t AccelY.dataReady(uint16_t data)
  {
      readings.accel_y = data >> 2;
      call AccelControl.stop();
      call PhotoControl.start();
      return SUCCESS;
  }
  
/*****************************************************************/

 /**********************************************
 * Four Hamamatsu Photodiodes
 ***********************************************/

  event result_t PhotoControl.startDone() {
      atomic state = STATE_PHOTO1;   
      call Photo1.getData();
      return SUCCESS;
  }
  
  async event result_t Photo1.dataReady(uint16_t data)
  {
      readings.photo[0] = data;
      atomic state = STATE_PHOTO2;   
      call Photo2.getData();
      return SUCCESS;
  }

  async event result_t Photo2.dataReady(uint16_t data)
  {
      readings.photo[1] = data;
      atomic state = STATE_PHOTO3;   
      call Photo3.getData();
      return SUCCESS;
  }

  async event result_t Photo3.dataReady(uint16_t data)
  {
      readings.photo[2] = data;
      atomic state = STATE_PHOTO4;   
      call Photo4.getData();
      return SUCCESS;
  }

  async event result_t Photo4.dataReady(uint16_t data)
  {
      readings.photo[3] = data;
      call PhotoControl.stop();
      atomic state = STATE_CALIBRATION;	
      call IntersemaControl.start();
      return SUCCESS;
  }

/*****************************************************************/

 /**********************************************
 * Intersema Calibration, Pressure, and Temperature
 ***********************************************/
  
  event result_t IntersemaControl.startDone()
  {
      count = 0;
      atomic state = STATE_CALIBRATION;
      call Calibration.getData();
      return SUCCESS;
  }
  
  event result_t Calibration.dataReady(char word, uint16_t value)
  {
      // make sure we get all the calibration bytes
      readings.presscalib[word-1] = value;
      count++;

      if (count == 4) {
          atomic state = STATE_PRESSURE;
	  call Pressure.getData();
      }

      return SUCCESS;
  }

  event result_t PressureError.error(uint8_t token) 
  {
      readings.press = 0xff;
      atomic state = STATE_PRESSURE_TEMP;
      call IntersemaTemperature.getData();
      return SUCCESS;
  }
  
  async event result_t Pressure.dataReady(uint16_t data)
  {
      readings.press = data;
      atomic state = STATE_PRESSURE_TEMP;
      call IntersemaTemperature.getData();
      return SUCCESS;
  }

  task void stopPressureControl()
  {
      call IntersemaControl.stop();
  }
 
  event result_t IntersemaTemperatureError.error(uint8_t token)
  {
      readings.presstemp = 0xff;
      post stopPressureControl();
      atomic state = STATE_START;

      // This is the final sensor reading for the MEP401...
      atomic {
	  if (!sending_packet) {
	      sending_packet = TRUE;
	      post send_radio_msg();
	  }
      }
      return SUCCESS;
  }

  async event result_t IntersemaTemperature.dataReady(uint16_t data)
  {
      readings.presstemp = data;
      post stopPressureControl();
      atomic state = STATE_START;
      
      // This is the final sensor reading for the MEP401...
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
      call Leds.yellowOff();
      return SUCCESS;
  }
}
