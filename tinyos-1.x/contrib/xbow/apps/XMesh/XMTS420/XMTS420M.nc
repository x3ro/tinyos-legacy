/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
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
 * 
 * 
 */
/* History:   created 1/25/2001
 *
 *  @authors Alan Broad, David M. Doolin, Hu Siquan, others
 *
 *  $Id: XMTS420M.nc,v 1.4 2005/04/05 03:09:42 husq Exp $ 
 *
 */
/******************************************************************************
 * Measures MTS400/420 weatherboard sensors & gps and converts to engineering
 * units were possible. 
 *-----------------------------------------------------------------------------
 * Output results through mesh network to BaseStation(nodeid:0)
 * Use Xlisten.exe program to view data from nodeid:0's uart port:
 *        mount mica2 with nodeid:0 on mib510 with MTS400/420
 *        Turn on other nodes to connect as a mesh netwrok
 *        connect MIB510 through serial cable to PC
 *        run xlisten.exe on PC at 57600 baud
 *-----------------------------------------------------------------------------
 * NOTES:
 * -Intersema pressure sensor control lines are shared with gps control lines
 * -Cannot enable gps rx/tx and intersema at same time
 *
 * - gps is always enabled, work for both  MTS420  and MTS400 sensor boards.
 * - if gps not present (MTS400) then additional ~2sec gps timeout will occur
 *
 * Strategy:
 * 1. Turn on gps power and leave on
 * 2. sequentially read  all weather sensors (green led on).
 *    - xmit weather sensor data
 * 3. get gps packet (red led on):
 *    - enable gps Rx,Tx lines to cpu
 *    - wait up to 1 sec to receive a packet (toggle yellow if no pkt)
 *    - xmit gps packet
 *    - disable gps Rx,Rx lines
 * 4. repeat 2,3
 * NOTE:  
 * No real power strategy; just turns sensors on sequentially, gps always on.
 * Need I2C BusArbitration routines for better power control
 *****************************************************************************/

#define USE_GGA_STRUCT 1

// gps.h file should eventually by split into
// a leadtek9546.h for the control of the gps
// hardware unit, and an nmea.h for handling
// the data going in and out of the unit.
includes gps;
includes NMEA;
includes XCommand;
#include "appFeatures.h"

module XMTS420M {

  provides interface StdControl;

#ifdef MTS420
  provides command void load_gps_struct();
  provides command result_t parse_gga_message(GPS_MsgPtr gps_data);
#endif

  uses {

//gps
#ifdef MTS420
    interface GpsCmd;   
    interface StdControl as GpsControl;
//  interface BareSendMsg as GpsSend;
    interface ReceiveMsg as GpsReceive;
    interface NMEA as nmea;
#endif

// RF Mesh Networking	
    interface Send;	
    interface RouteControl;
#ifdef XMESHSYNC
    interface Receive as DownTree; 	
#endif      
//
	interface XCommand;

// Battery    
    interface ADC as ADCBATT;
    interface StdControl as BattControl;

//Accels
    interface StdControl as AccelControl;
    interface I2CSwitchCmds as AccelCmd;
    interface ADC as AccelX;
    interface ADC as AccelY;

//Intersema
    interface SplitControl as PressureControl;
    //interface StdControl as PressureControl;
    interface ADC as IntersemaTemp;
    interface ADC as IntersemaPressure;
    interface Calibration as IntersemaCal;
    
//Sensirion
    interface SplitControl as TempHumControl;
    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;
//Taos
    interface SplitControl as TaosControl;
    interface ADC as TaosCh0;
    interface ADC as TaosCh1;

    interface ADCControl;
    interface Timer;
    interface Leds;
    
#if FEATURE_UART_SEND
	interface SendMsg as SendUART;
	command result_t PowerMgrEnable();
	command result_t PowerMgrDisable();
#endif
  }
}
implementation
{

  // This enum records the current state for the state machine
  // int Timer.fired(); 
  enum {
  	START,
	BUSY,
	GPS_BUSY,
	BATT_DONE,
	HUMIDITY_DONE,
	PRESSURE_DONE,
	LIGHT_DONE,
	ACCEL_DONE,
	GPS_DONE};

  enum {SENSOR_NONE = 0,
        SENSOR_BATT_START = 10,
		
	SENSOR_HUMIDITY_START = 20,
	SENSOR_HUMIDITY_GETHUMDATA = 21,
	SENSOR_HUMIDITY_GETTEMPDATA = 22,
	SENSOR_HUMIDITY_STOP = 23,

	SENSOR_PRESSURE_START = 30,
	SENSOR_PRESSURE_GETCAL = 31,
	SENSOR_PRESSURE_GETPRESSDATA = 32,
	SENSOR_PRESSURE_GETTEMPDATA = 33,
	SENSOR_PRESSURE_STOP = 34,

	SENSOR_LIGHT_START = 40,
	SENSOR_LIGHT_GETCH0DATA = 41,
	SENSOR_LIGHT_GETCH1DATA = 42,
	SENSOR_LIGHT_STOP = 43,
		
	SENSOR_ACCEL_START = 50,
	SENSOR_ACCEL_GETXDATA = 51,
	SENSOR_ACCEL_GETYDATA = 52,
	SENSOR_ACCEL_STOP = 53};
  
// timer period in msec
#define XSENSOR_SAMPLE_RATE 1000
// max wait time for gps packet = GPS_MAX_WAIT*TIMER_PERIOD
#define GPS_MAX_WAIT 20             

  char count;
  
  uint32_t   timer_rate;  
  bool       sleeping;	       // application command state
 
  uint16_t calibration[4];           // intersema calibration words
  norace uint8_t  main_state;        // main state of the schedule
  uint8_t  sensor_state;             // debug only
  
  uint8_t gps_wait_cnt;              //cnts wait periods for gps pkt to arrive
  bool gps_pwr_on;                   //true if gps power on
    
  TOS_Msg msg_buf_radio;
  TOS_MsgPtr msg_radio;
  norace XDataMsg   readings;
  norace uint8_t iNextPacketID;

  bool sending_packet, WaitingForSend;

  char gga_fields[GGA_FIELDS][GPS_CHAR_PER_FIELD]; // = {{0}};

  task void send_radio_msg() {

    uint8_t i;
    uint16_t len;
    XDataMsg *data;
	
      // Fill the given data buffer.
      data = (XDataMsg *)call Send.getBuffer(msg_radio, &len);

      for (i = 0; i <= sizeof(XDataMsg)-1; i++)
	    ((uint8_t*)data)[i] = ((uint8_t*)&readings)[i]; 
	
	data->xmeshHeader.board_id  = SENSOR_BOARD_ID;
	data->xmeshHeader.packet_id = iNextPacketID;    
	data->xmeshHeader.node_id   = TOS_LOCAL_ADDRESS;
	data->xmeshHeader.parent    = call RouteControl.getParent();
	
#if FEATURE_UART_SEND
	if (TOS_LOCAL_ADDRESS != 0) {
	    call PowerMgrDisable();
	    TOSH_uwait(1000);
	    if (call SendUART.send(TOS_UART_ADDR, sizeof(XDataMsg), 
				   msg_radio) != SUCCESS) 
	    {
		atomic sending_packet = FALSE;
		call Leds.yellowOff();
		call PowerMgrEnable();
	    }
	} 
	else 
#endif
	
	// Send the RF packet!
	if (call Send.send(msg_radio, sizeof(XDataMsg)) != SUCCESS) {
	    atomic {
	    	sending_packet = FALSE;
	    	WaitingForSend = FALSE;
	    }
	}
    return;
  }

 task void stopPressureControl() {

    atomic sensor_state = SENSOR_PRESSURE_STOP;
 	call PressureControl.stop();
 	return;
 }

 task void stopTempHumControl(){
 	atomic sensor_state = SENSOR_HUMIDITY_STOP;
	call TempHumControl.stop();
 	return;
 	}

  task void stopTaosControl(){
 	atomic sensor_state = SENSOR_LIGHT_STOP;
 	call TaosControl.stop();
 	return;
 	}

   task void powerOffAccel(){
     atomic sensor_state = SENSOR_ACCEL_STOP;
 	 call AccelCmd.PowerSwitch(0);                            //power off
 	 return;
 	}

  command result_t StdControl.init() {
   
    atomic {

      msg_radio = &msg_buf_radio;
      gps_pwr_on = FALSE;
      sending_packet = FALSE;
      WaitingForSend = FALSE;
    }

    call BattControl.init();    
    // usart1 is also connected to external serial flash
    // set usart1 lines to correct state
    TOSH_MAKE_FLASH_OUT_OUTPUT();             //tx output
    TOSH_MAKE_FLASH_CLK_OUTPUT();             //usart clk

    call ADCControl.init();
    call Leds.init();

#ifdef MTS420    
    call GpsControl.init();      
#endif

    call TaosControl.init();
    call AccelControl.init();      //initialize accelerometer 
    call TempHumControl.init();    //init Sensirion
    call PressureControl.init();   // init Intersema
	
    return SUCCESS;
  }


  command result_t StdControl.start() {

    //in case Sensirion doesn't respond
    call HumidityError.enable();
    call TemperatureError.enable();

#ifdef MTS420
    call GpsControl.start();      
#endif
      
    atomic main_state = START;
    atomic sensor_state= SENSOR_NONE;
    atomic gps_wait_cnt = 0;
    call Timer.start(TIMER_REPEAT,XSENSOR_SAMPLE_RATE);//start up sensor measurements

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    
    call BattControl.stop(); 
#ifdef MTS420
     call GpsControl.stop();
     call GpsCmd.TxRxSwitch(0);
#endif
    call Timer.stop();
    return SUCCESS;
  }

/******************************************************************************
 * Timer fired, test GPS, humidity/temp
 * async for test only
 * If gps_wait_cnt > 0 then gps is active, waiting for a packet
 *****************************************************************************/
  event result_t Timer.fired() {

    uint8_t l_state;

    call Leds.redToggle();		

#ifdef MTS420
    if (!gps_pwr_on){
      // turn on GPS power, stays on for entire test  
      return call GpsCmd.PowerSwitch(1);  
      return SUCCESS;
    }
#endif
    atomic l_state = main_state;
    // don't overrun buffers
    if (sending_packet || (l_state == BUSY)) return SUCCESS ;  
    
    if (WaitingForSend){
#ifdef MTS420
//      if (gps_pwr_on)call GpsCmd.PowerSwitch(0); 
#endif
      post send_radio_msg();
      return SUCCESS;
    }

	
    switch(l_state) {
    case START:
      atomic{
	main_state = BUSY;
	sensor_state = SENSOR_BATT_START;
      }
      call Leds.greenOn();
      call Leds.redToggle();
      call BattControl.start(); 
      return call ADCBATT.getData();           //get vref data;
      break;

    case BATT_DONE:
      call BattControl.stop(); 
      atomic{
	main_state = BUSY;
	sensor_state = SENSOR_HUMIDITY_START;
      }
      call Leds.redToggle();
      return call TempHumControl.start();
      break;	  

    case HUMIDITY_DONE:
      atomic {
	main_state = BUSY;
	sensor_state  = SENSOR_PRESSURE_START;
      }
      call Leds.redToggle();
      return call PressureControl.start();
      break;
	 	  
    case PRESSURE_DONE:
      atomic{
	main_state = BUSY;
	sensor_state = SENSOR_LIGHT_START;
      }
      return call TaosControl.start();
      break;
 		  
    case LIGHT_DONE:
      atomic{
	main_state = BUSY;
	sensor_state = SENSOR_ACCEL_START;
      }
      call Leds.redToggle();
      return call AccelCmd.PowerSwitch(1);//power on
      break;
	
    case ACCEL_DONE:
      call Leds.greenOff();
#ifdef MTS420
      atomic main_state = GPS_BUSY;
      return call GpsCmd.TxRxSwitch(1);           //enable gps tx/rx
#else
      atomic main_state = START;
      return SUCCESS;
#endif
      break;

#ifdef MTS420	
    case GPS_BUSY:
      if (gps_wait_cnt >= GPS_MAX_WAIT){      // gps rcvd pkt before time out?             
	call GpsCmd.TxRxSwitch(0);           // no,disable gps tx/rx switches
	atomic main_state = START;
	call Leds.yellowToggle();
	return SUCCESS;
      }
      else {
	gps_wait_cnt++;                      //keep waiting for gps pkt
	return SUCCESS;
      }
      break;

    case GPS_DONE:
      atomic main_state = START;
      return SUCCESS;
      break;  
#endif
    }
    
    return SUCCESS;
  }


/******************************************************************************
 * Packet received from GPS - ASCII msg
 * 1st byte in pkt is number of ascii bytes
 * async used only for testing
 GGA - Global Positioning System Fix Data
        GGA,123519,4807.038,N,01131.324,E,1,08,0.9,545.4,M,46.9,M, , *42
           123519       Fix taken at 12:35:19 UTC
           4807.038,N   Latitude 48 deg 07.038' N
           01131.324,E  Longitude 11 deg 31.324' E
           1            Fix quality: 0 = invalid
                                     1 = GPS fix
                                     2 = DGPS fix
           08           Number of satellites being tracked
           0.9          Horizontal dilution of position
           545.4,M      Altitude, Metres, above mean sea level
           46.9,M       Height of geoid (mean sea level) above WGS84
                        ellipsoid
           (empty field) time in seconds since last DGPS update
           (empty field) DGPS station ID number
 *****************************************************************************/
#ifdef MTS420
  event TOS_MsgPtr GpsReceive.receive(TOS_MsgPtr data) {  

    char *packet_format;

    //change to GPS packet!!
    GPS_MsgPtr gps_data = (GPS_MsgPtr)data;
    
    // if gps_state = TRUE then waiting to xmit gps uart/radio packet
    if (main_state == GPS_DONE) return data;       

 
    // check for NMEA format, gga_fields[0]
    packet_format = gps_data->data;

    if (is_gga_string_m(packet_format)) {
       call parse_gga_message(gps_data);
       call load_gps_struct();
    } else {
      return data;
    }
    
    if (gps_pwr_on)call GpsCmd.TxRxSwitch(0); // stop receive from gpsuart
    atomic main_state = GPS_DONE;    
    iNextPacketID = 2;  // issue gga packet xmit
    WaitingForSend =  TRUE;

    return data;                    
  }


  // This command is scheduled for replacement by the appropriate
  // gga parsing service, which is implemented but not yet wired.
  command result_t parse_gga_message(GPS_MsgPtr gps_data) {

    uint8_t i,j,k,m;
    bool end_of_field;
    uint8_t length;

    // parse comma delimited fields to gga_filed[][]
    end_of_field = FALSE;
    i=0;
    k=0;
    length = gps_data->length;
    while (i < GGA_FIELDS) {
      // assemble gga_fields array
      end_of_field = FALSE;
      j = 0;
      while ((!end_of_field) &( k < length)) {
	if (gps_data->data[k] == GPS_DELIMITER) {
	  end_of_field = TRUE;
	} 
	else {
	  gga_fields[i][j] = gps_data->data[k];
	}
	j++;
	k++;
      }
      // two commas (,,) indicate empty field
      // if field is empty, set it equal to 0
      if (j <= 1) {
	for (m=0; m<10; m++) gga_fields[i][m] = '0';
      }
      i++;
    }
    return SUCCESS;

  }

  command void load_gps_struct() {

    char * pdata;
    uint8_t NS,EW;

    // This code is not very useful because the same line
    // is executed whether the if statement is evaluated
    // true or false.  The valid field of the array/struct
    // should be replaced by a number_of_satellites field,
    // which provides the more information: no fix if less
    // 3 satellites, and bad fix if less than 5 sats.
    if((gga_fields[6][0]-'0')<=0) {
      readings.xData.dataGps.valid = (uint8_t)(gga_fields[6][0]-'0');
    } else {
      readings.xData.dataGps.valid = (uint8_t)(gga_fields[6][0]-'0');
    } 

    /** Extract Greenwich time. */
    pdata=gga_fields[1];
    readings.xData.dataGps.hours = extract_hours_m(pdata);
    readings.xData.dataGps.minutes = extract_minutes_m(pdata);
    readings.xData.dataGps.dec_sec = (uint32_t)(1000*extract_dec_sec_m(pdata)); 

    pdata=gga_fields[2];
    readings.xData.dataGps.Lat_deg = extract_Lat_deg_m(pdata);
    readings.xData.dataGps.Lat_dec_min = (uint32_t)(10000*extract_Lat_dec_min_m(pdata));

    pdata = gga_fields[4];
    readings.xData.dataGps.Long_deg = extract_Long_deg_m(pdata); 
    readings.xData.dataGps.Long_dec_min = (uint32_t)(10000*extract_Long_dec_min_m(pdata));

    NS = (gga_fields[3][0] == 'N') ? 1 : 0;
    EW = (gga_fields[5][0] == 'W') ? 1 : 0;
    readings.xData.dataGps.NSEWind = EW | (NS<<4); // eg. Status = 000N000E = 00010000

    // Add code for extracting satellites here.
  }


event result_t GpsCmd.PowerSet(uint8_t PowerState){
  if(PowerState) {
    atomic  gps_pwr_on = TRUE;
    call Leds.yellowOn();
  }
  else {
    atomic gps_pwr_on = FALSE;
    call Leds.yellowOff();
  }
  return SUCCESS;
 }

 event result_t GpsCmd.TxRxSet(uint8_t rtstate){
  
  // gps tx/rx switches set to on or off
  if (rtstate){
    //reinit gps uart since its shared with pressure sensor
    call GpsControl.start();
    //start counting time intervals, waiting for gps pkt          
    atomic gps_wait_cnt = 0;      
    call Leds.redOn();
  }
  else{
    // gps rx,tx control line switched off, restart weather sensors	    
    //atomic main_state = START;      
    call Leds.redOff();
  }
  return SUCCESS;
 }
#endif
 
 /****************************************************************************
 * Battery Ref  or thermistor data ready 
 ****************************************************************************/
  async event result_t ADCBATT.dataReady(uint16_t data) {
      
    readings.xData.data3.vref = data;      //voltage reference data
    atomic main_state = BATT_DONE;
    return SUCCESS;
  }
  
  
/******************************************************************************
 * Sensirion SHT11 humidity/temperature sensor
 * - Humidity data is 12 bit:
 *     Linear calc (no temp correction)
 *        fRH = -4.0 + 0.0405 * data -0.0000028 * data^2     'RH linear
 *     With temperature correction:
 *        fRH = (fTemp - 25) * (0.01 + 0.00008 * data) + fRH        'RH true
 * - Temperature data is 14 bit
 *     Temp(degC) = -38.4 + 0.0098 * data
 *****************************************************************************/
  async event result_t Temperature.dataReady(uint16_t data) {
    
    readings.xData.data3.temp = data;
    post stopTempHumControl();
    return SUCCESS;
  }

  async event result_t Humidity.dataReady(uint16_t data) {
    
    readings.xData.data3.humidity = data;
    atomic sensor_state = SENSOR_HUMIDITY_GETTEMPDATA;
    return call Temperature.getData();
  }

  event result_t TempHumControl.startDone() {
    
    atomic sensor_state = SENSOR_HUMIDITY_GETHUMDATA;
    call Humidity.getData();
    return SUCCESS;
  }
  
  event result_t TempHumControl.initDone() {    
    return SUCCESS;
  }

  event result_t TempHumControl.stopDone() {   
    atomic main_state = HUMIDITY_DONE;
    return SUCCESS;
  }

  event result_t HumidityError.error(uint8_t token)
  {
    
    call Temperature.getData();
    return SUCCESS;
  }


  event result_t TemperatureError.error(uint8_t token)
  {
    
    call TempHumControl.stop();
    atomic main_state = HUMIDITY_DONE;
    return SUCCESS;
  }  

 /******************************************************************************
 * Intersema MS5534A barometric pressure/temperature sensor
 *  - 6 cal coefficients (C1..C6) are extracted from 4, 16 bit,words from sensor
 * - Temperature measurement:
 *     UT1=8*C5+20224
 *     dT=data-UT1
 *     Temp=(degC x10)=200+dT(C6+50)/1024
 * - Pressure measurement:
 *     OFF=C2*4 + ((C4-512)*dT)/1024
 *     SENS=C1+(C3*dT)/1024 + 24576
 *     X=(SENS*(PressureData-7168))/16384 - OFF
 *     Press(mbar)= X/32+250
 *****************************************************************************/
  async event result_t IntersemaPressure.dataReady(uint16_t data) {    
    readings.xData.data3.intersemapressure = data;
    atomic atomic sensor_state = SENSOR_PRESSURE_GETTEMPDATA;
    return call IntersemaTemp.getData();
  }

  
  async event result_t IntersemaTemp.dataReady(uint16_t data) {
    readings.xData.data3.intersematemp = data;
    post stopPressureControl();
    return SUCCESS;
  }

  
  event result_t IntersemaCal.dataReady(char word, uint16_t value) {
    
    // make sure we get all the calibration bytes
    count++;
   
    calibration[word-1] = value;

    if (count == 4) {
      readings.xData.data3.cal_word1 = calibration[0];
      readings.xData.data3.cal_word2 = calibration[1];
      readings.xData.data3.cal_word3 = calibration[2];
      readings.xData.data3.cal_word4 = calibration[3];
      	 
      atomic sensor_state = SENSOR_PRESSURE_GETPRESSDATA;
      call IntersemaPressure.getData();
    }

    return SUCCESS;
  }

  event result_t PressureControl.initDone() {
    
    return SUCCESS;
  }

  event result_t PressureControl.startDone() {
    
    count = 0;
    atomic sensor_state = SENSOR_PRESSURE_GETCAL;
    call IntersemaCal.getData();
    return SUCCESS;
  }
  
  event result_t PressureControl.stopDone() {
    
    atomic main_state = PRESSURE_DONE;
    iNextPacketID = 3;  // issue 1st sensors packet xmit
    atomic WaitingForSend = TRUE;
    return SUCCESS;
  }

/******************************************************************************
 * Taos- tsl2250 light sensor
 * Two ADC channels:
 *    ADC Count Value (ACNTx) = INT(16.5*[CV-1]) +S*CV
 *    where CV = 2^^C
 *          C  = (data & 0x7) >> 4
 *          S  = data & 0xF
 * Light level (lux) = ACNT0*0.46*(e^^-3.13*R)
 *          R = ACNT1/ACNT0
 *****************************************************************************/
  async event result_t TaosCh1.dataReady(uint16_t data) {

    readings.xData.data4.taosch1 = data;
    post stopTaosControl();
    return SUCCESS;
  }

  async event result_t TaosCh0.dataReady(uint16_t data) {

    readings.xData.data4.taosch0 = data;
    atomic sensor_state = SENSOR_LIGHT_GETCH1DATA;
    return call TaosCh1.getData();
  }

  event result_t TaosControl.startDone(){

    atomic sensor_state = SENSOR_LIGHT_GETCH0DATA;
    return call TaosCh0.getData();
  }
  
  event result_t TaosControl.initDone() {

    return SUCCESS;
  }

  event result_t TaosControl.stopDone() {
   
    atomic main_state = LIGHT_DONE;
    return SUCCESS;
  }

/******************************************************************************
 * ADXL202E Accelerometer
 * At 3.0 supply this sensor's sensitivty is ~167mv/g
 *        0 g is at ~1.5V or ~VCC/2 - this varies alot.
 *        For an accurate calibration measure each axis at +/- 1 g and
 *        compute the center point (0 g level) as 1/2 of difference.
 * Note: this app doesn't measure the battery voltage, it assumes 3.2 volts
 * To getter better accuracy measure the battery voltage as this effects the
 * full scale of the Atmega128 ADC.
 * bits/mv = 1024/(1000*VBATT)
 * bits/g  = 1024/(1000*VBATT)(bits/mv) * 167(mv/g)
 *         = 171/VBATT (bits/g)
 * C       = 0.171/VBATT (bits/mg)
 * Accel(mg) ~ (ADC DATA - 512) /C
 *****************************************************************************/  
  
async event result_t AccelY.dataReady(uint16_t data){
    readings.xData.data4.accel_y = data;
    post powerOffAccel();
    return SUCCESS;
}
 
 
/***************************************************/
async  event result_t AccelX.dataReady(uint16_t  data){
    
    readings.xData.data4.accel_x = data;
    atomic sensor_state = SENSOR_ACCEL_GETYDATA;
    call AccelY.getData();
    return SUCCESS;
  }

/************power on/off**********************************************/
 event result_t AccelCmd.SwitchesSet(uint8_t PowerState){ 

  if (PowerState){
     call AccelX.getData();                     //start measuring X accel axis
     atomic sensor_state = SENSOR_ACCEL_GETXDATA;
  } 
  else{
    atomic main_state = ACCEL_DONE;
    iNextPacketID = 4;  // issue 1st sensors packet xmit
    atomic WaitingForSend = TRUE;
  }
  return SUCCESS;  
 }

  static void initialize() {
      atomic {
	  sleeping = FALSE;
	  main_state = START;
  	  WaitingForSend = FALSE;
	  sending_packet = FALSE;
	  timer_rate = XSENSOR_SAMPLE_RATE;
      }
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

	  default:
	      break;
      }    
      
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
      atomic msg_radio = msg;
      msg_radio->addr = TOS_BCAST_ADDR;
      
      if (call Send.send(msg_radio, sizeof(XDataMsg)) != SUCCESS) {
	  atomic sending_packet = FALSE;
	  call Leds.yellowOff();
      }
      
      if (TOS_LOCAL_ADDRESS != 0) // never turn on power mgr for base
	  call PowerMgrEnable();
      
      //}
      return SUCCESS;
  }
#endif
 
/****************************************************************************
 * Radio msg xmitted. 
 ****************************************************************************/
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {

    call Leds.yellowOff();

    atomic {
      msg_radio = msg;
      WaitingForSend = FALSE;
      sending_packet = FALSE;	  
    }
    
#if FEATURE_UART_SEND
      if (TOS_LOCAL_ADDRESS != 0) // never turn on power mgr for base
	  call PowerMgrEnable();
#endif

    return SUCCESS;
  }
  
#ifdef XMESHSYNC  
  task void SendPing() {
    XDataMsg *pReading;
    uint16_t Len;

      
    if ((pReading = (XDataMsg *)call Send.getBuffer(msg_radio,&Len))) {
      pReading->xmeshHeader.parent = call RouteControl.getParent();
      if ((call Send.send(msg_radio,sizeof(XDataMsg))) != SUCCESS)
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
