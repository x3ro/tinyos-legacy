// $Id: I2CPacketM.nc,v 1.5 2004/09/27 23:07:25 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/*
 *
 * Authors:		Joe Polastre, Rob Szewczyk
 * Date last modified:  7/18/02
 *
 */

/**
 * Provides functionality for writing and reading packets on the I2C bus
 * @author Joe Polastre
 * @author Rob Szewczyk
 * @author David Gay
 */
module I2CPacketM
{
  provides {
    interface StdControl;
    interface I2CPacket[uint8_t id];
  }
  uses {
    interface I2C;
    interface StdControl as I2CStdControl;
    interface Leds;
  }
}
implementation
{
  /* state of the i2c request  */
  enum {
    IDLE,
    I2C_WRITE,
    I2C_READ
  };

  norace char* data;		// data to read or write
  norace uint8_t length;	// request length
  norace uint8_t index;		// current index of read/write byte 
  norace uint8_t state;		// current state of the i2c request 
  norace uint8_t addr;		// destination address 
  norace uint8_t flags;		// request flags

  /**
   * initialize the I2C bus and set initial state
   */
  command result_t StdControl.init() {
    call I2CStdControl.init();
    state = IDLE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call I2CStdControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call I2CStdControl.stop();
    return SUCCESS;
  }

  result_t request(uint8_t newState, uint8_t id, char *in_data,
		   uint8_t in_length, uint8_t in_flags) {

    if (state != IDLE)
      return FAIL;

    state = newState;
    addr = id;
    data = in_data;
    index = 0;
    length = in_length;
    flags = in_flags;

    call I2C.sendStart();
    return SUCCESS;
  }

  command result_t I2CPacket.writePacket[uint8_t id](char *in_data, 
        uint8_t in_length, uint8_t in_flags) {
    return request(I2C_WRITE, id, in_data, in_length, in_flags);
  }
  
  command result_t I2CPacket.readPacket[uint8_t id](char *in_data, 
      uint8_t in_length, uint8_t in_flags) {
    return request(I2C_READ, id, in_data, in_length, in_flags);
  }

  /**
   * notification that the start symbol was sent 
   **/
  async event result_t I2C.sendStartDone() {
    call I2C.write(flags & I2C_ADDR_8BITS_FLAG ? addr :
		   (addr << 1) + (state == I2C_READ));
    return SUCCESS;
  }

  void readNextByte() {
    bool ack = index == length ? flags & I2C_ACK_END_FLAG != 0 :
      flags & I2C_NOACK_FLAG == 0;

    call I2C.read(ack);
  }

  task void completeTask() {
    uint8_t oldState = state;
    uint8_t outcome = flags;

    state = IDLE;
    switch (oldState)
      {
      case I2C_WRITE:
	signal I2CPacket.writePacketDone[addr](data, index, outcome);
	break;
      case I2C_READ:
	signal I2CPacket.readPacketDone[addr](data, index, outcome);
	break;
      }
  }

  void complete(result_t outcome) {
    // Hack: we save the outcome in flags (save mem)
    flags = outcome;
    call I2C.sendEnd();
  }

  async event result_t I2C.sendEndDone() {
    post completeTask();
    return SUCCESS;
  }

  /**
   * notification of a byte written to the bus 
   **/
  async event result_t I2C.writeDone(bool result, bool lostArbitration) {
    if (lostArbitration)
      {
	index = 0;
	call I2C.sendStart(); // retry ASAP
      }
    else if (!result) 
      complete(FAIL);
    else
      switch (state)
	{
	case I2C_READ:
	  readNextByte();
	  break;
	case I2C_WRITE:
	  if (index < length)
	    call I2C.write(data[index++]);
	  else
	    complete(SUCCESS);
	  break;
	}
    return SUCCESS;
  }

  /**
   * byte read off the bus, add it to the packet 
   **/
  async event result_t I2C.readDone(char in_data) {
    data[index++] = in_data;

    if (index < length)
      readNextByte();
    else
      complete(SUCCESS);
    return SUCCESS;
  }

  default event result_t I2CPacket.readPacketDone[uint8_t id]
    (char* in_data, uint8_t len, result_t result) {
    return SUCCESS;
  }

  default event result_t I2CPacket.writePacketDone[uint8_t id]
        (char* in_data, uint8_t len, result_t result) {
    return SUCCESS;
  }

}
