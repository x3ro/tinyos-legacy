 

/*									
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
/*								       
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
 */

module TempHumM {

  provides {
    interface StdControl;
    interface ADC as TempSensor;
    interface ADC as HumSensor;
    interface ADCError as HumError;
    interface ADCError as TempError;
  }
  uses {
    interface Leds;
    interface Timer;
    interface StdControl as TimerControl;
  }
}

implementation {
#include "SODebug.h"  
#define DBG_USR2  0                        //comment this out to enable debug 

  //states
  enum {READY=0, TEMP_MEASUREMENT=1, HUM_MEASUREMENT=2, POWER_OFF};

  char state;
  uint8_t timeout;
  uint8_t errornum;
  int16_t data;
  int cmd;

  bool humerror,temperror;

  char calc_crc(char current, char in) {
    return crctable[current ^ in];
  }

  task void signalHumError() {
    atomic {
      signal HumError.error(errornum);
    }
  }

  task void signalTempError() {
    atomic {
      signal TempError.error(errornum);
    }
  }

  // Enable Mote INT3 which is INT7 on the Atmega128
  static inline void HumidityIntEnable() {

    sbi(EICRB , 7);
    cbi(EICRB , 6);        //low level detect
    sbi(EIMSK , 7);        //enable INT7
  }

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



/******************************************************************************
 * processCommand
 *  -Send a command to the Sensirion
 *  -Toggles SCLK and SDA serial signals to Sensirion
 *  -Start by sending bus reset command (9 clocks)
 *  -Start timer to check error condition where Sensirion doesn't complete measurement
 *  -Enable SDA as interrupt, this line goes low when Sensirion completes measurement
 */
   task void  processCommand() {

      int i;
      int CMD;
      atomic {
         CMD = cmd;
         cmd &= 0x1f;
      }
      HUMIDITY_INT_DISABLE();
      reset();           
      initseq();              //reset the serial interface, 9 clocks
      for (i=0; i<8; i++) {   //xmit addr and cmd data

         atomic {
            if(cmd & 0x80) {
               HUMIDITY_SET_DATA();
            } else {
               HUMIDITY_CLEAR_DATA();
            }
            cmd = cmd << 1 ;
            HUMIDITY_SET_CLOCK();
            TOSH_wait_250ns();              
            TOSH_wait_250ns();              
            HUMIDITY_CLEAR_CLOCK();
         }
      }

      HUMIDITY_MAKE_DATA_INPUT(); //make SDA an input
      HUMIDITY_SET_DATA();
      TOSH_wait_250ns();
      HUMIDITY_SET_CLOCK();
      TOSH_wait_250ns();

      if(HUMIDITY_GET_DATA()) { //if SDA hi then Sensirion is not responding
    
         SODbg(DBG_USR2, "TempHumM.processCommand: No response from Sensirion \n"); 

	 reset(); 
         atomic {
            errornum = 2;
         }

         if ((CMD == TOSH_HUMIDITY_ADDR) && (humerror == TRUE)) {
            post signalHumError();
         } else if ((CMD == TOSH_HUMIDTEMP_ADDR) && (temperror == TRUE)) {
            post signalTempError();
         }
         //return 0; 
      }

      TOSH_wait_250ns();
      HUMIDITY_CLEAR_CLOCK();
    
      if((CMD == TOSH_HUMIDITY_ADDR) || (CMD == TOSH_HUMIDTEMP_ADDR) ) {

         if ((CMD == TOSH_HUMIDITY_ADDR) && (humerror == TRUE)) {
            SODbg(DBG_USR2, "TempHumM.processCommand: cmd complete, starting timer for measurement \n"); 

            atomic {
	       timeout = 0;
            }
            call Timer.start(TIMER_REPEAT, HUMIDITY_TIMEOUT_MS);

         } else if ((CMD == TOSH_HUMIDTEMP_ADDR) && (temperror == TRUE)) {
       
            atomic {
            timeout = 0;
         }
	 call Timer.start(TIMER_REPEAT, HUMIDITY_TIMEOUT_MS);
      }
      HumidityIntEnable();
    }
   }


  command result_t StdControl.init() {

    atomic {
       humerror = FALSE;
       temperror = FALSE;
       state = POWER_OFF;
    }
    return call TimerControl.init();
  }

   command result_t StdControl.start() {

      atomic {
         state=READY;
      }
      HUMIDITY_CLEAR_CLOCK();
      HUMIDITY_MAKE_CLOCK_OUTPUT();
      HUMIDITY_SET_DATA();
      HUMIDITY_MAKE_DATA_INPUT();
      HUMIDITY_INT_DISABLE();
      cbi(EICRA, ISC30);   //enable falling edge interrupt
      sbi(EICRA, ISC31);
      reset();
      atomic {
         cmd = TOSH_HUMIDITY_RESET;
      }
      post processCommand();
      return SUCCESS;
   }

  command result_t StdControl.stop() {
    state = POWER_OFF;
    HUMIDITY_CLEAR_CLOCK();
    HUMIDITY_MAKE_CLOCK_INPUT();
    HUMIDITY_MAKE_DATA_INPUT();
    HUMIDITY_CLEAR_DATA();
    return SUCCESS;
  }

  async default event result_t TempSensor.dataReady(uint16_t tempData) 
  {
    return SUCCESS;
  }


  async default event result_t HumSensor.dataReady(uint16_t humData) 
  {
    return SUCCESS;
  }




  /**
   * readSensor
   *  -Read data from Sensirion
   */
   task void readSensor() {

      char i;
      char CRC = 0;  
      data = 0; 

      SODbg(DBG_USR2, "TempHumM.readSensor: reading data \n"); 
    
      call Timer.stop();

      for(i=0; i<8; i++) {

         HUMIDITY_SET_CLOCK();   
         TOSH_wait_250ns();
         data |= HUMIDITY_GET_DATA();
         data = data << 1;
         HUMIDITY_CLEAR_CLOCK();
      }

      ack();

      for(i=0; i<8; i++) {

         HUMIDITY_SET_CLOCK();   
         TOSH_wait_250ns();
         data |= HUMIDITY_GET_DATA();
         //the last byte of data should not be shifted
         if(i!=7) data = data << 1;  
         HUMIDITY_CLEAR_CLOCK();
      }

      ack();

      for(i=0; i<8; i++) {

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
	crc = calc_crc(crc,TOSH_HUMIDTEMP_ADDR);
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

      atomic {
         if (state == TEMP_MEASUREMENT){
            signal TempSensor.dataReady(data);
         } else if (state == HUM_MEASUREMENT) {
            signal HumSensor.dataReady(data);
         }
         state=READY;
      }
   }



/******************************************************************************
 * TOSH_SIGNAL(HUMIDITY_INTERRUPT)
 *  -Enter here when Sensirion completes measurement
 *  -Sensirion SDA line goes low when it completes measurement
 ******************************************************************************/
// #ifndef PLATFORM_PC
   TOSH_SIGNAL(HUMIDITY_INTERRUPT) {

//spurious int?
     if(HUMIDITY_GET_DATA()) {

        call Leds.yellowOff();
        call Leds.yellowOn();
        call Leds.yellowOff();
        call Leds.yellowOn();
        return;
     }
    
     HUMIDITY_INT_DISABLE();
     SODbg(DBG_USR2, "TempHumM.TOSH_SIGNAL(HUMIDITY INTERRUPT): measurment complete \n"); 
     call Leds.redOff();
     call Leds.yellowOff();
     call Leds.yellowOn();
     call Leds.yellowOff();
     post readSensor();
     return;
  }
// #endif


  // no such thing
  async command result_t TempSensor.getContinuousData() {
    return FAIL;
  }

  // no such thing
  async command result_t HumSensor.getContinuousData() {
    return FAIL;
  }

  async command result_t TempSensor.getData() {

    atomic {
      if(state!= READY ){
         reset();
      }
    }
    //call Leds.redOn();
    atomic {
      state=TEMP_MEASUREMENT;
    }
    atomic {
       cmd = TOSH_HUMIDTEMP_ADDR;
    }
    post processCommand();
    return SUCCESS;
  }

  async command result_t HumSensor.getData() {

    atomic {
      if(state!= READY ){
         reset();
      }
    }

    SODbg(DBG_USR2, "TempHumM.getData: starting to get humidity data \n"); 
    //call Leds.yellowOn();
    atomic {
       state=HUM_MEASUREMENT;
    }
    atomic {
      cmd = TOSH_HUMIDITY_ADDR;
    }
    post processCommand();
    return SUCCESS;
  }

  command result_t HumError.enable() {
    if (humerror == FALSE) {
      atomic humerror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.enable() {
    if (temperror == FALSE) {
      atomic temperror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t HumError.disable() {
    if (humerror == TRUE) {
      atomic humerror = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.disable() {
    if (temperror == TRUE) {
      atomic temperror = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

/******************************************************************************
 * Timer.fired
 *  Sensirion should lower the data line to signal that the measurement is done
 *  This timer event used to signal a timout that senirion did not complete
 ******************************************************************************/
   event result_t Timer.fired() {

      atomic {

         timeout++;
    	  
         if (timeout > HUMIDITY_TIMEOUT_TRIES) {
           
           //call Leds.redOff();

	    //  call Leds.yellowOff();
            if ((state == HUM_MEASUREMENT) && (humerror == TRUE)) {
               call Timer.stop();
               HUMIDITY_INT_DISABLE();
               state = READY;
               errornum = 1;
               post signalHumError();
               SODbg(DBG_USR2, "TempHumM.Timer.fired: No response from Sensirion humidity   \n"); 
            } else if ((state == TEMP_MEASUREMENT) && (temperror == TRUE)) {

               call Timer.stop();
               HUMIDITY_INT_DISABLE();
               state = READY;
               errornum = 1;
               post signalTempError();
               SODbg(DBG_USR2, "TempHumM.Timer.fired: No response from Sensirion temp   \n"); 
            }
         }
      }
      return SUCCESS;
   }

  default event result_t HumError.error(uint8_t token) { return SUCCESS; }

  default event result_t TempError.error(uint8_t token) { return SUCCESS; }

}
