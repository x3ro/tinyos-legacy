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

#define TOS_FRAME_TYPE UART_frame
TOS_FRAME_BEGIN(UART_frame) {
        char state;
}
TOS_FRAME_END(UART_frame);
#define PWR_OFF 0

//char TOS_COMMAND(UART_PWR)(char data){return 0;}
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

char TOS_COMMAND(UART_PWR) (char state) {
    if (state == PWR_OFF) 
	outp(0x00, UCR);
    else 
	outp(0xd8, UCR);
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

char TOS_COMMAND(UART_TX_BYTES)(char data){
    if(VAR(state)!= 0) {return 0;}

    dbg(DBG_UART, ("UART_write_Byte_inlet %x\n", data & 0xff));
    VAR(state) = 1;
    sbi(USR, TXC);
    outp(data, UDR); 
    return 1;
}

