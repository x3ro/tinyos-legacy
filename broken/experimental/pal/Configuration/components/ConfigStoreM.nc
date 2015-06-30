/*									tab:4
 *
 *
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2003 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 * Authors:		Philip Levis
 * Date last modified:  6/19/03
 */

/**
 * Provides access to a small piece (256 bytes) of non-volatile storage
 * that can be written atomically. The storage is in a fixed place
 * on the non-volatile storage. It persists across application boots
 * and application installations.
 */

includes ConfigStore;

module ConfigStoreM {
  provides {
    interface ConfigStoreControl;
    interface ConfigWrite;
    interface ConfigRead;
  }
  uses {
    interface Leds;
  }
}

implementation {

  enum {
    CONFIG_CLEAN, // Nothing has been written, can't read
    CONFIG_READY, // Valid data
    CONFIG_STORE_COOKIE = 0x02251977,
  };
  
  uint8_t regionSize;
  uint8_t regionIndex;
  uint8_t state;
  bool busy;
  uint8_t* buffer;
  uint32_t cookieStorage;
  
  task void initTask();
  task void writeTask();
  task void writeDoneTask();
  task void cookieWriteTask();
  task void readTask();
  
  command result_t ConfigStoreControl.init(uint8_t size) {
    busy = TRUE;
    state = CONFIG_CLEAN;
    regionSize = size;
    regionIndex = 0;
    call Leds.init();
    call Leds.greenOn();
    post initTask();
    dbg(DBG_USR2|DBG_BOOT, "ConfigStore: Initializing.\n");
    return SUCCESS;
  }

  command result_t ConfigWrite.write(uint8_t* buf, uint8_t len) {
    if (busy || !eeprom_is_ready() || len != regionSize) {
      call Leds.yellowToggle();
      return FAIL;
    }
    else {
      int i;
      busy = TRUE;
      if (state == CONFIG_CLEAN) {
	post cookieWriteTask();
      }
      regionIndex = 0;
      buffer = buf;
      post writeTask();
      return SUCCESS;
    }
  }

  command result_t ConfigRead.read(uint8_t* buf, uint8_t len) {
    if (busy || !eeprom_is_ready() ||
	len != regionSize || state == CONFIG_CLEAN) {
      return FAIL;
    }
    else {
      buffer = buf;
      post readTask();
    }
  }

  task void readTask() {
    call Leds.redOn();
    eeprom_read_block(buffer, sizeof(cookieStorage), regionSize);
    call Leds.redOff();
    signal ConfigRead.readSuccess(buffer);
  }

  task void initTask() {
    eeprom_read_block(&cookieStorage, 0, 4);
    busy = FALSE;
    if (cookieStorage != CONFIG_STORE_COOKIE) {
      signal ConfigStoreControl.initialisedNoData();
    }
    else {
      state = CONFIG_READY;
      signal ConfigStoreControl.initialisedDataPresent();
    }
  }

  task void writeDoneTask() {
    state = CONFIG_READY;
    busy = FALSE;
    signal ConfigWrite.writeSuccess(buffer);
  }
  
  task void writeTask() {
    uint8_t writeEnd = regionIndex + 4; // Write 4 bytes
    writeEnd = (writeEnd>regionSize)? regionSize:writeEnd; // But not too much
    for (; regionIndex < writeEnd; regionIndex++) {
      eeprom_wb(regionIndex + sizeof(cookieStorage), buffer[regionIndex]);
    }
    if (writeEnd == regionSize) {
      post writeDoneTask();
    }
    else {
      post writeTask();
    }
  }
  
  task void cookieWriteTask() {
    uint8_t i;
    uint8_t* valBuf = (uint8_t*)&cookieStorage;
    cookieStorage = CONFIG_STORE_COOKIE;
    for (i = 0; i < sizeof(cookieStorage); i++) {
      eeprom_wb(i, valBuf[i]);
    }
  }
  
}
    
