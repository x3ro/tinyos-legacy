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
 * $Id: TestSensorM.nc,v 1.14 2005/01/21 07:50:46 pipeng Exp $
 */

/******************************************************************************
 *    -Tests the Mep401 Mica2 Sensor Board
 *    -Read Accel, Light, Pressure, Temperature and Humidity(Internal and External) sensor readings
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
 * Data packet structure  :
 *
 * PACKET #1 (of 2)
 * ----------------
 *  msg->data[0] : sensor id, Mep401 = 0x87
 *  msg->data[1] : packet id = 10
 *  msg->data[2] : node id
 *  msg->data[3] : reserved
 *  msg->data[4,5] : accel_x adc data
 *  msg->data[6,7] : accel_y adc data
 *  msg->data[8,9] : photo1 data 
 *  msg->data[10,11] : photo2 data  
 *  msg->data[12,13] : photo3 data 
 *  msg->data[12,13] : photo4 data 
 *  msg->data[14,15] : humidity data
 *  msg->data[16,17] : thermistor data
 *  
 * PACKET #2 (of 2)
 * ----------------
 *  msg->data[0] : sensor id, Mep401 = 0x87
 *  msg->data[1] : packet id = 11
 *  msg->data[2] : node id
 *  msg->data[3] : reserved 
 *  msg->data[4,5] : cal_word1 
 *  msg->data[6,7] : cal_word2
 *  msg->data[8,9] : cal_word3
 *  msg->data[10,11] : cal_word4
 *  msg->data[12,13] : intersematemp
 *  msg->data[14,15] : pressure
 
 * ---------------------------------------------------------------------------
 *****************************************************************************/
#include "appFeatures.h"
includes sensorboard;

module TestSensorM {
  provides {
    interface StdControl;
  }
  uses {
  
    //interface ADCControl;
    interface Timer;
    interface Leds;

//communication
	interface StdControl as CommControl;
	interface SendMsg as Send;
	interface ReceiveMsg as Receive;
    
// Battery    
    interface ADC as ADCBATT;
    interface StdControl as BattControl;

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

implementation {
	
  enum {STATE_START, STATE_VREF, STATE_ACCELX,STATE_ACCELY,
        STATE_PHOTO1,STATE_PHOTO2,STATE_PHOTO3,STATE_PHOTO4,
        STATE_HUMIDITY,STATE_THERM,STATE_INTHUMIDITY,STATE_INTTHERM,STATE_INTTHERMEND,
        STATE_CALIBRATION,STATE_PRESSURE,STATE_TEMP,};
/*
  enum { SENSOR_ID = 0, PACKET_ID, NODE_ID, RSVD};
  enum { VREF=4, ACCELX = 6, ACCELY = 8, PHOTO1=10, PHOTO2=12, 
         PHOTO3=14, PHOTO4=16, HUMIDITY=18, THERM=20,INTHUMIDITY=22, INTTHERM=24,};
  enum { CAL_WORD1 = 4, CAL_WORD2 = 6, CAL_WORD3 = 8,CAL_WORD4 = 10,
       	 TEMP = 12, PRESSURE = 14,};
 */ 
  #define MSG_LEN  29 

   TOS_Msg msg_buf;
   TOS_MsgPtr msg_ptr;
 
   bool sendPending;
   bool bIsUart;
   uint8_t state;
   
   char count;
   XDataMsg *pack;
   uint16_t calibration[4];           //intersema calibration words

/****************************************************************************
 * Task to xmit radio message
 *
 ****************************************************************************/
   task void send_radio_msg(){
    if(sendPending) return; 
    atomic sendPending=TRUE;  
    call Leds.yellowToggle(); 
    call Send.send(TOS_BCAST_ADDR,sizeof(XDataMsg),msg_ptr);
    return;
  }
/****************************************************************************
 * Task to uart as message
 *
 ****************************************************************************/
  task void send_uart_msg(){

    if(sendPending) return; 
    atomic sendPending=TRUE;  
    call Leds.yellowToggle(); 
        
    call Send.send(TOS_UART_ADDR,sizeof(XDataMsg),msg_ptr);
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
        pack=(XDataMsg*)msg_ptr->data;
    };
    
    call BattControl.init();    
    
    atomic sendPending = TRUE;
    call CommControl.init();
    call Leds.init();
    atomic sendPending = FALSE;
    
    call AccelControl.init();
    call PhotoControl.init();
    call HumControl.init();
    call IntHumControl.init();
    call IntersemaControl.init();
		
    atomic state = STATE_START;
    
    call Leds.greenOff(); 
    call Leds.yellowOff(); 
    call Leds.redOff(); 
    
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
    call BattControl.start(); 
    call IntHumidityError.enable();
    call IntTemperatureError.enable();
    call PressureError.enable();
    call IntersemaTemperatureError.enable();
    call CommControl.start();
    call Timer.start(TIMER_REPEAT, 2000);
    pack->xSensorHeader.board_id = SENSOR_BOARD_ID;
    pack->xSensorHeader.node_id = TOS_LOCAL_ADDRESS;
    pack->xSensorHeader.rsvd = 0;
    return SUCCESS;	
  }
/**
 * Stop this component.
 * 
 * @return returns <code>SUCCESS</code>
 */
  command result_t StdControl.stop() {
    call CommControl.stop();
    call BattControl.stop(); 
    call AccelControl.stop();
    call PhotoControl.stop();
    call HumControl.stop();
    call IntHumControl.stop();
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
  	int i;
    bIsUart=TRUE;
	atomic l_state = state;
  	if ( sendPending ) return SUCCESS ;      //don't overrun buffers
    // sample
    call Leds.redOn();
    switch(l_state) {
    	case STATE_START:
    	    for(i=4;i<29;i++){((uint8_t*)pack)[i]=0x0;}
    	    atomic state = STATE_VREF;	
            call ADCBATT.getData();           //get vref data;
        	break;
        case STATE_INTTHERMEND:
        	for(i=4;i<29;i++){((uint8_t*)pack)[i]=0x0;}
        	atomic state = STATE_CALIBRATION;	
        	call IntersemaControl.start();
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
      pack->xData.datax.vref = data ;
      atomic state = STATE_ACCELX;	
      call AccelControl.start();
      return SUCCESS;
  }
  
  event result_t AccelControl.startDone() {
    atomic state = STATE_ACCELX;   
    call AccelX.getData();
    return SUCCESS;
  }

  async event result_t AccelX.dataReady(uint16_t data)
  {
    pack->xData.datax.accelX=data;
    atomic state = STATE_ACCELY;   
    call Leds.redOn();
    call AccelY.getData();
    return SUCCESS;
  }
  
  async event result_t AccelY.dataReady(uint16_t data)
  {
    pack->xData.datax.accelY=data;
    call Leds.redOn();
    call AccelControl.stop();
    call PhotoControl.start();
    return SUCCESS;
  }
  
  /***********************************************/  
  event result_t PhotoControl.startDone() {
  	atomic state = STATE_PHOTO1;   
    call Photo1.getData();
    return SUCCESS;
  }
  
  /***********************************************/  
    async event result_t Photo1.dataReady(uint16_t data)
  {
    pack->xData.datax.photo1=data;
    atomic state = STATE_PHOTO2;   
    call Leds.greenOn();
    call Photo2.getData();
    return SUCCESS;
  }

  async event result_t Photo2.dataReady(uint16_t data)
  {
    pack->xData.datax.photo2=data;
    atomic state = STATE_PHOTO3;   
    call Leds.yellowOn();
    call Photo3.getData();
    return SUCCESS;
  }

  async event result_t Photo3.dataReady(uint16_t data)
  {
    pack->xData.datax.photo3=data;
    atomic state = STATE_PHOTO4;   
    call Leds.redOn();
    call Photo4.getData();
    return SUCCESS;
  }

  async event result_t Photo4.dataReady(uint16_t data)
  {
    pack->xData.datax.photo4=data;
    call Leds.yellowOff();
    call PhotoControl.stop();
    call HumControl.start();    
    return SUCCESS;
  }
  
/***********************************************/  
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
    pack->xData.datax.humidity=data;
    atomic state = STATE_THERM;   
    call Temperature.getData();
    return SUCCESS;
  }
  
   event result_t HumidityError.error(uint8_t token)
  {
    pack->xData.datax.humidity= 0xffff;
    atomic state = STATE_THERM;   
    call Temperature.getData();
    return SUCCESS;
  }
  
  async event result_t Temperature.dataReady(uint16_t data)
  {	
    pack->xData.datax.therm= data;
    atomic state = STATE_INTHUMIDITY; 
    call IntHumidity.getData();
    return SUCCESS;
  }
  
  event result_t TemperatureError.error(uint8_t token)
  {
    pack->xData.datax.therm= 0xffff;
    atomic state = STATE_INTHUMIDITY; 
    call IntHumidity.getData();
    return SUCCESS;
  }
  
  async event result_t IntHumidity.dataReady(uint16_t data)
  {
    pack->xData.datax.inthumidity = data;
    atomic state = STATE_INTTHERM;   
    call IntTemperature.getData();
    return SUCCESS;
  }
  
   event result_t IntHumidityError.error(uint8_t token)
  {
    pack->xData.datax.inthumidity = 0xffff;
    atomic state = STATE_INTTHERM;   
    call IntTemperature.getData();
    return SUCCESS;
  }
  
  async event result_t IntTemperature.dataReady(uint16_t data)
  {	
    pack->xData.datax.inttherm = data;
    call HumControl.stop();
    call IntHumControl.stop();
    pack->xSensorHeader.packet_id = 1;      // The No.1 packet for MEP401
   	post send_uart_msg();           //post uart xmit
    atomic state = STATE_INTTHERMEND;   
    return SUCCESS;
  }
  
  event result_t IntTemperatureError.error(uint8_t token)
  {
    pack->xData.datax.inttherm = 0xffff;
    call HumControl.stop();
    call IntHumControl.stop();
    pack->xSensorHeader.packet_id = 1;      // The No.1 packet for MEP401
   	post send_uart_msg();           //post uart xmit
    atomic state = STATE_INTTHERMEND;   
    return SUCCESS;
  }
  
    event result_t IntersemaControl.startDone() {
    count = 0;
    atomic state = STATE_CALIBRATION;
    call Calibration.getData();
    return SUCCESS;
  }
  
    event result_t Calibration.dataReady(char word, uint16_t value) {
    // make sure we get all the calibration bytes
    count++;
    calibration[word-1] = value;

    if (count == 4) {
    	pack->xData.dataw.word1 = calibration[0];
    	pack->xData.dataw.word2 = calibration[1];
    	pack->xData.dataw.word3 = calibration[2];
    	pack->xData.dataw.word4 = calibration[3];

	    atomic state = STATE_PRESSURE;
        call Pressure.getData();
    }
    return SUCCESS;
  }

  event result_t PressureError.error(uint8_t token) {
    pack->xData.dataw.pressure=0xffff;
	atomic state = STATE_TEMP;
    call IntersemaTemperature.getData();
    return SUCCESS;
  }
  
  async event result_t Pressure.dataReady(uint16_t data)
  {
    pack->xData.dataw.pressure=data;
    call Leds.greenOn();
	atomic state = STATE_TEMP;
    call IntersemaTemperature.getData();
    return SUCCESS;
  }


  task void stopPressureControl()
  {
    //atomic sensor_state = SENSOR_PRESSURE_STOP;
    call IntersemaControl.stop();
    return;
  }
 
  event result_t IntersemaTemperatureError.error(uint8_t token)
  {
    pack->xData.dataw.intersematemp=0xffff;
	//call IntersemaControl.stop();
	post stopPressureControl();
    call Leds.greenOn();
	atomic state = STATE_START;
	pack->xSensorHeader.packet_id = 2;      // The No.2 packet for MEP401
   	post send_uart_msg();                                  //post uart xmit
	atomic state = STATE_START;
    return SUCCESS;
  }
  
  

  async event result_t IntersemaTemperature.dataReady(uint16_t data)
  {
    pack->xData.dataw.intersematemp=data;
	//call IntersemaControl.stop();
	post stopPressureControl();
    call Leds.greenOn();
	atomic state = STATE_START;
	pack->xSensorHeader.packet_id = 2;      // The No.2 packet for MEP401
   	post send_uart_msg();           // post uart xmit
	atomic state = STATE_START;
    return SUCCESS;
  }

/****************************************************************************
 * if Uart msg xmitted,Xmit same msg over radio
 * if Radio msg xmitted, issue a new round measuring
 ****************************************************************************/
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
      //atomic msg_uart = msg;

      atomic msg_ptr = msg;
	  sendPending = FALSE;
      if(bIsUart)
      {
        bIsUart=!bIsUart;
        post send_radio_msg();
      }
      call Leds.redOff();
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

