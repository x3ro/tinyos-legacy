// $Id: PIC18F4620SPIM.nc,v 1.1 2005/12/07 18:59:19 hjkoerber Exp $

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
 *          <hj.koerber@hsu-hh.de>
 *          (+49)40-6541-2638/2627
 *  @author Tobias Brennenstuhl
 *	      <tobias.brennenstuhl@hsu-hh.de>
 *
 * $Date: 2005/12/07 18:59:19 $
 * $Revision: 1.1 $
 *
 */

includes pic18f4620mssp;

module PIC18F4620SPIM
{

/************************************************************************************************************/
/* 						provided interfaces									*/
/************************************************************************************************************/

  provides {
    interface StdControl;
    interface PIC18F4620SPI;
    interface SPIPacket;

  }

/************************************************************************************************************/
/* 						used interfaces										*/
/************************************************************************************************************/

  uses {
    interface HPLMSSPControl as MSSPControl;
    interface HPLSPIInterrupt;
  }
}

/************************************************************************************************************/
/* 						Implementation of PIC18F4620SPIM			        			*/
/************************************************************************************************************/


implementation
{

/************************************************************************************************************/
/* 						variables						        				*/
/************************************************************************************************************/

  uint8_t 		PIC18F4620SPIM_mode=1;                      						// Tx-Mode = 1 or Rx-Mode = 2
  uint8_t 		PIC18F4620SPIM_length;
  uint8_t 		PIC18F4620SPIM_addr;
  norace result_t	PIC18F4620SPIM_result;
  uint8_t 		*PIC18F4620SPIM_data;
  uint8_t 		*PIC18F4620SPIM_TxBuf;
  uint8_t 		*PIC18F4620SPIM_RxBuf;
  uint8_t 		PIC18F4620SPIM_RxAddr;
  uint8_t 		PIC18F4620SPIM_TxBufLength;
  uint8_t 		PIC18F4620SPIM_RxBufLength;
  uint8_t 		PIC18F4620SPIM_TxByteCounter;
  uint8_t 		PIC18F4620SPIM_RxByteCounter;
  result_t 		PIC18F4620SPIM_Idle=TRUE;


  pic18f4620_msspmode_t mssp_mode;

/************************************************************************************************************/
/* 						readDone						        				*/
/************************************************************************************************************/

  task void readDone() {

    result_t _result;
    uint8_t _length;
    uint8_t* _data;
    uint16_t _addr;

    _result = PIC18F4620SPIM_result;                                    				// protect variables from manipulation
    _length = PIC18F4620SPIM_length;
    _data = PIC18F4620SPIM_RxBuf;
    _addr = PIC18F4620SPIM_RxBuf[0];
    PIC18F4620SPIM_Idle=TRUE;

    signal SPIPacket.readPacketDone(_addr, _length, _data, _result);   					// signal readPacketDone to SPIPacketM
  }

/************************************************************************************************************/
/* 						writeDone						        				*/
/************************************************************************************************************/

  task void writeDone() {

    result_t _result;
    uint8_t _length;
    uint8_t* _data;
    uint16_t _addr;

    _result = PIC18F4620SPIM_result;                                					// protect variables from manipulation
    _length = PIC18F4620SPIM_length;
    _data = PIC18F4620SPIM_data;
    _addr = PIC18F4620SPIM_addr;
    PIC18F4620SPIM_Idle=TRUE;

    signal SPIPacket.writePacketDone(_addr, _length, _data, _result); 					// signal readPacketDone to SPIPacketM
  }

/************************************************************************************************************/
/* 						StdControl.init						        			*/
/************************************************************************************************************/

  command result_t StdControl.init()
  { return SUCCESS; }

/************************************************************************************************************/
/* 						StdControl.start						        			*/
/************************************************************************************************************/

  command result_t StdControl.start() {

  mssp_mode = call MSSPControl.getMode();
	if (mssp_mode != MSSP_SPI) {                  								// check if we are in SPI-Mode
	    call MSSPControl.setModeSPI();            								// if not, set SPI-Mode

	    return SUCCESS;
      	}
	else return SUCCESS;

  return FAIL;
  }

/************************************************************************************************************/
/* 						StdControl.stop						        			*/
/************************************************************************************************************/

  command result_t StdControl.stop() {
    atomic
    {
        call PIC18F4620SPI.disable();
    }

  return SUCCESS;
  }

/************************************************************************************************************/
/* 						PIC18F4620SPI.enable					        			*/
/************************************************************************************************************/

  async command result_t PIC18F4620SPI.enable() {
    result_t _res = FAIL;
    atomic {	
      if (call MSSPControl.isSPI()) {                								// check if we are in SPI-Mode
	_res = SUCCESS;
      }
      else {
	call MSSPControl.setModeSPI();               								// if not, set SPI-Mode
	_res = SUCCESS;
     }
    }
    return _res;
  }

/************************************************************************************************************/
/* 						PIC18F4620SPI.disable					        			*/
/************************************************************************************************************/

  async command result_t PIC18F4620SPI.disable() {
    result_t _res = FAIL;
    atomic {
      if (call MSSPControl.isSPI()) {                								// check if we are in SPI-Mode
	SSPCON1bits_SSPEN = 0x0;                     								// Disables serial port and configures pins as I/O port pins
	_res = SUCCESS;
      }
    }
    return _res;
  }

/************************************************************************************************************/
/* 						SPIRxIntHandler						        			*/
/************************************************************************************************************/

void SPIRxIntHandler()
{
	uint8_t rx_daten;

if (PIC18F4620SPIM_RxByteCounter == 0)
{
	rx_daten = SSPBUF_register;                   								// this data is useless
	SSPBUF_register=0x01;

	PIC18F4620SPIM_RxByteCounter++;
}
else if(PIC18F4620SPIM_RxByteCounter < PIC18F4620SPIM_RxBufLength)
{												
	PIC18F4620SPIM_RxBuf[PIC18F4620SPIM_RxByteCounter-1] = SSPBUF_register;      			// "-1" for saving data at position "0"
	PIC18F4620SPIM_RxByteCounter++;
	SSPBUF_register=0x02;


}
else
{																
	PIC18F4620SPIM_RxBuf[PIC18F4620SPIM_RxByteCounter-1] = SSPBUF_register;      			// "-1" for saving data at position "1"
	PIE1bits_SSPIE=0x00;
	PIC18F4620SPIM_Idle=1;
	PIC18F4620SPIM_mode=1;
	post readDone();                                                 					// post Task
}
}

/************************************************************************************************************/
/* 						SPITxIntHandler						        			*/
/************************************************************************************************************/

void SPITxIntHandler()
{
	uint8_t rx_daten;

	if(PIC18F4620SPIM_TxByteCounter < PIC18F4620SPIM_TxBufLength)
	{
		rx_daten = SSPBUF_register;                                                   	// dummy read to prevent Write Collision
		SSPBUF_register = PIC18F4620SPIM_TxBuf[PIC18F4620SPIM_TxByteCounter++];     		// write the data to the buffer
	}
	else
	{
		rx_daten = SSPBUF_register;                                                         // dummy read to prevent Write Collision
		PIE1bits_SSPIE=0x00;                                                                // kill MSSP Interrupt enable bit
		PIC18F4620SPIM_Idle=1;                                                          	// Set SPI_MODE to Idle
		post writeDone();                                                                   // post Task
	}
}


/************************************************************************************************************/
/* 						SpiSendData						        				*/
/************************************************************************************************************/

command result_t SPIPacket.SpiSendData (uint8_t *txBuf, uint16_t PIC18F4620SPIM_length)
{
	uint8_t rx_daten;

	if (PIC18F4620SPIM_Idle)
	{
		PIC18F4620SPIM_TxBuf = txBuf;                                                   	// save local variable to global variable
		PIC18F4620SPIM_TxBufLength=PIC18F4620SPIM_length;                               	// save local variable to global variable
		PIC18F4620SPIM_TxByteCounter=0;                                                	// reset ByteCounter
		PIC18F4620SPIM_Idle=FALSE;
	      PIC18F4620SPIM_mode=1;                                                              // Set Mode to Tx-Mode
		rx_daten=SSPBUF_register;

		SSPBUF_register=PIC18F4620SPIM_TxBuf[PIC18F4620SPIM_TxByteCounter++];       		// Write first byte to buffer to start transfer

		return TRUE;
	}
	return FALSE;
}

/************************************************************************************************************/
/* 						SpiReceiveData						        			*/
/************************************************************************************************************/

command void SPIPacket.SpiReceiveData (uint8_t PIC18F4620SPIM_addr, uint8_t *rxBuf, uint8_t PIC18F4620SPIM_length)
{
	uint8_t rx_daten;
	if(PIC18F4620SPIM_Idle)
	{


		PIC18F4620SPIM_RxAddr=PIC18F4620SPIM_addr;                                   		// save local variable to global variable
		PIC18F4620SPIM_RxBuf=rxBuf;                                                  		// save local variable to global variable
		PIC18F4620SPIM_RxBufLength=PIC18F4620SPIM_length;                            		// save local variable to global variable
		PIC18F4620SPIM_RxByteCounter=0;                                              		// reset ByteCounter
		PIC18F4620SPIM_Idle=FALSE;									
                PIC18F4620SPIM_mode=2;                                                       	// Set Mode to Rx-Mode
   		rx_daten=SSPBUF_register;
		SSPBUF_register = PIC18F4620SPIM_RxAddr;                              	   		// Write readAddress to buffer to start transfer



	}
}

/************************************************************************************************************/
/* 						Interrupt-Handler					        				*/
/************************************************************************************************************/

  async event void HPLSPIInterrupt.fired() {
    switch(PIC18F4620SPIM_mode) {                                                            	// state machine to set Tx- or Rx-Mode
    case 1:															// Tx Mode
    	SPITxIntHandler();     										 		// start Tx-Interrupt-Handler
        PIC18F4620SPIM_Idle=TRUE;
        break;

    case 2:															// Rx Mode
        SPIRxIntHandler();    										 	// start Rx-Interrupt-Handler
        PIC18F4620SPIM_Idle=TRUE;
	  break;

    default:
	  break;
    }
    return;
 }

}
