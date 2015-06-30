/*
 * @(#)LOGGER.c
 *
 * "Copyright (c) 2001 and The Regents of the University 
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
 * Author:  Robert Szewczyk
 *
 * $\Id$
 */

#include "tos.h"
#include "LOGGER.h"
#include "dbg.h"
// Logger states.
#define WAITING     0
#define STATUS      1
#define SEND_CMD    2
#define EXEC_CMD    3
#define FAILED      4

#define IDLE        0
#define READ_DATA   1
#define WRITE_DATA  2
#define READ_BUFFER 3

/* Parameters for configuring the logger: */
/* The log entry is of size 2 ^ LOG_2_SIZE */

#define DBG(act) TOS_CALL_COMMAND(LOGGER_LEDS)(led_ ## act)

#define LOG_2_SIZE 4

#define LOG_ENTRY_SIZE (1 << LOG_2_SIZE)

/* Maximum number of log entries: 32768 / 16 => 2048 lines*/
#define LOGGER_MAX_LINES (0x8000 >> LOG_2_SIZE)

#define APPEND_ADDR_START 16
#define NO_LAST_LINE -1

#define TOS_FRAME_TYPE LOGGER_obj_frame
TOS_FRAME_BEGIN(LOGGER_obj_frame) {
    char bufpos;
    int state : 4;
    int phase : 4;
    unsigned char cmdbuf[8];
    char *data_buf;
    char data_ptr;
    char data_len;
    char disable_requested;
    int last_line;
}
TOS_FRAME_END(LOGGER_obj_frame);

void push_address(int line, char * buf) 
{
  *buf++ = (line << LOG_2_SIZE) & 0xff; // byte address, there is 8bytes
				//per page that cannot be
				//accessed. Will use for CRC, etc. 
  *buf++ = (line >> (7 - LOG_2_SIZE)) & 0xfe; //page address
  *buf++ = (line >> (15 - LOG_2_SIZE)) & 0xff; // page address
}

static void complete(char success)
{
  char oldstate = VAR(state);

  VAR(state) = IDLE;
  VAR(phase) = EXEC_CMD;
  switch (oldstate)
    {
    case READ_DATA:
      TOS_SIGNAL_EVENT(READ_LOG_DONE)(VAR(data_buf), success);
      break;
    case WRITE_DATA: case READ_BUFFER:
      VAR(state) = IDLE;
      TOS_SIGNAL_EVENT(APPEND_LOG_DONE)(success);
      break;
    }
}


static void disable_flash(void)
{
  VAR(disable_requested) = 1;
  TOS_CALL_COMMAND(LOGGER_FLASH_DISABLE)();
}

static void enable_flash(void)
{
  CLR_FLASH_SELECT_PIN();
  TOS_CALL_COMMAND(LOGGER_FLASH_ENABLE)();
}

static char request_status(void)
{
  VAR(phase) = WAITING;
  enable_flash();
  if (TOS_CALL_COMMAND(LOGGER_SPI_BYTE)(0xd7))
    return 1;
  else
    {
      VAR(phase) = FAILED;
      disable_flash();
      return 0;
    }
}

char TOS_COMMAND(READ_LOG)(short line, char * data) 
{
  if (VAR(state) == IDLE) 
    {
      VAR(data_buf) = data;
      VAR(state) = READ_DATA;
      VAR(data_len) = LOG_ENTRY_SIZE; 
      VAR(data_ptr) = 0;
      // padding, optional
      // VAR(cmdbuf)[0] = 0;
      // VAR(cmdbuf)[1] = 0;
      // VAR(cmdbuf)[2] = 0;
      // VAR(cmdbuf)[3] = 0;
      push_address(line, &(VAR(cmdbuf)[5]));
      VAR(bufpos) = 7;

      return request_status();
    }
  return 0;
}

char TOS_COMMAND(APPEND_LOG) (char *data) {
    return TOS_CALL_COMMAND(WRITE_LOG)(VAR(last_line) == NO_LAST_LINE ? APPEND_ADDR_START : VAR(last_line) + 1, data);
}

char exec_write() 
{
  push_address(VAR(last_line), &(VAR(cmdbuf)[0]));
  VAR(state) = WRITE_DATA;
  VAR(bufpos) = 2;
  return request_status();
}

char read_buffer() 
{
  push_address(VAR(last_line), &(VAR(cmdbuf)[0]));
  VAR(state) = READ_BUFFER;
  VAR(bufpos) = 2;
  return request_status();
}    

char TOS_COMMAND(WRITE_LOG)(short line, char * data) 
{
  if (VAR(state) == IDLE) 
    {
      short old_last_line = VAR(last_line);
      VAR(last_line) = line;

      VAR(data_buf) = data;
      VAR(data_ptr) = 0;
      VAR(data_len) = LOG_ENTRY_SIZE;
      if ((line >> (8 - LOG_2_SIZE)) != (old_last_line >> (8 - LOG_2_SIZE)))
	return read_buffer();
      else
	return exec_write();
    }
  return 0;
}

char TOS_COMMAND(LOGGER_INIT)(void) 
{
  VAR(disable_requested) = 0;
  VAR(state) = IDLE;
  VAR(phase) = EXEC_CMD;
  VAR(bufpos) = -1;
  VAR(last_line) = NO_LAST_LINE;
  TOS_CALL_COMMAND(LOGGER_SUB_INIT)();
  dbg(DBG_BOOT, ("Logger initialized.\n"));
  return 1;
}

char TOS_EVENT(LOGGER_FLASH_DISABLED)(void)
{
  if (!VAR(disable_requested))
    return 1;
  VAR(disable_requested) = 0;
  SET_FLASH_SELECT_PIN();

  switch (VAR(phase))
    {
    case STATUS:
      request_status(); /* busy wait, effectively */
      break;
    case SEND_CMD:
      {
	/* send the appropriate command */
	unsigned char cmd;

	enable_flash();
	switch (VAR(state))
	  {
	  default:
	    cmd = 0;
	    break;
	  case READ_DATA:
	    cmd = 0xd2;
	    break;
	  case WRITE_DATA:
	    cmd = 0x82;
	    break;
	  case READ_BUFFER:
	    cmd = 0x53;
	    break;
	  }
	TOS_CALL_COMMAND(LOGGER_SPI_BYTE)(cmd);
	break;
      }
    case FAILED:
      break;
    case EXEC_CMD:
      switch (VAR(state)) 
	{
	case IDLE:
	  break;
	case READ_DATA: case WRITE_DATA:
	  complete(1);
	  break;
	case READ_BUFFER:
	  exec_write();
	  break;
	default:
	  VAR(state) = IDLE;
	  break;
	}
      break;
    }
  return 0;
}

char TOS_EVENT(LOGGER_SPI_BYTE_DONE) (unsigned char in) 
{
  dbg(DBG_LOG, ("LOGGER: byte received: %02x, STATE: %02x, CMD COUNT: %d, DATA COUNT: %d \n", in&0xff, VAR(state), VAR(bufpos), VAR(data_ptr)));
    
  switch (VAR(phase))
    {
    case WAITING:
      VAR(phase) = STATUS;
      TOS_CALL_COMMAND(LOGGER_SPI_BYTE)(0);
      break;
    case STATUS:
      if (in & 0x80) /* ready */
	VAR(phase) = SEND_CMD;
      disable_flash();
      break;
    case SEND_CMD:
      TOS_CALL_COMMAND(LOGGER_SPI_BYTE)(VAR(cmdbuf)[(int)VAR(bufpos)]);
      VAR(bufpos)--;
      if (VAR(bufpos) < 0)
	VAR(phase) = EXEC_CMD;
      break;
    case EXEC_CMD:
      switch (VAR(state))
	{
	case READ_DATA:
	  VAR(data_buf)[(int)VAR(data_ptr)++] = in;
	  if (VAR(data_ptr) < VAR(data_len)) 
	    {
	      TOS_CALL_COMMAND(LOGGER_SPI_BYTE)(0);
	      return 1;
	    }
	  break;
	case WRITE_DATA:
	  dbg(DBG_LOG, ( "LOGGER: Byte sent: %02x\n", VAR(data_buf)[VAR(data_ptr)]));
	  if (VAR(data_ptr) < VAR(data_len)) 
	    {
	      TOS_CALL_COMMAND(LOGGER_SPI_BYTE)(VAR(data_buf)[(int)VAR(data_ptr)++]);
	      return 1;
	    }
	  break;
	case READ_BUFFER:
	  break;
	}
      disable_flash();
    }
  return 1;
}

