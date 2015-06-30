/*									tab:4
 * Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye
 * 
 * UART debugging: this component is for sending debugging bytes thru UART
 *   Note: can't be used with any application that uses the UART, e.g. motenic
 *
 */

#ifndef UART_DEBUG
#define UART_DEBUG

#define DBG_BUF_LEN 50
#define ADVANCE(x) x = (((x+1) >= DBG_BUF_LEN) ? 0 : x+1)  // from TXMAN.c
#define UART_IDLE 0
#define UART_BUSY 1

// variables for UART debugging
char UARTState;
char dbgBuf[DBG_BUF_LEN];
uint8_t dbgHead;
uint8_t dbgTail;
uint8_t dbgBufCount;


void uartDebug_init()
{
   UARTState = UART_IDLE;
   dbgBufCount = 0;
   dbgHead = 0;
   dbgTail = 0;
   // initialize UART
   outp(12, UBRR);
   inp(UDR); 
   outp(0xd8,UCR);
   TOSH_SET_UART_RXD0_PIN();
   // suppose global interrupt is enabled
}


void uartDebug_txByte(char byte)
{
   char prev = inp(SREG) & 0x80;
   cli();
   if (UARTState == UART_IDLE) { // send byte if UART is idle 
      UARTState = UART_BUSY;
      if(prev) sei();
      // send byte to UART
      sbi(USR, TXC);
      outp(byte, UDR); 
   } else {  // UART is busy, put byte into buffer
      // if buffer is full, the byte will be dropped silently
      if (dbgBufCount < DBG_BUF_LEN) {
         dbgBuf[dbgTail] = byte;
         ADVANCE(dbgTail);
         dbgBufCount++;
      }
      if(prev) sei();
   }
}


TOSH_INTERRUPT(SIG_UART_TRANS)
{
   // UART is able to send next byte
   // This interrupt handler is using the INTERRUPT macro, in which 
   // the global interrupt is enabled, so the interrupt handler can
   // be interruptted too.
   char byte;
   char prev = inp(SREG) & 0x80;
   cli();
   if(dbgBufCount > 0) {
      byte = dbgBuf[dbgHead];
      ADVANCE(dbgHead);
      dbgBufCount--;
      if(prev) sei();
      // send next byte to UART
      sbi(USR, TXC);
      outp(byte, UDR); 
   } else {
      UARTState = UART_IDLE;
      if(prev) sei();
   }
}

#endif  // UART_DEBUG

