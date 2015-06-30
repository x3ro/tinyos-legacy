/*									tab:4
 *
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
 * Authors:		Jason Hill
 *
 *
 */

#include "tos.h"
#include "UART.h"
#include "dbg.h"
#include "tossim.h"
#include <stdlib.h>

#define TOS_FRAME_TYPE UART_frame
TOS_FRAME_BEGIN(UART_frame) {
        char state;
}
TOS_FRAME_END(UART_frame);


char TOS_COMMAND(UART_PWR)(char data){return 0;}
#ifdef __IOM163
#define UCR UCSRB
#define USR UCSRA
#endif

char TOS_COMMAND(UART_INIT)(){
    outp(12, UBRR);
    inp(UDR); 
    outp(0xd8,UCR);
    sei();
    dbg(DBG_BOOT, ("UART initialized\n"));
    VAR(state) = 0;
    return 1;
}



TOS_SIGNAL_HANDLER(SIG_UART_RECV, (char bitIn)){
  //   sbi(PORTD, 6);
  if(inp(USR) & 0x80){ // Will always be 0 in fullpc: inp() resolves to 1
    VAR(state) = 0;
    TOS_SIGNAL_EVENT(UART_RX_BYTE_READY)(inp(UDR), 0);
   }
  //   cbi(PORTD, 6);
  dbg(DBG_UART, ("signal: state %d, bitIn %d\n", VAR(state), bitIn));
  VAR(state) = 0;
}
//#endif

TOS_INTERRUPT_HANDLER(SIG_UART_TRANS,(char bitIn)){
  //dbg(DBG_UART, ("state %d, bitIn %d, first: %x\n", VAR(state), bitIn, VAR(first)));
  dbg(DBG_UART, ("intr: state %d, bitIn %d\n", VAR(state), bitIn));
  VAR(state) = 0;
  TOS_SIGNAL_EVENT(UART_TX_BYTE_READY)(1);
}
void event_uart_write_create(event_t* event, int mote, long long time);

char TOS_COMMAND(UART_TX_BYTES)(char data){
  event_t* event = (event_t*)(malloc(sizeof(event_t)));
  event_uart_write_create(event, NODE_NUM, tos_state.tos_time + 200);
  TOS_queue_insert_event(event);
  
  if(VAR(state)!= 0) {return 0;}
  else {
    event_t* event = (event_t*)(malloc(sizeof(event_t)));
    event_uart_write_create(event, NODE_NUM, tos_state.tos_time + 200);
    TOS_queue_insert_event(event);
    
    dbg(DBG_UART, ("UART_write_Byte_inlet %x\n", data & 0xff));
    VAR(state) = 1;
    sbi(USR, TXC);
    outp(data, UDR);
  }
  return 1;
}


void event_uart_write_handle(event_t* event,
			    struct TOS_state* state) {
  
  TOS_ISSUE_INTERRUPT(SIG_UART_TRANS)(0);
  event->cleanup(event);
  dbg(DBG_UART, ("UART: Transmit byte complete.\n"));
}

void event_uart_write_create(event_t* event, int mote, long long time) {
  //int time = THIS_NODE.time;
  event->mote = mote;
  event->data = 0;
  event->time = time;
  event->handle = event_uart_write_handle;
  event->cleanup = event_total_cleanup;
  event->pause = 0;
}
