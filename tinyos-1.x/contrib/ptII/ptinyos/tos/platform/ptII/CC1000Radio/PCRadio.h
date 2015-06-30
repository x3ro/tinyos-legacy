// $Id: PCRadio.h,v 1.2 2006/11/10 03:36:28 celaine Exp $

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
#define PCR_DEBUG(_x)

typedef struct {
  TOS_MsgPtr msg;
  int success;
} uart_send_done_data_t;

enum {
  UART_SEND_DELAY = 1600
};

/***************************************************************************/

void NIDO_uart_send_done(TOS_MsgPtr fmsg, result_t fsuccess);

void event_uart_write_create(event_t* uevent, int mote, long long utime, TOS_MsgPtr msg, result_t success);

void event_uart_write_handle(event_t* uevent,
			     struct TOS_state* state) {
  
  // function defined in tos/platform/pc/UARTNoCRCPacketM.nc
  NIDO_uart_send_done((TOS_MsgPtr)((uart_send_done_data_t*)uevent->data)->msg,
		      ((uart_send_done_data_t *)uevent->data)->success);
  
  // set the msg pointer to NULL since it was returned to the application level with the issuing of the interrupt
  ((uart_send_done_data_t*)uevent->data)->msg = NULL;
  event_cleanup(uevent);
  dbg(DBG_UART, "UART: packet transfer complete.\n");
}

void event_uart_write_create(event_t* uevent, int mote, long long utime, TOS_MsgPtr msg, result_t success) {
  uart_send_done_data_t* data = (uart_send_done_data_t*)malloc(sizeof(uart_send_done_data_t));
  dbg(DBG_MEM, "malloc uart send done data event.\n");

  ((uart_send_done_data_t *)data)->msg = msg;
  ((uart_send_done_data_t *)data)->success = success;
  
  uevent->mote = mote;
  uevent->data = data;
  uevent->time = utime;
  uevent->handle = event_uart_write_handle;
  uevent->cleanup = event_total_cleanup;
  uevent->pause = 0;
  uevent->force = 0;
}

void TOSH_uart_send(TOS_MsgPtr msg) 
{
  result_t success;
  event_t* uevent;
  UARTMsgSentEvent ev;
  char buf[1024];
  success = SUCCESS;
  // Send event to GUI
  memcpy(&ev.message, msg, sizeof(ev.message));
  sendTossimEvent(NODE_NUM, AM_UARTMSGSENTEVENT, tos_state.tos_time, &ev);

  // Enqueue write done event
  uevent = (event_t*)malloc(sizeof(event_t));
  event_uart_write_create(uevent, NODE_NUM, tos_state.tos_time + UART_SEND_DELAY, msg, success);
  TOS_queue_insert_event(uevent);
  printTime(buf, 1024);
  // Viptos: _PTII_NODEID is passed to the preprocessor as a macro definition.
  // Viptos: We assume that there is only one node per TOSSIM.
  //dbg(DBG_UART, "Enqueueing uart_send_event at %s for mote %i", buf, NODE_NUM);
  dbg(DBG_UART, "Enqueueing uart_send_event at %s for mote %i", buf, _PTII_NODEID);
}

#include "adjacency_list.c"
#include "rfm_model.c"
#include "packet_sim.c"
