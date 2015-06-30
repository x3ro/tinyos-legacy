// $Id: HPLSTM25PC.nc,v 1.2 2005/07/16 00:20:37 jwhui Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
*/

includes HPLSTM25P;

module HPLSTM25PC {
  provides {
    interface StdControl;
    interface HPLSTM25P;
  }
}

implementation {

  enum {
    S_POWEROFF = 0xfe,
    S_POWERON = 0xff,
  };

  enum {
    WRITE_DELAY = 6000, // 1.5ms
  };

  norace uint8_t state;
  norace uint8_t status;
  norace uint8_t addressBytesLoaded;
  norace uint32_t curAddr;

  norace uint8_t eraseBuf[256];

  norace event_t flash_event;

  void event_flash_create(event_t* fevent, int mote, long long ftime);

  command result_t StdControl.init() {
    state = S_POWERON;
    status = 0;
    addressBytesLoaded = 0;
    curAddr = 0;
    event_flash_create(&flash_event, tos_state.current_node, 0);
    memset(eraseBuf, 0xff, 256);
    dbg(DBG_USR1, "STM25P Initialized.\n");
    return SUCCESS; 
  }

  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }

  async command result_t HPLSTM25P.getBus() { return SUCCESS;  }
  async command result_t HPLSTM25P.releaseBus() { return SUCCESS; }
  async command void HPLSTM25P.beginCmd() {}

  async command void HPLSTM25P.endCmd() {

    if ( state == STM25P_WRSR || state == STM25P_PP
	 || state == STM25P_SE || state == STM25P_BE ) {
      status += WIP;
      flash_event.time = tos_state.tos_time + WRITE_DELAY;
      queue_insert_event(&(tos_state.queue), &flash_event);
    }
    state = S_POWERON;
    addressBytesLoaded = 0;
    curAddr = 0;

  }

  async command void HPLSTM25P.hold() {}
  async command void HPLSTM25P.unhold() {}

  async command void HPLSTM25P.txBuf(void* buf, stm25p_addr_t len) {

    uint8_t* bufByte = (uint8_t*)buf;
    uint32_t i;
    
    if (state == S_POWERON) {
      state = *bufByte++;
      len--;
    }
    
    switch(state) {
    case STM25P_CMD_WREN:
      status |= WEL;
      break;
    case STM25P_CMD_WRDI:
      status &= ~WEL;
      break;
    case STM25P_CMD_RDSR:
      break;
    case STM25P_CMD_WRSR:
      status = (status & WIP) | (*bufByte++ & ~WIP);
      break;
    case STM25P_CMD_READ:
      for ( ; addressBytesLoaded < 3 && len; addressBytesLoaded++, len-- )
	curAddr |= (*bufByte++ & 0xff) << (2-addressBytesLoaded)*8;
      break;
    case STM25P_CMD_FAST_READ:
      break;
    case STM25P_CMD_PP:
      for ( ; addressBytesLoaded < 3 && len; addressBytesLoaded++, len-- )
	curAddr |= (*bufByte++ & 0xff) << (2-addressBytesLoaded)*8;
      if ( status & WEL ) {
	for ( i = 0; i < len; i++, curAddr++ ) {
	  uint8_t tmpBufByte;
	  readEEPROM(&tmpBufByte, tos_state.current_node, curAddr, 1);
	  tmpBufByte &= *bufByte++;
	  writeEEPROM(&tmpBufByte, tos_state.current_node, curAddr, 1);
	}
      }
      break;
    case STM25P_CMD_SE:
      for ( ; addressBytesLoaded < 3 && len; addressBytesLoaded++, len-- )
	curAddr |= (*bufByte++ & 0xff) << (2-addressBytesLoaded)*8;
      curAddr &= 0xff0000;
      if ( status & WEL ) {
	if ( addressBytesLoaded == 3 ) {
	  for ( i = 0; i < STM25P_SECTOR_SIZE; i += 256, curAddr += 256 )
	    writeEEPROM(eraseBuf, tos_state.current_node, curAddr, 256);
	}
      }
      break;
    case STM25P_CMD_BE:
      if ( status & WEL ) {
	for ( i = 0; i < STM25P_FLASH_SIZE; i += 256 )
	  writeEEPROM(eraseBuf, tos_state.current_node, i, 256);
      }
      break;
    case STM25P_CMD_DP:
      break;
    case STM25P_CMD_RES:
      break;
    }

  }

  async command uint16_t HPLSTM25P.rxBuf(void* buf, stm25p_addr_t len, uint16_t crc) {

    uint8_t* bufByte = (uint8_t*)buf;
    uint8_t tmp;
    uint32_t i;

    switch(state) {
    case STM25P_CMD_RDSR:
      *bufByte++ = status;
      break;
    case STM25P_CMD_READ:
      for ( i = 0; i < len; i++, curAddr++ ) {
	readEEPROM(&tmp, tos_state.current_node, curAddr, 1);
	crc = crcByte(crc, tmp);
	if (buf != NULL)
	  *bufByte++ = tmp;
      }
      break;
    case STM25P_CMD_FAST_READ:
      break;
    case STM25P_CMD_RES:
      break;
    default:
      dbg(DBG_USR1, "rxBuf : unexpected command %d\n", state);
    }

    return crc;

  }

  void event_flash_handle(event_t* fevent, struct TOS_state* fstate) {
    status &= ~WIP;
  }

  void event_flash_cleanup(event_t* fevent) {
    // Since logger events are statically allocated,
    // we shouldn't deallocate anything; since this function
    // should never be called, we set the fields so they
    // will cause a SEGV if used as is.
    fevent->time = -1;
    fevent->handle = 0;
    fevent->cleanup = 0;
    fevent->mote = 0xffffffff;
  }

  void event_flash_create(event_t* fevent, int mote, long long ftime) {
    fevent->mote = mote;
    fevent->time = ftime;
    fevent->data = NULL;
    fevent->handle = event_flash_handle;
    fevent->cleanup = event_flash_cleanup;
    fevent->pause = 0;
  }

}
