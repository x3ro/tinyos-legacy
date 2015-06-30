// $Id: MDA300EEPROMM.nc,v 1.2 2005/01/08 03:40:50 pipeng Exp $

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
 */
module MDA300EEPROMM
{
  provides {
    interface StdControl;
    interface MDA300EEPROM[uint8_t id];
  }
  uses {
    interface I2C;
    interface StdControl as I2CStdControl;
  }
}

implementation
{

  /* state of the i2c request  */
  enum {IDLE=99,
        I2C_START_COMMAND=1,
        I2C_STOP_COMMAND=2,
        I2C_STOP_COMMAND_SENT=3,
        I2C_SECOND_START=4,
        I2C_SECOND_CONTROL=5,
        I2C_WRITE_CONTROL=10,
        I2C_WRITE_ADDR_HIGH=11,
        I2C_WRITE_ADDR_LOW=12,
        I2C_READ_CONTROL=20,
        I2C_READ_ADDR_HIGH=21,
        I2C_READ_ADDR_LOW=22,
        I2C_WRITE_DATA=30,
        I2C_READ_DATA=40,
	    I2C_READ_DONE=50};

  enum {STOP_FLAG=0x01, /* send stop command at the end of packet? */
        ACK_FLAG =0x02, /* send ack after recv a byte (except for last byte) */
        ACK_END_FLAG=0x04, /* send ack after last byte recv'd */ 
	ADDR_8BITS_FLAG=0x80, // the address is a full 8-bits with no terminating readflag
       };

  /**
   *  bytes to write to the i2c bus 
   */
  char* data;    

  /**
   * length in bytes of the request 
   */
  char length;   

  /**
   * current index of read/write byte 
   */
  char index;    


  /**
   * start address of read/write operation 
   */
  uint16_t address;    

  /** 
   * current state of the i2c request 
   */
  char state;    

  /**
   * destination address 
   */
  char addr;     
  
  /**
   * store flags 
   */
  char flags;    

  /**
   * cache incoming bytes : 32 is the maximum number
   */
  char temp[32]; 


#define INT_ENABLE()  sbi(EIMSK , 4)
#define INT_DISABLE() cbi(EIMSK , 4)

  // wait when triggering the clock
  void wait() {
    asm volatile  ("nop" ::);
    asm volatile  ("nop" ::);
  }

  void waitn(uint16_t n)
  {
  	uint16_t i;
  	for(i=0;i<n;i++)
  	{
  		wait();
  	}
  }

  /**
   * initialize the I2C bus and set initial state
   */
  command result_t StdControl.init() {
    call I2CStdControl.init();
    state = IDLE;
    index = 0;
    address=0;
    return SUCCESS;
  }

  /**
   * start the component 
   **/
  command result_t StdControl.start() {
    call I2CStdControl.start();
    return SUCCESS;
  }

  /**
   * stop the component
   **/
  command result_t StdControl.stop() {
    call I2CStdControl.stop();
    return SUCCESS;
  }

  /**
   * writes a series of bytes out to the I2C bus 
   *
   * @param in_length number of bytes to be written to the bus
   * @param in_data pointer to the data
   * @param in_flags bitmask of flags (see I2CPacket.ti interface)
   *
   * @return returns SUCCESS if the bus is free and the request is accepted.
   */
  command result_t MDA300EEPROM.writePacket[uint8_t id](uint16_t startaddr, char in_length, 
        char* in_data, char in_flags) {
    if (state == IDLE)
    {
      /*  reset variables  */
      addr = id;
      data = in_data;
      index = 0;
      length = in_length;
      flags = in_flags;
      address=startaddr;
    }
    else {
      return FAIL;
    }

    state = I2C_WRITE_CONTROL;
    if (call I2C.sendStart())
    {
      return SUCCESS;
    }
    else
    {
      state = IDLE;
      return FAIL;
    }
  }
  
  /**
   * reads a series of bytes out to the I2C bus 
   *
   * @param in_length number of bytes to be read from the bus
   * @param in_flags bitmask of flags (see I2CPacket.ti interface)
   *
   * @return returns SUCCESS if the bus is free and the request is accepted.
   */
  command result_t MDA300EEPROM.readPacket[uint8_t id](uint16_t startaddr, char in_length, 
						    char in_flags) {
    if (state == IDLE)
    {
       atomic{
          addr = id;
          index = 0;
          length = in_length;
          flags = in_flags;
          address=startaddr;
        }
    }
    else {
      return FAIL;
    }

    state = I2C_READ_CONTROL;
    if (call I2C.sendStart())
    {
      return SUCCESS;
    }
    else
    {
      state = IDLE;
      return FAIL;
    }
  }

  /**
   * reads one byte out to the I2C bus 
   *
   * @param in_flags bitmask of flags (see I2CPacket.ti interface)
   *
   * @return returns SUCCESS if the bus is free and the request is accepted.
   */
  task  void readByte() {
	waitn(4);
    if (state == IDLE)
    {
        state = I2C_READ_CONTROL;
        if (!(call I2C.sendStart()))
        {
          state = IDLE;
        }
    }

  }


  /**
   * notification that the start symbol was sent 
   **/
  event result_t I2C.sendStartDone() {
    waitn(4);
    if(state == I2C_WRITE_CONTROL){
      atomic state = I2C_WRITE_ADDR_HIGH;
      call I2C.write( (flags & ADDR_8BITS_FLAG) ? addr : ((addr << 1) + 0) );
    }
    else if (state == I2C_READ_CONTROL){
      atomic state = I2C_READ_ADDR_HIGH;
      call I2C.write( (flags & ADDR_8BITS_FLAG) ? addr : ((addr << 1) + 0) );
    }
    else if (state == I2C_SECOND_CONTROL){
      state = I2C_READ_DATA; 
      call I2C.write( (flags & ADDR_8BITS_FLAG) ? addr : ((addr << 1) + 1) );
      atomic index++;
    }
    return 1;
  }



  /**
   * notification that the stop symbol was sent 
   **/
  event result_t I2C.sendEndDone() {
    if (state == I2C_STOP_COMMAND_SENT) {
      /* success! */
      waitn(8);
      signal MDA300EEPROM.writePacketDone[addr](SUCCESS);
      state = IDLE;
    }
    else if (state == I2C_READ_DONE) {
        atomic{
            address=(address+1)%0x1fff;
            state = IDLE;
            if (index <= length)
              post readByte();
            else if (index > length)
            {
            	waitn(8);
                atomic{
                    signal MDA300EEPROM.readPacketDone[addr](index-1, temp);
                    state = IDLE;
                }
            }
        }
    }
    return SUCCESS;
  }

  /**
   * notification of a byte sucessfully written to the bus 
   **/
  event result_t I2C.writeDone(bool result) {
    waitn(2);
    if(result == FAIL) {
        atomic{
        	signal MDA300EEPROM.writePacketDone[addr](FAIL);
        	state = IDLE;
        }
    	return FAIL;
    }
    if (state == I2C_WRITE_ADDR_HIGH)
    {
	    atomic state = I2C_WRITE_ADDR_LOW;
        return call I2C.write((address>>8) & 0x1f);
    }
    else if (state == I2C_WRITE_ADDR_LOW)
    {
	    atomic state = I2C_WRITE_DATA;
        return call I2C.write((address & 0xff));
    }
    else if (state == I2C_READ_ADDR_HIGH)
    {
	    atomic state = I2C_READ_ADDR_LOW;
        return call I2C.write((address>>8) & 0x1f);
    }
    else if (state == I2C_READ_ADDR_LOW)
    {
	    atomic state = I2C_SECOND_START;
        return call I2C.write((address & 0xff));
    }
    else if (state == I2C_SECOND_START)
    {
	    atomic state =I2C_SECOND_CONTROL ;
        return call I2C.sendStart();
    }
    else if (state == I2C_READ_DATA)
    {
	    atomic state =I2C_READ_DATA ;
        call I2C.read((flags & ACK_END_FLAG) == ACK_END_FLAG);
    }
    else if ((state == I2C_WRITE_DATA) && (index < length))
    {
        index++;
        if (index == length)
	        state = I2C_STOP_COMMAND;
        return call I2C.write(data[index-1]);
    }
    else if (state == I2C_STOP_COMMAND)
    {
        state = I2C_STOP_COMMAND_SENT;
        if (flags & STOP_FLAG)
            return call I2C.sendEnd();
    	else {
    	    signal MDA300EEPROM.writePacketDone[addr](SUCCESS);
    	    state = IDLE;
            return SUCCESS;
    	}
    }

    return SUCCESS;
  }


  /**
   * read a byte off the bus and add it to the packet 
   **/
  event result_t I2C.readDone(char in_data) {
    atomic{
        temp[index-1] = in_data;
         state = I2C_READ_DONE;
    }
    if (flags & STOP_FLAG)
    {
    	if(index>length)
    	{
	    waitn(4);
	    }
        call I2C.sendEnd();
    }
    else
    {
        atomic{
            address=(address+1)%0x1fff;
            state = IDLE;
            if (index <= length)
              post readByte();
            else if (index > length)
            {
                atomic{
                    state = IDLE;
                    signal MDA300EEPROM.readPacketDone[addr](index-1, temp);
                }
            }
        }
    }
    return SUCCESS;
  }


  default event result_t MDA300EEPROM.readPacketDone[uint8_t id](char in_length, char* in_data) {
    return SUCCESS;
  }

  default event result_t MDA300EEPROM.writePacketDone[uint8_t id](bool result) {
    return SUCCESS;
  }


}

