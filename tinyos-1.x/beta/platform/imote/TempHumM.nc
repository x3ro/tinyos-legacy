/*									tab:4
 **
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
/*
 *
 * Authors:		Mohammad Rahmim, Joe Polastre
 *
 * $Id: TempHumM.nc,v 1.3 2004/07/16 20:44:21 jsherbac Exp $
 */

module TempHumM {
  provides {
    interface StdControl;
    interface ADC as TempSensor;
    interface ADC as HumSensor;
//    interface ADCError as HumError;
//    interface ADCError as TempError;
  }
  uses {
    interface Leds;
    interface Timer;
    interface StdControl as TimerControl;
  }

}
implementation {


#include "sensorboard.h"

  //states
  enum {READY=0, TEMP_MEASUREMENT=1, HUM_MEASUREMENT=2, POWER_OFF};

  char state;
  uint8_t timeout;
  uint8_t errornum;
  uint16_t data;

  bool humerror,temperror;

  void HUMIDITY_MAKE_DATA_OUTPUT(){ TOSH_MAKE_I2C_BUS1_SDA_OUTPUT();}
  void HUMIDITY_MAKE_DATA_INPUT() { TOSH_MAKE_I2C_BUS1_SDA_INPUT(); }  
  
  void HUMIDITY_SET_DATA() { TOSH_SET_I2C_BUS1_SDA_PIN(); }
  void HUMIDITY_CLEAR_DATA() { TOSH_CLR_I2C_BUS1_SDA_PIN(); }
  char HUMIDITY_GET_DATA() { return TOSH_READ_I2C_BUS1_SDA_PIN(); }  
  
  void HUMIDITY_MAKE_CLOCK_OUTPUT() { TOSH_MAKE_I2C_BUS1_SCL_OUTPUT(); }
  void HUMIDITY_MAKE_CLOCK_INPUT()  { TOSH_MAKE_I2C_BUS1_SCL_INPUT(); }
  void HUMIDITY_SET_CLOCK() { TOSH_SET_I2C_BUS1_SCL_PIN(); }
  void HUMIDITY_CLEAR_CLOCK() { TOSH_CLR_I2C_BUS1_SCL_PIN(); }

  void TOSH_wait_250ns()
      {
          int i;
          for( i=0;i<2; i++)
              {
                  asm volatile ("nop" ::);
              }
      }
  
  char calc_crc(char current, char in) {
    return crctable[current ^ in];
  }

/*  task void signalHumError() {
    signal HumError.error(errornum);
  }

  task void signalTempError() {
    signal TempError.error(errornum);
  }*/

  static inline void  ack()
  {
    HUMIDITY_MAKE_DATA_OUTPUT();
    HUMIDITY_CLEAR_DATA();
    TOSH_wait_250ns();
    HUMIDITY_SET_CLOCK();
    TOSH_wait_250ns();
    HUMIDITY_CLEAR_CLOCK();
    HUMIDITY_MAKE_DATA_INPUT();
    HUMIDITY_SET_DATA();
  }

  static inline void initseq()
  { 
    HUMIDITY_MAKE_DATA_OUTPUT();
    HUMIDITY_SET_DATA();
    HUMIDITY_CLEAR_CLOCK();   
    TOSH_wait_250ns();         
    HUMIDITY_SET_CLOCK();
    TOSH_wait_250ns();
    HUMIDITY_CLEAR_DATA();
    TOSH_wait_250ns();
    HUMIDITY_CLEAR_CLOCK();
    TOSH_wait_250ns();
    HUMIDITY_SET_CLOCK();
    TOSH_wait_250ns(); 
    HUMIDITY_SET_DATA();
    TOSH_wait_250ns(); 
    HUMIDITY_CLEAR_CLOCK();
  }

  static inline void reset()
  {
    int i;
    HUMIDITY_MAKE_DATA_OUTPUT();
    HUMIDITY_SET_DATA();
    HUMIDITY_CLEAR_CLOCK();
    for (i=0;i<9;i++) {
      HUMIDITY_SET_CLOCK();
      TOSH_wait_250ns();
      HUMIDITY_CLEAR_CLOCK();
    }
  }

  static inline char processCommand(int cmd)
  {
    int i;
    int CMD = cmd;
    cmd &= 0x1f;
    //HUMIDITY_INT_DISABLE();
    reset();           
    initseq();        //sending the init sequence
    for(i=0;i<8;i++)
        {
            if(cmd & 0x80) 
                HUMIDITY_SET_DATA();
            else 
                HUMIDITY_CLEAR_DATA();
            cmd = cmd << 1 ;
            HUMIDITY_SET_CLOCK();
            TOSH_wait_250ns();              
            TOSH_wait_250ns();              
            HUMIDITY_CLEAR_CLOCK();        
        }
    HUMIDITY_MAKE_DATA_INPUT();
    HUMIDITY_SET_DATA();
    TOSH_wait_250ns();
    HUMIDITY_SET_CLOCK();
    TOSH_wait_250ns();
    if(HUMIDITY_GET_DATA()) 
        { 
            reset(); 
            errornum = 2;
/*            if ((CMD == TOSH_HUMIDITY_ADDR) && (humerror == TRUE))
                post signalHumError();
            else if ((CMD == TOSH_HUMIDTEMP_ADDR) && (temperror == TRUE))
                post signalTempError();*/
            return 0; 
        }
    TOSH_wait_250ns();
    HUMIDITY_CLEAR_CLOCK();
    if((CMD == TOSH_HUMIDITY_ADDR) || (CMD == TOSH_HUMIDTEMP_ADDR) )
        {
            if ((CMD == TOSH_HUMIDITY_ADDR) && (humerror == TRUE)) 
                {
                    timeout = 0;
                    call Timer.start(TIMER_REPEAT, HUMIDITY_TIMEOUT_MS);
                }
            else if ((CMD == TOSH_HUMIDTEMP_ADDR) && (temperror == TRUE)) 
                {
                    timeout = 0;
                    call Timer.start(TIMER_REPEAT, HUMIDITY_TIMEOUT_MS);
                }
            TOSH_wait_250ns();
            TM_SetPio(5);
            TM_EnablePIOInt();
         //HUMIDITY_INT_ENABLE();
        }
    return 1;
  }
  
  extern void TM_PIOIsr_ISR() __attribute__ ((C, spontaneous));

  command result_t StdControl.init() {
    humerror = FALSE;
    temperror = FALSE;
    state = POWER_OFF;
    TM_RegisterInterrupt(eTM_PIO, (tIntFunc) TM_PIOIsr_ISR, eTM_ProLow);
    return call TimerControl.init();
  }

  command result_t StdControl.start() {
    state=READY;
    TM_SetPioAsOutput(5);
    TM_SetPioAsOutput(6);
    
    HUMIDITY_CLEAR_CLOCK();
    HUMIDITY_MAKE_CLOCK_OUTPUT();
    HUMIDITY_SET_DATA();
    HUMIDITY_MAKE_DATA_INPUT();
    //HUMIDITY_INT_DISABLE();
    reset();
    processCommand(TOSH_HUMIDITY_RESET);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    state = POWER_OFF;
    HUMIDITY_CLEAR_CLOCK();
    HUMIDITY_MAKE_CLOCK_INPUT();
    HUMIDITY_MAKE_DATA_INPUT();
    HUMIDITY_CLEAR_DATA();
    TM_DisablePIOInt();
    return SUCCESS;
  }

  default async event result_t TempSensor.dataReady(uint16_t tempData) 
  {
    return SUCCESS;
  }


  default async event result_t HumSensor.dataReady(uint16_t humData) 
  {
    return SUCCESS;
  }


  task void readSensor()
  {
    char i;
    char CRC=0;  
    uint32_t temp, humidity;
    data=0; 
    
    
    //call Timer.stop();
    
    for(i=0;i<8;i++)
        {
            HUMIDITY_SET_CLOCK();   
            TOSH_wait_250ns();
            data |= HUMIDITY_GET_DATA();
            data = data << 1;
            HUMIDITY_CLEAR_CLOCK();
        }
    ack();
    for(i=0;i<8;i++)
        {
            HUMIDITY_SET_CLOCK();   
            TOSH_wait_250ns();
            data |= HUMIDITY_GET_DATA();
            //the last byte of data should not be shifted
            if(i!=7) 
                data = data << 1;  
            HUMIDITY_CLEAR_CLOCK();
        }
    ack();
    for(i=0;i<8;i++){
      HUMIDITY_SET_CLOCK();   
      TOSH_wait_250ns();
      CRC |= HUMIDITY_GET_DATA();
      if(i!=7)CRC = CRC << 1;
      HUMIDITY_CLEAR_CLOCK();
    }
    // nack with high as it should be for the CRC ack
    HUMIDITY_MAKE_DATA_OUTPUT();
    HUMIDITY_SET_DATA();          
    TOSH_wait_250ns();
    HUMIDITY_SET_CLOCK();
    TOSH_wait_250ns();
    HUMIDITY_CLEAR_CLOCK();

    /**********
     * initial implementation of CRC calculation
     * commented out for now
    {
	int i;
	char crc = 0;
	char reverse_crc = 0;

	// check CRC
	crc = calc_crc(crc,TOSH_HUMIDTEM_ADDR);
	crc = calc_crc(crc,data[0]);
	crc = calc_crc(crc,data[1]);

	// reverse the crc bits
	for (i=0; i<8; i++)
	  reverse_crc = reverse_crc + (((crc >> i) & 0x01) << (7-i));

	// is the crc correct?
	if ((reverse_crc == data[2]) || (crc == data[2])) {
	}
    }
    **/


    if(state==TEMP_MEASUREMENT){
        // let the PC do the calculation *****
      
        //temp=data;
        //t= (((ftemp) )*0.98-3840)/100;
        //temp= (int16_t) t; 
        //if(temp > 100 ) temp=100;
        //if(temp < -40 ) temp=-40;
        temp = (((data>>1) *18) -39280)/1000;
        //signal TempSensor.dataReady( (int16_t)temp);
        signal TempSensor.dataReady((uint16_t)(temp & 0xFF));
        //signal TempSensor.dataReady( 13262);
        
        //signal TempSensor.dataReady(data);
    }
    else if(state==HUM_MEASUREMENT) {
      /* let the PC do the calculation *****
      hum=data;
      h= 0.0405 * (float) (hum) - 4 - (float)(hum) * (float)(hum)*0.0000028;
      h= (t-25) * (0.01 + 0.00128 * hum) + h;
      hum= (int16_t) h;
      if(hum > 100 ) hum=100;
      if(hum < 0 ) hum=0;
      signal HumSensor.dataReady(hum);
      ****/
        humidity = (((data>>1) * (data >>1)) * -28)/10000000;
        humidity += ((data>>1) * 405)/10000;
        humidity -=4;
        //     if(humidity > 99)
        //  humidity = 99;
        // humidity = data;
        //       signal HumSensor.dataReady((uint16_t)(humidity & 0xFF));
        signal HumSensor.dataReady((uint16_t)(humidity));
    }
    state=READY;
  }


  //#ifndef PLATFORM_PC
#if 0  
TOSH_SIGNAL(HUMIDITY_INTERRUPT)
  {
    HUMIDITY_INT_DISABLE();
    post readSensor();
    return;
  }
#endif

//if we get the GPIO interrupt and it's the correct pin, post readSensor();

 void TM_PIO_InterruptHdl() __attribute__ ((C, spontaneous)) 
     {
         TM_DisablePIOInt();
         if( TM_ReadPio(1) == 0)
             {
                 //only disable it if we get the one we want...
                 //it seems like there's some stale state or somethin
                 TM_ResetPio(5);
                 post readSensor();
             }
         else
             {
                 TM_EnablePIOInt();
             }
         TM_ClearPioInterrupt();
     }

  // no such thing
  async command result_t TempSensor.getContinuousData() {
    return FAIL;
  }

  // no such thing
  async command result_t HumSensor.getContinuousData() {
    return FAIL;
  }

  async command result_t TempSensor.getData()
  {
    if(state!= READY ){
      reset();
    }
    state=TEMP_MEASUREMENT;
    processCommand(TOSH_HUMIDTEMP_ADDR);
    return SUCCESS;
  }

  async command result_t HumSensor.getData()
  {
    if(state!= READY ){
      reset();
    }
    state=HUM_MEASUREMENT;
    processCommand(TOSH_HUMIDITY_ADDR);
    return SUCCESS;
  }


/*  command result_t HumError.enable() {
    if (humerror == FALSE) {
        //atomic humerror = TRUE;
        humerror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.enable() {
    if (temperror == FALSE) {
        //atomic temperror = TRUE;
        temperror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t HumError.disable() {
    if (humerror == TRUE) {
        //atomic humerror = FALSE;
        humerror = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.disable() {
    if (temperror == TRUE) {
        // atomic temperror = FALSE;
        temperror = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }*/
 
  event result_t Timer.fired() {
    timeout++;
    if (timeout > HUMIDITY_TIMEOUT_TRIES) {
      if ((state == HUM_MEASUREMENT) && (humerror == TRUE)) {
        call Timer.stop();
        //HUMIDITY_INT_DISABLE();
        state = READY;
        errornum = 1;
//        post signalHumError();
      }
      else if ((state == TEMP_MEASUREMENT) && (temperror == TRUE)) {
        call Timer.stop();
        //HUMIDITY_INT_DISABLE();
        state = READY;
        errornum = 1;
//        post signalTempError();
      }
    }
    return SUCCESS;
  }

 
/*  default event result_t HumError.error(uint8_t token) { return SUCCESS; }

  default event result_t TempError.error(uint8_t token) { return SUCCESS; }*/
 
}
