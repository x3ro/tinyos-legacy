
// $Id: PIC18F4620_Test_I2CM.nc,v 1.1 2005/05/02 07:37:48 hjkoerber Exp $

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

/* @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 * 
 * $Date: 2005/05/02 07:37:48 $
 * $Revision: 1.1 $
 */


module PIC18F4620_Test_I2CM 
{
  provides interface StdControl;
  uses {
    interface Timer;
    interface I2CPacket as I2CPacket;
    interface StdControl as I2CControl;
  }
}
implementation
{

  // here we define the packet

  uint8_t *send_data_ptr;
  uint8_t *receive_data_ptr;
  uint8_t send_data;
  uint8_t receive_data;
  uint16_t I2C_ADDRESS;
  uint8_t length;

  /**
   * Used to initialize this component.
   */
 command result_t StdControl.init() {


  // here we initialize the packet to be send over uart (address and one command byte[data=0])
 
  I2C_ADDRESS = 0x004d; // address of the  PICDEM PLUS 2 DEMO BOARD temperature I2C sensor
  length =1;
  send_data=0;
  receive_data=0;
  send_data_ptr= &send_data;
  receive_data_ptr=&receive_data;

  call I2CControl.init();

  return SUCCESS;
 }
  /**
   * Starts the components.
   */

  command result_t StdControl.start() {
    call I2CControl.start();
    call Timer.start(TIMER_REPEAT, 1000);
    return SUCCESS;
  }

  /**
   * Stops the components.
   */

  command result_t StdControl.stop() {
    call I2CControl.stop();
    call Timer.stop();

    return SUCCESS;
  }

  /**
   * Signalled when the timer expires
   */
  event result_t Timer.fired() {
    return call I2CPacket.writePacket(I2C_ADDRESS, length, send_data_ptr);
  }

  /**
   * Signalled when an I2CPacket has been written
   */ 

  event void I2CPacket.writePacketDone(uint16_t addr, uint8_t _length, uint8_t* _data, result_t _result) {
    if(_result = SUCCESS){
      call  I2CPacket.readPacket(I2C_ADDRESS, length, receive_data_ptr);
    }
    return;
  }

 /**
   * Signalled when an I2CPacket has been read
   */ 
 
 event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _result) {
    uint8_t* received_data =0;
    received_data = _data;
    return;
  }
}

