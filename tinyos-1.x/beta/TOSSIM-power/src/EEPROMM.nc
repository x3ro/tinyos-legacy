// $Id: EEPROMM.nc,v 1.1 2004/04/22 01:16:51 shnayder Exp $

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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

includes platform_params;

module EEPROMM
{
  provides {
    interface StdControl;
    interface EEPROMRead;
    interface EEPROMWrite[uint8_t writerId];
  }
  uses interface PowerState;
}
implementation
{
  enum {
    PHASE = 1,
    IDLE = 0,
    SEND_CMD = 1,
    READ_DATA = 2,
    WIDLE = 3,
    WRITE_DATA = 4,
    // FIXME: These next two are specific for the mica2 eeprom and CPUFREQ
    LOGGER_READ_DELAY = 4164, //  for mica2, .56ms
    LOGGER_WRITE_DELAY = 95073,  // 12.9ms
    APPEND_ADDR_START = 16
  };

  char state;
  char *data_buf;
  char data_len;
  int last_line;
  int read_line;
  event_t eeprom_event;
  uint8_t currentWriter;
    
  void event_logger_create(event_t* fevent, int mote, long long ftime);

  command result_t EEPROMRead.read(uint16_t line, uint8_t *buffer) {
    if (state == IDLE) {
      call PowerState.eepromReadStart();
      data_buf = buffer;
      state = READ_DATA;
      data_len = TOS_EEPROM_LINE_SIZE;
      read_line = line;
      eeprom_event.time = tos_state.tos_time + LOGGER_READ_DELAY;
      queue_insert_event(&(tos_state.queue), &eeprom_event);
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t EEPROMWrite.startWrite[uint8_t id]() {
    //    dbg(DBG_USR1, "EEPROMWrite.startWrite()");
    if (state != IDLE)
      return FAIL;
    call PowerState.eepromWriteStart();
    state = WIDLE;
    currentWriter = id;

    return SUCCESS;
  }
  
  command result_t EEPROMWrite.write[uint8_t id](uint16_t line, uint8_t *buffer) {
    if (state != WIDLE || id != currentWriter)
      return FAIL;
    data_buf = buffer;
    data_len = TOS_EEPROM_LINE_SIZE;
    last_line = line;
    state = WRITE_DATA;
    eeprom_event.time = tos_state.tos_time + LOGGER_WRITE_DELAY;
    queue_insert_event(&(tos_state.queue), &eeprom_event);
    return SUCCESS;
  }

  command result_t EEPROMWrite.endWrite[uint8_t id]() {
    if (state != WIDLE || id != currentWriter)
      return FAIL;
    
    state = IDLE;
    call PowerState.eepromWriteStop();
    signal EEPROMWrite.endWriteDone[currentWriter](SUCCESS);
    return SUCCESS;
  }

  default event result_t EEPROMWrite.writeDone[uint8_t id](uint8_t *buffer) {
    return FAIL;
  }

  default event result_t EEPROMWrite.endWriteDone[uint8_t id](result_t result) {
    return FAIL;
  }
  
  command result_t StdControl.init() {
    state = IDLE;
    last_line = APPEND_ADDR_START;
    
    event_logger_create(&eeprom_event, tos_state.current_node, 0);
    dbg(DBG_BOOT, "Logger initialized.\n");
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  result_t logger_spi_byte_done(unsigned char in) {
    if (state == READ_DATA) {
      int rval;
      state = IDLE;
      rval = readEEPROM(data_buf, tos_state.current_node, read_line * TOS_EEPROM_LINE_SIZE, TOS_EEPROM_LINE_SIZE);
      if (rval == 0) {
	int i;
	dbg(DBG_LOG, "LOGGER: Log read of line %i completed.\n", read_line);
	dbg_clear(DBG_LOG, "\t[");
	for (i = 0; i < TOS_EEPROM_LINE_SIZE; i++) {
	  dbg_clear(DBG_LOG, "%2hhx", data_buf[i]);
	}
	dbg_clear(DBG_LOG, "]\n");
      }
      call PowerState.eepromReadStop();
      signal EEPROMRead.readDone(data_buf, SUCCESS);
    }
    else if (state == WRITE_DATA) {
      int rval;
      state = WIDLE;
      rval = writeEEPROM(data_buf, tos_state.current_node, last_line * TOS_EEPROM_LINE_SIZE, TOS_EEPROM_LINE_SIZE);
      if (rval == 0) {
	int i;
	dbg(DBG_LOG,  "LOGGER: Log write to line %i completed\n", last_line);
	dbg_clear(DBG_LOG, "\t[");
	for (i = 0; i < TOS_EEPROM_LINE_SIZE; i++) {
	  dbg_clear(DBG_LOG, "%2hhx", data_buf[i]);
	}
	dbg_clear(DBG_LOG, "]\n");
      }
      call PowerState.eepromWriteStop();
      signal EEPROMWrite.writeDone[currentWriter](data_buf);
    }
    else {
      dbg(DBG_LOG | DBG_ERROR, "LOGGER: Operation completed when unknown operation specified!\n");
    }
    return SUCCESS;
  }
  
  void event_logger_handle(event_t* fevent, struct TOS_state* fstate) {
    logger_spi_byte_done(0);
  }
  
  void event_logger_cleanup(event_t* fevent) {
    // Since logger events are statically allocated,
    // we shouldn't deallocate anything; since this function
    // should never be called, we set the fields so they
    // will cause a SEGV if used as is.
    fevent->time = -1;
    fevent->handle = 0;
    fevent->cleanup = 0;
    fevent->mote = 0xffffffff;
    return;
  }
  
  void event_logger_create(event_t* fevent, int mote, long long ftime) {
    fevent->mote = mote;
    fevent->time = ftime;
    fevent->data = NULL;
    fevent->handle = event_logger_handle;
    fevent->cleanup = event_logger_cleanup;
    fevent->pause = 0;
  }
}




