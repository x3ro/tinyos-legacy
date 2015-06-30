// $Id: UARTNoCRCPacketM.nc,v 1.1 2005/04/19 01:16:13 celaine Exp $

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
 * Authors:		Jason Hill, David Gay, Philip Levis, Nelson Lee
 * Date last modified:  6/25/02
 *
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Nelson Lee
 */

includes PCRadio;

module UARTNoCRCPacketM {
  provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
  }
}
implementation {

  command result_t Control.init() {
    dbg(DBG_BOOT, "UART initialized.\n");
    return SUCCESS;
  }

  command result_t Control.start() {
    dbg(DBG_BOOT, "UART started.\n");
    return SUCCESS;
  }

  command result_t Control.stop() {
    dbg(DBG_BOOT, "UART stopped.\n");
    return SUCCESS;
  }
  
  command result_t Send.send(TOS_MsgPtr msg) {
    msg->crc = 1; /* Fake out the CRC as passed. */
    
    TOSH_uart_send(msg);
    //sendTossimEvent(TOS_LOCAL_ADDRESS, AM_UARTMSGSENTEVENT, tos_state.tos_time, (char*) msg);
    return SUCCESS;
  }
  
  default event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;    
  }
  
  void NIDO_uart_send_done(TOS_MsgPtr fmsg, result_t fsuccess) __attribute__ ((C, spontaneous)) {
    signal Send.sendDone(fmsg, fsuccess);
  }

}
