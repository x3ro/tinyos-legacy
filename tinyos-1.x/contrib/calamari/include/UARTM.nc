// $Id: UARTM.nc,v 1.2 2004/03/11 22:46:55 kaminw Exp $

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
 * Date last modified:  5/27/03
 *
 *  5/27/03    pal      Added atomic sections for safety.
 *
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

//this is a special version on uart that exposes a txDebugByte, which
//allows you to send single bytes for debugging.  useful for debuggin
//radio stack.  use pegtestbedinit.m with PACKETS=0 to see bytes.

includes cqueue;

module UARTM {
  provides {
    interface ByteComm;
    interface StdControl as Control;
    async command result_t txDebugByte(uint8_t data);
  }
  uses {
    interface HPLUART;
  }
}
implementation 
{
  enum{
    BYTE_QUEUE_SIZE=50
      };
  bool state;
  bool debugState;
  cqueue_t m_cq;
  uint8_t m_bytes[BYTE_QUEUE_SIZE];
  
  command result_t Control.init() {
    dbg(DBG_BOOT, "UART initialized\n");
    atomic {
      state = FALSE;
      debugState = FALSE;
    }
    init_cqueue( &m_cq,  BYTE_QUEUE_SIZE);
    return SUCCESS;
  }

  command result_t Control.start() {
    return call HPLUART.init();
  }

  command result_t Control.stop() {
      
    return call HPLUART.stop();
  }
    
  async event result_t HPLUART.get(uint8_t data) {
    // Changed SRM 7.8.02 -- No reason to clear state just because
    // we received some data, I think...

    //    state = FALSE;
    signal ByteComm.rxByteReady(data, FALSE, 0);
    dbg(DBG_UART, "signal: state %d\n", state);
    return SUCCESS;
  }

  task void retransmit(){
    if( is_empty_cqueue( &m_cq ) == FALSE )
      call txDebugByte(m_bytes[m_cq.front]);
  } 

  async event result_t HPLUART.putDone() {
    bool oldState;
    bool oldDebugState;
    
    atomic {
      dbg(DBG_UART, "intr: state %d\n", state);
      oldState = state;
      state = FALSE;
      oldDebugState = debugState;
      debugState= FALSE;
    }
    
    /* Note that the state transition/event signalling is not atomic.
       It is possible, after state has been set to FALSE, that
       someone calls txByte before txDone is signalled. The event
       handler therefore may not be able to transmit. Sharing
       the byte level can be very tricky, unless we assure non-preemptiveness
       or have client ids. The UART implementation is non-preemptive,
       but is not assuredly so. -pal*/
    if (oldState) {
      signal ByteComm.txDone();
      signal ByteComm.txByteReady(TRUE);
    }  
    else if(oldDebugState){
      pop_front_cqueue( &m_cq );
      post retransmit();
    }
    return SUCCESS;
  }

  async command result_t ByteComm.txByte(uint8_t data) {
    bool oldState;
    bool oldDebugState;
    
    dbg(DBG_UART, "UART_write_Byte_inlet %x\n", data);

    atomic {
      oldDebugState = debugState;
    }
    if (oldDebugState) 
      return FAIL;

    atomic {
      oldState = state;
      state = TRUE;
    }
    if (oldState) 
      return FAIL;

    call HPLUART.put(data);

    return SUCCESS;
  }

  async command result_t txDebugByte(uint8_t data) {
    bool oldState;
    bool oldDebugState;

    
    if( is_full_cqueue(&m_cq)  || push_back_cqueue( &m_cq ) == FAIL )
      return FAIL;
    m_bytes[m_cq.back] = data;

    dbg(DBG_UART, "UART_write_Byte_inlet %x\n", data);

    atomic {
      oldState = state;
    }
    if (oldState) 
      return SUCCESS;

    atomic {
      oldDebugState = debugState;
      debugState = TRUE;
    }
    if (oldDebugState) 
      return SUCCESS;

    call HPLUART.put(m_bytes[m_cq.front]);

    return SUCCESS;
  }


}
