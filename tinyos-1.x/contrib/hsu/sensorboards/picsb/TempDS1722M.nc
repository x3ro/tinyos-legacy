// $Id: TempDS1722M.nc,v 1.1 2005/12/07 18:56:38 hjkoerber Exp $

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
 ** @author Tobias Brennenstuhl
 *	   <tobias.brennenstuhl@hsu-hh.de>
 *
 * $Date: 2005/12/07 18:56:38 $
 * $Revision: 1.1 $
 *
 */

/*  TEMP_INIT command initializes the MSSP as I2C*/
/*  TEMP_GET_DATA command initiates acquiring a reading from Microchip TCN75A temperature I2C sensor*/
/*  TEMP_DATA_READY is signaled, providing data, when it becomes available*/



module TempDS1722M {

/****************************************************************************************************************/
/* 						provided interfaces									    */
/****************************************************************************************************************/

  provides {
  	interface StdControl;
  	interface ADC as TempADC;
  }

/****************************************************************************************************************/
/* 						used interfaces										    */
/****************************************************************************************************************/

  uses {
    interface SPIPacket;
    interface StdControl as SPIControl;
  }
}
implementation

/****************************************************************************************************************/
/* 						implementation						        			    */
/****************************************************************************************************************/

{

/****************************************************************************************************************/
/* 						variables						       				    */
/****************************************************************************************************************/

  uint8_t 	*TEMPDS1722M_sendDataPtr;                  						// pointer on the data we want to send
  uint8_t 	TEMPDS1722M_receiveData[2];                						// 2-Byte-Array for data receive
  uint16_t 	TEMPDS1722M_sendData=0;                   						// This variable contains the data to be send over SPI
  uint8_t 	TEMPDS1722M_sendLength;                    						// Number of bytes to send over the SPI
  uint8_t 	TEMPDS1722M_resolution;                    						// Resolution of the SPI-Sensor
  uint16_t 	TEMPDS1722M_conversionTime;               						// the higher the resoultion the longer the conversion takes (delta/sigma-converter)
  uint8_t 	TEMPDS1722M_state;              								// continuous conversion, shutdown, one shot, conversion pending or idle
  uint8_t 	TEMPDS1722M_resultShift;                   						// we have to shift the two result bytes according to the resolution

  enum{
    TEMPDS1722M_CONTINUOUS_CONVERSION	= 0x00,  							//replace state with values to programm config-register
    TEMPDS1722M_SHUTDOWN_MODE		= 0x01,
    TEMPDS1722M_ONE_SHOT_MODE		= 0x11,
    TEMPDS1722M_CONVERSION_PENDING	= 0x04,
    TEMPDS1722M_IDLE			= 0x05
  };

 enum{                                            							//replace TEMPDS1722M_resolution with values to programm config-register
   RES_8BIT =0x00,
   RES_9BIT =0x02,
   RES_10BIT=0x04,
   RES_11BIT=0x06,
   RES_12BIT=0x07,
  };

/****************************************************************************************************************/
/* 						StdControl.init 										    */
/****************************************************************************************************************/

 command result_t StdControl.init() {
   TEMPDS1722M_state = TEMPDS1722M_IDLE;
   TEMPDS1722M_resolution = RES_10BIT;             							// here you can choose the resolution
   switch (TEMPDS1722M_resolution){
   case RES_8BIT:
     TEMPDS1722M_conversionTime = 75;                 						// a temp-conversion needs 75 ms to finish, each additional bit doubles the conversion time
     TEMPDS1722M_resultShift=8;										// shift 8 bits right, because data is left assigned
     break;
   case RES_9BIT:
     TEMPDS1722M_conversionTime = 150;
     TEMPDS1722M_resultShift=7;                       						// shift 8 bits right, because data is left assigned
     break;
   case RES_10BIT:
     TEMPDS1722M_conversionTime = 300;
     TEMPDS1722M_resultShift=6;                       						// shift 8 bits right, because data is left assigned
     break;
   case RES_11BIT:
     TEMPDS1722M_conversionTime = 600;
     TEMPDS1722M_resultShift =5;                      						// shift 8 bits right, because data is left assigned
     break;
   case RES_12BIT:
     TEMPDS1722M_conversionTime = 1200;
     TEMPDS1722M_resultShift=4;                       						// shift 8 bits right, because data is left assigned
     break;
   default:
     break;
   }

    call SPIControl.init();
      return SUCCESS;
  }

/****************************************************************************************************************/
/* 						StdControl.start										    */
/****************************************************************************************************************/

  command result_t StdControl.start() {

    TEMPDS1722M_sendLength = 2;
    call SPIControl.start();                          						// set busmode to SPI

    TEMPDS1722M_sendData = TEMPDS1722M_resolution | 0xE0 | TEMPDS1722M_ONE_SHOT_MODE;   	// send data, high byte = config register -> enable shutdown because we want to save energy
    TEMPDS1722M_sendData  = (TEMPDS1722M_sendData<<8) | 0x80;
    TEMPDS1722M_sendDataPtr = (uint8_t *)&TEMPDS1722M_sendData;

    LATDbits_LATD3=1;                                   						// set !CS to high level, to enable spi-sensor
    call SPIPacket.SpiSendData(TEMPDS1722M_sendDataPtr,TEMPDS1722M_sendLength);
    LATDbits_LATD3=0;
    return SUCCESS;                                     						// set !CS to low level, to disable spi-sensor
  }

/****************************************************************************************************************/
/* 						StdControl.stop 										    */
/****************************************************************************************************************/

  command result_t StdControl.stop() {
    call SPIControl.stop();
    return SUCCESS;
  }

/****************************************************************************************************************/
/* 						TempADC.getData 										    */
/****************************************************************************************************************/

  async command result_t TempADC.getData() {
    if( TEMPDS1722M_state == TEMPDS1722M_ONE_SHOT_MODE){
      //start conversion
      LATDbits_LATD3=1;                                 						// set !CS to high level, to enable spi-sensor
      call SPIPacket.SpiSendData(TEMPDS1722M_sendDataPtr, TEMPDS1722M_sendLength);				//Send config register again, to start new temperature conversion
      LATDbits_LATD3=0;                                						// set !CS to low level, to disable spi-sensor


    }
     return SUCCESS;
  }

/****************************************************************************************************************/
/* 						TempAdc.getContinuousData								    */
/****************************************************************************************************************/

  async command result_t TempADC.getContinuousData() {
                                                        						// not implemented, because we want to save energy
    return SUCCESS;
  }

/****************************************************************************************************************/
/* 						SPIPacket.writePacketDone								    */
/****************************************************************************************************************/

event void SPIPacket.writePacketDone(uint16_t addr, uint8_t _length, uint8_t* _data, result_t _result) {

    switch (TEMPDS1722M_state){

       	case TEMPDS1722M_IDLE :                                         			// the first write contains the config-register
       		TEMPDS1722M_state = TEMPDS1722M_ONE_SHOT_MODE;           			// the chip will not send any data, during the first write
          	break;

       	case TEMPDS1722M_ONE_SHOT_MODE:

         	TOSH_mswait(TEMPDS1722M_conversionTime);           					//wait for finished conversion


        	LATDbits_LATD3=1;                      							// set !CS to high level, to enable spi-sensor
         	call SPIPacket.SpiReceiveData(0x01,TEMPDS1722M_receiveData,2);  			// read result of conversion
         	LATDbits_LATD3=0;                      							// set !CS to low level, to disable spi-sensor
     	break;

     	default:
     	break;
    }
return;
}

/****************************************************************************************************************/
/* 						SPIPacket.readPacketDone							          */
/****************************************************************************************************************/

event void SPIPacket.readPacketDone(uint16_t addr, uint8_t _length, uint8_t* _data, result_t _result) {
uint16_t temp_value = 0;

	temp_value = *(_data+1);                             						// write highbyte to temp_value
	temp_value = (temp_value<<8) | (*_data);  							// shift left, write lowbyte to temp_value
	temp_value = (temp_value>>TEMPDS1722M_resultShift);   					// shift 'resultShift' bits right, because data is left assign
	signal TempADC.dataReady(temp_value);                						// signal dataready to Oscilloscope
return;

}


}

