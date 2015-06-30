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
 * Author:  Philip Levis
 *
 * This component implements the logger for the simulator.
 *
 */

#include "tos.h"
#include "LOGGER.h"
#include "dbg.h"
#include "eeprom.h"

void event_logger_handle(event_t* event, struct TOS_state* state);
void event_logger_cleanup(event_t* event);
void event_logger_create(event_t* event, int mote, long long time);
     
// Logger states.
#define PHASE      1
#define IDLE       0
#define SEND_CMD   1
#define READ_DATA  2
#define WRITE_DATA 4

/* Parameters for configuring the logger: */
/* The log entry is of size 2 ^ LOG_2_SIZE */

#define LOG_2_SIZE 4
#define LOGGER_DELAY 40000   // 10 milliseconds (40,000 cycles) 
#define LOG_ENTRY_SIZE (1 << LOG_2_SIZE)

/* Maximum number of log entries: 32768 / 16 => 2048 lines*/
#define LOGGER_MAX_LINES (0x8000 >> LOG_2_SIZE)

#define APPEND_ADDR_START 16

#define TOS_FRAME_TYPE LOGGER_obj_frame
TOS_FRAME_BEGIN(LOGGER_obj_frame) {
    char state;
    char *data_buf;
    char data_len;
    int last_line;
    int read_line;
    event_t event;
}
TOS_FRAME_END(LOGGER_obj_frame);

char TOS_COMMAND(READ_LOG) (short line, char * data) {
  if (VAR(state) == IDLE) {
    VAR(data_buf) = data;
    VAR(state) = READ_DATA;
    VAR(data_len) = LOG_ENTRY_SIZE;
    VAR(read_line) = line;
    VAR(event).time = tos_state.tos_time + LOGGER_DELAY;
    TOS_queue_insert_event(&VAR(event));
    return 1;
  }
  else {
    return 0;
  }
}

char TOS_COMMAND(APPEND_LOG) (char *data) {
  return TOS_CALL_COMMAND(WRITE_LOG)((short)VAR(last_line)+1, data);
}


char TOS_COMMAND(WRITE_LOG) (short line, char * data) {
  if (VAR(state)== IDLE) {
    VAR(data_buf) = data;
    VAR(data_len) = LOG_ENTRY_SIZE;
    VAR(last_line) = line;
    VAR(state) = WRITE_DATA;
    VAR(event).time = tos_state.tos_time + LOGGER_DELAY;
    TOS_queue_insert_event(&VAR(event));
    return 1;
  }
  else {
    return 0;
  }
}

char TOS_COMMAND(LOGGER_INIT) (void) {
  VAR(state) = IDLE;
  VAR(last_line) = APPEND_ADDR_START;

  event_logger_create(&VAR(event), NODE_NUM, 0);
  dbg(DBG_BOOT, ("Logger initialized.\n"));
  return 1;
}

char TOS_EVENT(LOGGER_SPI_BYTE_DONE) (unsigned char in) {
  if (VAR(state) == READ_DATA) {
    int rval;
    VAR(state) = IDLE;
    rval = readEEPROM(VAR(data_buf), NODE_NUM, VAR(read_line) * LOG_ENTRY_SIZE, LOG_ENTRY_SIZE);
    if (rval == 0) {
      int i;
      dbg(DBG_LOG, ("LOGGER: Log read of line %i completed.\n", VAR(read_line)));
      dbg_clear(DBG_LOG, ("\t["));
      for (i = 0; i < LOG_ENTRY_SIZE; i++) {
	dbg_clear(DBG_LOG, ("%2hhx", VAR(data_buf)[i]));
      }
      dbg_clear(DBG_LOG, ("]\n"));
    }
    TOS_SIGNAL_EVENT(READ_LOG_DONE) (VAR(data_buf), 1);
  }
  else if (VAR(state) == WRITE_DATA) {
    int rval;
    VAR(state) = IDLE;
    rval = writeEEPROM(VAR(data_buf), NODE_NUM, VAR(last_line) * LOG_ENTRY_SIZE, LOG_ENTRY_SIZE);
    if (rval == 0) {
      int i;
      dbg(DBG_LOG, ( "LOGGER: Log write to line %i completed\n", VAR(last_line)));
      dbg_clear(DBG_LOG, ("\t["));
      for (i = 0; i < LOG_ENTRY_SIZE; i++) {
	dbg_clear(DBG_LOG, ("%2hhx", VAR(data_buf)[i]));
      }
      dbg_clear(DBG_LOG, ("]\n"));
    }
    TOS_SIGNAL_EVENT(APPEND_LOG_DONE)(1);
  }
  else {
    dbg(DBG_LOG | DBG_ERROR, ("LOGGER: Operation completed when unknown operation specified!\n"));
  }
  return 1;
}


void event_logger_handle(event_t* event, struct TOS_state* state) {
  TOS_SIGNAL_EVENT(LOGGER_SPI_BYTE_DONE)(0);
}

void event_logger_cleanup(event_t* event) {
  // Since logger events are statically allocated,
  // we shouldn't deallocate anything; since this function
  // should never be called, we set the fields so they
  // will cause a SEGV if used as is.
  event->time = -1;
  event->handle = 0;
  event->cleanup = 0;
  event->mote = 0xffffffff;
  return;
}

void event_logger_create(event_t* event, int mote, long long time) {
  event->mote = mote;
  event->time = time;
  event->data = NULL;
  event->handle = event_logger_handle;
  event->cleanup = event_logger_cleanup;
  event->pause = 0;
}


