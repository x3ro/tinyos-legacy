// $Id: SPIPacketM.nc,v 1.1 2005/12/07 18:59:19 hjkoerber Exp $

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
 *	      (+49)40-6541-2638/2627
 *  @author Tobias Brennenstuhl
 *	      <tobias.brennenstuhl@hsu-hh.de>
 *
 * $Date: 2005/12/07 18:59:19 $
 * $Revision: 1.1 $
 *
 */



module SPIPacketM
{

/****************************************************************************************************************/
/* 						provided interfaces									    */
/****************************************************************************************************************/

  provides {
    interface SPIPacket as SPIPacket;
    interface StdControl;
  }

/****************************************************************************************************************/
/* 						used interfaces										    */
/****************************************************************************************************************/

  uses {
    interface SPIPacket as LPacket;
    interface StdControl as LControl;
    interface BusArbitration;
  }
}

/****************************************************************************************************************/
/* 						Implementation of PIC18F4620SPIM			        			    */
/****************************************************************************************************************/

implementation
{

/****************************************************************************************************************/
/* 						StdControl.init						        			    */
/****************************************************************************************************************/

  command result_t StdControl.init() {
    call LControl.init();                           					// link to PIC18F4620_StdControl.init()
    return SUCCESS;
  }

/****************************************************************************************************************/
/* 						StdControl.start										    */
/****************************************************************************************************************/

  command result_t StdControl.start() {
    call LControl.start();                          					// link to PIC18F4620_StdControl.start()
    return SUCCESS;
  }

/****************************************************************************************************************/
/* 						StdControl.stop						        			    */
/****************************************************************************************************************/

  command result_t StdControl.stop() {
    return SUCCESS;
  }

/****************************************************************************************************************/
/* 						SpiReceiveData						        			    */
/****************************************************************************************************************/

  command void SPIPacket.SpiReceiveData(uint8_t _addr, uint8_t *_data, uint8_t _length)
  {

  if (call BusArbitration.getBus() == SUCCESS) {                    		// try to get bus
	if (call LControl.start())                                  		// link to PIC18F4620_StdControl.start()
	call LPacket.SpiReceiveData(_addr, _data, _length);         		// link to PIC18F4620_SPIPacket.ReceiveData()
        return;
	}
  return;
  }

/****************************************************************************************************************/
/* 						readPacketDone						        			    */
/****************************************************************************************************************/

  event void LPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _result)
  {
	call LControl.stop();                                                   // link to PIC18F4620_StdControl.stop()
	call BusArbitration.releaseBus();                           		// release bus
	signal SPIPacket.readPacketDone(_addr, _length, _data, _result);        // link signal to TEMPDS1722M
  }


/****************************************************************************************************************/
/* 						SpiSendData						        				    */
/****************************************************************************************************************/

  command result_t SPIPacket.SpiSendData(uint8_t* _data, uint16_t _length)
  {

  if (call BusArbitration.getBus() == SUCCESS) {                     		// try to get bus
	if (call LControl.start())                                   		// link to PIC18F4620_StdControl.start()
	      return call LPacket.SpiSendData(_data,_length);        		// link to PIC18F4620_SPIPacket.SendData()

	}
  return FAIL;
  }

/****************************************************************************************************************/
/* 						writePacketDone						        			    */
/****************************************************************************************************************/

  event void LPacket.writePacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _result)
  {
	call LControl.stop();                                                   // link to PIC18F4620_StdControl.stop()
	call BusArbitration.releaseBus();                                       // release bus
	signal SPIPacket.writePacketDone(_addr, _length, _data, _result);       // link signal to TEMPDS1722M
  }

  event result_t BusArbitration.busFree()
  { return SUCCESS; }

}

