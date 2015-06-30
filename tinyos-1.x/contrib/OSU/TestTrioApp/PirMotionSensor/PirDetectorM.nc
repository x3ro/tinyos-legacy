/*
 * Copyright (c) 2004 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

/**
 * The <code>PirDetectorM</code> implements the core of the PIR detector.
 *
 * @author  Emre Ertin
 */
#ifndef _PIR_H
#define _PIR_H

#define LOG_SERIAL 1
#endif

includes Pir;
module PirDetectorM
{
    provides
    {
        interface StdControl;
	  interface PirDetector;
    }
    uses
    {
        interface ADC;
        interface PIR;
        interface Scheduler as Scheduler;
	  interface StdControl as PirControl;

	  #ifdef LOG_SERIAL
		  interface StdControl as UARTControl;
		  interface SendMsg as UARTSend;
	  #endif
	  interface Leds;	
    }
}
implementation
{

	#ifdef LOG_SERIAL

 	typedef struct IntMsg {
	  uint16_t src;
	  uint8_t type;
	  uint16_t count;
	  uint16_t sample1;
	  uint8_t flagged;
        uint8_t detected;
	  int32_t zvalue;
	} IntMsg;

	struct TOS_Msg data;
	uint16_t count = 0;
	#endif

    bool detected = FALSE; 

    uint8_t flagged;
    int16_t val;
    int16_t x[3];
    int32_t y[3];
    int32_t y2[3];
    int32_t z[3];
    int32_t currzindex;
    int8_t index,index2;

    int32_t a0,c0, a1,c1, a2,c2, b1, d1, b2, d2;
	
    uint16_t oldval = 512;  //for discarding flagged adc values

    command result_t StdControl.init()
    {
	  #ifdef LOG_SERIAL
		call UARTControl.init();
	  #endif

	  call PirControl.init();
	  index = 0;
	  x[0]=y[0]=0;
	  x[1]=y[1]=0;
	  x[2]=y[2]=0;

          //a0=128;a1=-256;a2=128;b1=-121; b2=43;
          //c0=2048;c1=4096;c2=2048;d1=-3869; d2=1833; //old values

         a0=128;a1=0;a2=-128;b1=-167; b2=55;
         c0=2048;c1=4096;c2=2048;d1=-3643; d2=1640;     //new values
 
         return SUCCESS;
    }

    command result_t StdControl.start()
    {
	  #ifdef LOG_SERIAL
		  call UARTControl.start();
	  #endif
	
	  call PirControl.start();
	  call PIR.PIROn();
	
	  return SUCCESS;
    }

    command result_t StdControl.stop()
    {
  	  return call PIR.PIROff();
    }

    
    task void processSample(){
	  bool detect;	  
	
	  x[index] = val;
	  y[index] = a0*x[index] + a1*x[(index+2)%3] + a2*x[(index+1)%3] - b1*y[(index+2)%3] - b2*y[(index+1)%3];
	 
	  y[index] = y[index]>>7;
     
          y2[index]= y[index]*y[index];
          y2[index]= y2[index]>>12;
 
          z[index] =  c0*y2[index] + c1*y2[(index+2)%3] + c2*y2[(index+1)%3] - d1*z[(index+2)%3] - d2*z[(index+1)%3];
          z[index] = z[index]>>11;
 
        currzindex = z[index];
	  detect = (z[index] > PIR_THRESHOLD ? TRUE : FALSE);
        index=(index+1)%3;
      
      if (detect) {
	if (!detected){
              detected = TRUE;
              signal PirDetector.start();
         }
      }
      else {

        if (detected) {
	      detected= FALSE;
            signal PirDetector.stop();
        }                     

      }                    
    }

   event result_t Scheduler.getPirSample()
   {
	return call ADC.getData();
   }

   event result_t Scheduler.getMagSample()
   {
	return SUCCESS;
   }

   event result_t Scheduler.getAcoSnippet()
   {
	return SUCCESS;
   }

   async event result_t ADC.dataReady(uint16_t sample)
   {
	  #ifdef LOG_SERIAL
		  IntMsg *message = (IntMsg *)data.data;
	  #endif

        
	  atomic{
           val = sample;
	     oldval = sample;
	  }
        	
	  #ifdef LOG_SERIAL 

	  message->src = TOS_LOCAL_ADDRESS;
	  message->type = 20;
	  message->count = count++;
	  message->sample1 = val;
	  message->flagged = flagged;	  
	  message->detected = detected;
	  message->zvalue = currzindex;
	  call UARTSend.send(TOS_UART_ADDR, sizeof(IntMsg), &data);
	  
  	  #endif

        call Scheduler.pirSampleComplete();
        post processSample();

        return SUCCESS;
    }
	
   #ifdef LOG_SERIAL
    event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success)
    {
	return SUCCESS;
    }
   #endif

  event void PIR.adjustDetectDone(bool result){return;}
  event void PIR.adjustQuadDone(bool result){return;}
  event void PIR.readDetectDone(uint8_t val){return;}
  event void PIR.readQuadDone(uint8_t val){return;}
  event void PIR.firedPIR(){return;}

}
