// $Id: HPLUARTC.nc,v 1.1.1.1 2007/11/05 19:10:19 jpolastre Exp $

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


includes HPLConstants;

module HPLUARTC {
  provides interface HPLUART;
}

implementation {
  enum {
    IDLE = 0,
    BUSY = 1
  };

  void event_uart_component_write_create(event_t* uevent, int mote, long long utime);

  uint8_t compState;
  
  async command result_t HPLUART.init() {
    atomic {
      compState = IDLE;
    }
    return SUCCESS;
  }

  async command result_t HPLUART.stop() {
    atomic {
      compState = IDLE;
    }
    return SUCCESS;
  }

 

  async command result_t HPLUART.put(uint8_t data) {
    uint8_t oldState;

    atomic {
      oldState = compState;
      compState = BUSY;
    }
    if (oldState != IDLE) {return FAIL;}
    else {
      event_t* uevent = (event_t*)(malloc(sizeof(event_t)));
      event_uart_component_write_create(uevent, NODE_NUM, tos_state.tos_time + UART_BYTE_TIME);
      TOS_queue_insert_event(uevent);
      
      dbg(DBG_UART, "UART_write_Byte_inlet %x\n", data & 0xff);
    }
    return SUCCESS;
  }

  TOS_INTERRUPT_HANDLER(SIG_UART_TRANS,()) {
    atomic {
      compState = IDLE;
    }
    signal HPLUART.putDone();
  }
  
  void event_uart_component_write_handle(event_t* uevent,
			       struct TOS_state* state) __attribute__ ((C, spontaneous)) {
    
    TOS_ISSUE_INTERRUPT(SIG_UART_TRANS)();
    event_cleanup(uevent);
    dbg(DBG_UART, "UART: Transmit byte complete.\n");
  }
  
  void event_uart_component_write_create(event_t* uevent, int mote, long long utime) {
    uevent->mote = mote;
    uevent->data = 0;
    uevent->time = utime;
    uevent->handle = event_uart_component_write_handle;
    uevent->cleanup = event_total_cleanup;
    uevent->pause = 0;
  }
}
