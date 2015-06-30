// $Id: TempM.nc,v 1.1 2005/06/01 14:51:30 hjkoerber Exp $

/* 
 * Copyright (c) Helmut-Schmidt-University, Hamburg
 *		 Dpt.of Electrical Measurement Engineering  
 *		 All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Helmut-Schmidt-University nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/** @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 *
 * $Date: 2005/06/01 14:51:30 $
 * $Revision: 1.1 $
 *
 */

/*  TEMP_INIT command initializes the MSSP as I2C*/
/*  TEMP_GET_DATA command initiates acquiring a reading from Microchip TCN75A temperature I2C sensor*/
/*  TEMP_DATA_READY is signaled, providing data, when it becomes available*/

module TempM {
  provides interface StdControl;
  provides interface ADC as TempADC;
  uses {
    interface I2CPacket;
    interface StdControl as I2CControl;
  }
}
implementation 
{
  uint8_t *sendDataPtr;
  uint8_t *receiveDataPtr;
  uint16_t sendData;
  uint16_t I2C_ADDRESS;
  uint8_t sendLength;
  uint8_t resolution;
  uint8_t conversionTime;                // the higher the resoultion the longer the conversion takes (delta/sigma-converter)
  uint8_t stateTempM; 
  uint8_t resultShift;                   // we have to shift the two result bytes according to the resolution

  enum{
    TEMPM_CONTINUOUS_CONVERSION=1,
    TEMPM_SHUTDOWN_MODE=2,
    TEMPM_ONE_SHOT_MODE=3,
    TEMPM_CONVERSION_PENDING=4,
  };

 enum{
   RES_9BIT=0,
   RES_10BIT= 1,
   RES_11BIT= 2,
   RES_12BIT= 3,
  };

 command result_t StdControl.init() { 
   stateTempM = TEMPM_CONTINUOUS_CONVERSION; 
   resolution = RES_10BIT;              // here you can choose the resolution
   switch (resolution){
   case RES_9BIT:
     conversionTime = 30;
     resultShift=7;
     break;
   case RES_10BIT:
     conversionTime = 60;
     resultShift=6;
     break;
   case RES_11BIT:
     conversionTime = 120;
     resultShift =5;
     break;
   case RES_12BIT:
     conversionTime = 240;
     resultShift=4;
     break;
   }
   I2C_ADDRESS = 0x48; // address of the Microchip TCN75A temperature I2C sensor on our sensormodule
    call I2CControl.init();
      return SUCCESS;
  }

  command result_t StdControl.start() {
    call I2CControl.start();    
    sendLength = 2;
    sendData = (resolution<<5) | 0x01;     // send data, high byte = config register -> enable shutdown because we want to save energy
    sendData = (sendData<<8) | 0x01;       // send data, low byte = register pointer=1 -> access config register
    sendDataPtr= (uint8_t *)&sendData;
    call I2CPacket.writePacket(I2C_ADDRESS, sendLength, sendDataPtr);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call I2CControl.stop();
    return SUCCESS;
  }

  async command result_t TempADC.getData() {
    if( stateTempM == TEMPM_SHUTDOWN_MODE){
      sendLength = 2;
      sendData = (resolution<<5) | 0x81;    // send data, high byte = config register  -> enable one-shot-mode
      sendData = (sendData<<8) | 0x01;      // send data, low byte = temperature register   
      return call I2CPacket.writePacket(I2C_ADDRESS, sendLength, sendDataPtr);
    }
  }

  async command result_t TempADC.getContinuousData() {
    return SUCCESS;
  }

 /**
   * here we have a simple state machine 
   */  

event void I2CPacket.writePacketDone(uint16_t addr, uint8_t _length, uint8_t* _data, result_t _result) {
  uint8_t receiveLength;

  switch(stateTempM){                       // this is the I2C state machine for sending some data 
  case TEMPM_CONTINUOUS_CONVERSION:
    if(_result==SUCCESS){
       stateTempM = TEMPM_SHUTDOWN_MODE;
     }
     break;
  case TEMPM_SHUTDOWN_MODE:
    if(_result==SUCCESS){
      stateTempM = TEMPM_ONE_SHOT_MODE;     
      TOSH_mswait(conversionTime);          // we have to wait the required conversion time until  conversion is done
      sendLength=1;
      sendData = 0;                         // send data, low byte = register pointer=1 -> access temperature register 
      call  I2CPacket.writePacket(I2C_ADDRESS, sendLength, sendDataPtr);
    }
    break;
  case TEMPM_ONE_SHOT_MODE:
    if(_result==SUCCESS){
      stateTempM = TEMPM_CONVERSION_PENDING;   
      receiveLength=2; 
      call  I2CPacket.readPacket(I2C_ADDRESS, receiveLength, receiveDataPtr);
    }
    break;
  }
  return;
}


 /**
   * Signalled temperature value when an I2CPacket has been read
   */ 
 
 event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _result) {
    uint16_t TempValue = 0;
    stateTempM = TEMPM_SHUTDOWN_MODE;
    TempValue = *_data;                     // get the data high byte (it is transmitted before the low byte on the I2C-bus)
    TempValue = (TempValue<<8)|(*(_data+1));// get the data low byte
    TempValue = (TempValue >>resultShift) & 0x07ff;   //shift 6 digits right 'cause the data is left assigned
    signal TempADC.dataReady(TempValue);    // TempValue divided by 4 gives the ambient temperatue in Celcius
    return;
  }
}

