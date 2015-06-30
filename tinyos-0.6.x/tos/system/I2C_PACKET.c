/*									tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:	        Joe Polastre
 *
 *
 */

#include "tos.h"
#include "I2C_PACKET.h"
#include "dbg.h"

static inline char TOS_EVENT(I2C_PACKET_NULL_FUNC)(char length, char* data){return 1;} 

/* state of the i2c request */
#define IDLE 99
#define I2C_START_COMMAND 1
#define I2C_STOP_COMMAND  2
#define I2C_STOP_COMMAND_SENT 3
#define I2C_WRITE_ADDRESS 10
#define I2C_WRITE_DATA    11
#define I2C_READ_ADDRESS  20
#define I2C_READ_DATA     21
#define I2C_READ_DONE     22

/* bit masks for the flags variable */
#define STOP_FLAG     0x01 /* send stop command at the end of packet? */
#define ACK_FLAG      0x02 /* send ack after recv a byte (except for last byte) */
#define ACK_END_FLAG  0x04 /* send ack after last byte recv'd */

#define TOS_FRAME_TYPE I2C_PACKET_obj_frame
TOS_FRAME_BEGIN(I2C_PACKET_obj_frame) {
        char* data;    /* bytes to write to the i2c bus */
	char length;   /* length in bytes of the request */
	char index;    /* current index of read/write byte */
	char state;    /* current state of the i2c request */
        char addr;     /* destination address */
	char flags;    /* store flags */
	char temp[10]; /* cache incoming bytes */
}
TOS_FRAME_END(I2C_PACKET_obj_frame);

char TOS_COMMAND(I2C_PACKET_INIT)(){
    TOS_CALL_COMMAND(I2C_PACKET_SUB_INIT)();
    VAR(state) = IDLE;
    VAR(index) = 0;

    dbg(DBG_BOOT, ("I2C Packet initialized.\n"));
    return 1;
} 

/* writes a series of bytes out to the I2C bus */
char TOS_COMMAND(I2C_PACKET_WRITE_PACKET)(char addr, char length, char* data, char flags) {
  if (VAR(state) == IDLE)
  {
      /*  reset variables  */
      VAR(addr) = addr;
      VAR(data) = data;
      VAR(index) = 0;
      VAR(length) = length;
      VAR(flags) = flags;
  }
  else {
      return 0;
  }

  VAR(state) = I2C_WRITE_ADDRESS;
  if (TOS_CALL_COMMAND(I2C_PACKET_SEND_START)())
    {
      return 1;
    }
  else
    {
      VAR(state) = IDLE;
      return 0;
    }
}

/* reads a series of bytes from the I2C bus */
char TOS_COMMAND(I2C_PACKET_READ_PACKET)(char addr, char length, char flags) {
  if (VAR(state) == IDLE)
  {
      VAR(addr) = addr;
      VAR(index) = 0;
      VAR(length) = length;
      VAR(flags) = flags;
  }
  else {
      return 0;
  }

  VAR(state) = I2C_READ_ADDRESS;
  if (TOS_CALL_COMMAND(I2C_PACKET_SEND_START)())
    {
      return 1;
    }
  else
    {
      VAR(state) = IDLE;
      return 0;
    }
}

/* notification that the start symbol was sent */
char TOS_EVENT(I2C_PACKET_SEND_START_DONE)(){
    if(VAR(state) == I2C_WRITE_ADDRESS){
      VAR(state) = I2C_WRITE_DATA;
      TOS_CALL_COMMAND(I2C_PACKET_WRITE_BYTE)((VAR(addr) << 1) + 0);
    }
    else if (VAR(state) == I2C_READ_ADDRESS){
      VAR(state) = I2C_READ_DATA;
      TOS_CALL_COMMAND(I2C_PACKET_WRITE_BYTE)((VAR(addr) << 1) + 1);
      VAR(index)++;
    }
    return 1;
}

/* notification that the stop symbol was sent */
char TOS_EVENT(I2C_PACKET_SEND_END_DONE)(){
    if(VAR(state) == I2C_STOP_COMMAND_SENT){
      /* success! */
      VAR(state) = IDLE;
      TOS_SIGNAL_EVENT(I2C_PACKET_WRITE_PACKET_DONE)(1);
    }
    else if (VAR(state) == I2C_READ_DONE) {
        VAR(state) = IDLE;
	TOS_SIGNAL_EVENT(I2C_PACKET_READ_PACKET_DONE)(VAR(length), VAR(data));
	//I2C_PACKET_DISPATCH(VAR(length), VAR(data));
    }
    return 1;
}

/* notification of a byte sucessfully written to the bus */
char TOS_EVENT(I2C_PACKET_WRITE_BYTE_DONE)(char success){
    if(success == 0){
	dbg(DBG_ERROR, ("I2C_PACKET_WRITE_FAILED"));
	VAR(state) = IDLE;
	TOS_SIGNAL_EVENT(I2C_PACKET_WRITE_PACKET_DONE)(0);
	return 0;
    }
    if ((VAR(state) == I2C_WRITE_DATA) && (VAR(index) < VAR(length)))
    {
        VAR(index++);
        if (VAR(index) == VAR(length))
	    VAR(state) = I2C_STOP_COMMAND;
        return TOS_CALL_COMMAND(I2C_PACKET_WRITE_BYTE)(VAR(data)[VAR(index)-1]);
    }
    else if (VAR(state) == I2C_STOP_COMMAND)
    {
        VAR(state) = I2C_STOP_COMMAND_SENT;
        if ((VAR(flags) & STOP_FLAG) == 1)
            return TOS_CALL_COMMAND(I2C_PACKET_SEND_END)();
	else {
	    VAR(state)= IDLE;
	    return TOS_SIGNAL_EVENT(I2C_PACKET_WRITE_PACKET_DONE)(1);
	}
    }
    else if (VAR(state) == I2C_READ_DATA)
    {
      if (VAR(index) == VAR(length))
      {
	return TOS_CALL_COMMAND(I2C_PACKET_READ_BYTE)((VAR(flags) & ACK_END_FLAG));
      }
      else if (VAR(index) < VAR(length))
	return TOS_CALL_COMMAND(I2C_PACKET_READ_BYTE)((VAR(flags) & ACK_FLAG));
    }

    return 1;
}

/* read a byte off the bus and add it to the packet */
char TOS_EVENT(I2C_PACKET_READ_BYTE_DONE)(char data, char success)
{
  if (success == 0)
  {
	dbg(DBG_ERROR, ("I2C_PACKET_READ_FAILED"));
	VAR(state) = IDLE;
	TOS_SIGNAL_EVENT(I2C_PACKET_READ_PACKET_DONE)(0, VAR(data));
	return 0;
  }
  VAR(temp)[VAR(index)-1] = data;
  VAR(index)++;
  if (VAR(index) == VAR(length))
      TOS_CALL_COMMAND(I2C_PACKET_READ_BYTE)((VAR(flags) & ACK_END_FLAG));
  else if (VAR(index) < VAR(length))
      TOS_CALL_COMMAND(I2C_PACKET_READ_BYTE)((VAR(flags) & ACK_FLAG));
  else if (VAR(index) > VAR(length))
  {
    VAR(state) = I2C_READ_DONE;
    VAR(data) = (char*)(&VAR(temp));
    if (VAR(flags) & STOP_FLAG)
      TOS_CALL_COMMAND(I2C_PACKET_SEND_END)();
    else
    {
        VAR(state) = IDLE;
	TOS_SIGNAL_EVENT(I2C_PACKET_READ_PACKET_DONE)(VAR(length), VAR(data));
	//I2C_PACKET_DISPATCH(VAR(length), VAR(data));
    }
  }
  return 1;
}

#include "I2C_PACKET.dispatch"

  
