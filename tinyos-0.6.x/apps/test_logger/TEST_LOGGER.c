/*									tab{4
 *  TEST_LOGGER.c
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 *
 * Authors:  Jason Hill, Alec Woo
 * Date:     Oct., 2001
 *
 * This module is a demonstration of the logging functionality.  It 
 * periodically reads in sensor values.  Once it has a full data packet of
 * sensor readings, it writes the data out to a Log Entry.  The LOGGER
 * componnet automatically appends the entry to the log.  When the log
 * write is complete, the applications sends the same data to the UART.
 *
 * This component also acceps message commands that will cause it to read
 * from the log.  The first two bytes are interpreted a log entry number.  
 * The module reads the values out of the log and then broadcasts them 
 * over the radio.
 * 
 * The log entries are 16 bytes long.  They are stored in the I2C EEPROM
 * which has a capacity of 256 Kbits.  The log start at entry 4.
 *
 */

#include "tos.h"
#include "TEST_LOGGER.h"
#include "dbg.h"

struct log_rec{
	short time;
	short val;
}; // This structure has size 4 bytes

// We only have 16 bytes log entry
typedef struct {
        struct log_rec records[4];
}log_entry;

/* Utility functions */
#define TOS_FRAME_TYPE TEST_LOGGER_frame
TOS_FRAME_BEGIN(TEST_LOGGER_frame) {
  int log_line;
  int reading;
  char count;
  char read_log;
  TOS_Msg msg;  
  TOS_Msg read_msg[2];  
  char read_msg_ptr;
  char msg_pending;
  char read_send_pending;
  log_entry* entries;
}
TOS_FRAME_END(TEST_LOGGER_frame);

/* Initialize the component */
char TOS_COMMAND(TEST_LOGGER_INIT)(){
  VAR(reading) = 0;
  VAR(msg_pending) = 0;
  VAR(read_send_pending) = 0;
  TOS_CALL_COMMAND(TEST_LOGGER_SUB_INIT)();
  TOS_CALL_COMMAND(COMM_INIT)();
  TOS_CALL_COMMAND(LOGGER_CLOCK_INIT)(255, 4);
  TOS_CALL_COMMAND(LOGGER_ADC_INIT)();
  VAR(entries) = (log_entry*)VAR(msg).data;
  dbg(DBG_BOOT, ("TEST_LOGGER initialized\n"));
  VAR(read_msg_ptr) = 0;
  VAR(read_log) = 0;
  return 1;
}


char TOS_COMMAND(TEST_LOGGER_START)(){
  return 1;
}

/* Collect sensor data (port 1) for each clock event */
void TOS_EVENT(TEST_LOGGER_CLOCK_EVENT)(){
  dbg(DBG_USR1, ("getting data\n"));
  TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
  TOS_CALL_COMMAND(LOGGER_ADC_GET_DATA)(1); /* start data reading */
}

/* Finish writing into the LOG */
char TOS_EVENT(TEST_LOGGER_WRITE_LOG_DONE)(char success){
  dbg(DBG_USR1, ("LOG_WRITE_DONE\n"));
  if(VAR(msg_pending) == 0){
    TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
    VAR(msg_pending) = TOS_CALL_COMMAND(COMM_SEND_MSG)(TOS_UART_ADDR,0x06,&VAR(msg));
  }
  return 1;
}

/* Receive message to start dumping the LOG over the radio */
/* The first 2 bytes (little endian) of data in the packet correspond to the
   start log entry of the log dump. */
TOS_MsgPtr TOS_EVENT(TEST_LOGGER_READ_MSG)(TOS_MsgPtr msg){
  char* data = msg->data;
  int log_line = data[1] & 0xff;
  log_line |= data[0] << 8;
  dbg(DBG_USR1, ("LOG_READ_START \n"));
  VAR(log_line) = log_line;
  TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
  TOS_CALL_COMMAND(TEST_LOGGER_READ_LOG)(VAR(log_line),VAR(read_msg)[0].data);
  VAR(read_log) = 0;
  return msg;
}

/* Finish sending the message */
char TOS_EVENT(TEST_LOGGER_MSG_SENT)(TOS_MsgPtr msg){
  if(VAR(msg_pending) == 1 && ((msg == &VAR(msg)))) {
    VAR(msg_pending) = 0;
    dbg(DBG_USR1, ("data buffer free\n"));
  }
  /* If we are dumping the log, keep dumping */
  if((msg == &(VAR(read_msg)[(int)VAR(read_msg_ptr)]))) {
    VAR(read_send_pending) = 0;
    TOS_CALL_COMMAND(TEST_LOGGER_READ_LOG)(++VAR(log_line),VAR(read_msg)[(int)VAR(read_msg_ptr)].data);
    VAR(read_msg_ptr) ^= 1;
    VAR(read_send_pending) = TOS_CALL_COMMAND(COMM_SEND_MSG)(TOS_BCAST_ADDR,0x06,&(VAR(read_msg)[(int)VAR(read_msg_ptr)]));
    dbg(DBG_USR1, ("read buffer free\n"));
  }
  return 0;
}

/* Read from LOGGER is complete */
char TOS_EVENT(TEST_LOGGER_READ_LOG_DONE)(char* data, char success){
  dbg(DBG_USR1, ("LOG_READ_DONE\n"));
  if (VAR(read_log) == 0 && VAR(read_send_pending) == 0){
    VAR(read_log) = 1;
    VAR(log_line)++;
    TOS_CALL_COMMAND(TEST_LOGGER_READ_LOG)(VAR(log_line),VAR(read_msg)[1].data);
    VAR(read_send_pending) = TOS_CALL_COMMAND(COMM_SEND_MSG)(TOS_BCAST_ADDR,0x06,&(VAR(read_msg)[0]));
  }
  return 1;
}


/* ADC data is ready */
char TOS_EVENT(LOGGER_DATA_READY)(short data){
  dbg(DBG_USR1, ("got logger data\n"));
  TOS_CALL_COMMAND(RED_LED_TOGGLE)();
  VAR(entries)->records[(int)VAR(count)].val = data;
  VAR(entries)->records[(int)VAR(count)].time = VAR(reading);
  VAR(count) ++;
  VAR(reading) ++;
  if(VAR(count) >= 3){
    TOS_CALL_COMMAND(TEST_LOGGER_WRITE_LOG)(VAR(msg).data);
    VAR(count) = 0;
  }
  return 1;
}   

