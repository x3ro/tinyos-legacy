/*
 * Copyright (C) 2003-2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors:	Wei Ye
 * 
 * UART debugging: this component is for sending debugging bytes thru UART
 *   Note: can't be used with any application that uses the UART, e.g. motenic
 *
 * There are two known problems:
 * 1) Initializing UART (e.g., for UART debugging) may cause a node fail to 
 *   start or stop running when it's not connected with a serial board/cable.
 *   The reason needs to be checked further.
 * 2) When HPLPowerManagement is enabled, the bytes sent to the UART could 
 *   be corrupted. To be safe, HPLPowerManagement should be disabled when
 *   using UART debug.
 */


module UartDebugM
{
  provides {
    command void UartDebugInit();
    command void UartDebugTxByte(uint8_t byte);
  }
}

implementation
{

#define DBG_BUF_LEN 50
#define ADVANCE(x) x = (((x+1) >= DBG_BUF_LEN) ? 0 : x+1)  // from TXMAN.c
#define UART_IDLE 0
#define UART_BUSY 1

  // variables for UART debugging
  uint8_t UARTState;
  uint8_t dbgBuf[DBG_BUF_LEN];
  uint8_t dbgHead;
  uint8_t dbgTail;
  uint8_t dbgBufCount;


  command void UartDebugInit()
  {
    // initialize UART
   
    UARTState = UART_IDLE;
    dbgBufCount = 0;
    dbgHead = 0;
    dbgTail = 0;
    // initialize UART
    // Set 57.6 KBps
    outp(0,UBRR0H); 
//    outp(15, UBRR0L);  // 57600 at 7.3728MHz
    outp(16, UBRR0L);  // 57600 at 8MHz

    // Set UART double speed
    outp((1<<U2X),UCSR0A);

    // Set frame format: 8 data-bits, 1 stop-bit
    outp(((1 << UCSZ1) | (1 << UCSZ0)) , UCSR0C);

    // Enable reciever and transmitter and their interrupts
    outp(((1 << RXCIE) | (1 << TXCIE) | (1 << RXEN) | (1 << TXEN)) ,UCSR0B);
    // suppose global interrupt is enabled
  }


  command void UartDebugTxByte(uint8_t byte)
  {
    char prev = inp(SREG) & 0x80;
    cli();
    if (UARTState == UART_IDLE) { // send byte if UART is idle 
      UARTState = UART_BUSY;
      if(prev) sei();
      // send byte to UART
      outp(byte, UDR0); 
      sbi(UCSR0A, TXC);
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


  TOSH_INTERRUPT(SIG_UART0_TRANS)
  {
    // UART is able to send next byte
    // This interrupt handler is using the INTERRUPT macro, in which 
    // the global interrupt is enabled, so the interrupt handler can
    // be interruptted too.
    uint8_t byte;
    char prev = inp(SREG) & 0x80;
    cli();
    if(dbgBufCount > 0) {
      byte = dbgBuf[dbgHead];
      ADVANCE(dbgHead);
      dbgBufCount--;
      if(prev) sei();
      // send next byte to UART
      outp(byte, UDR0); 
      sbi(UCSR0A, TXC);
    } else {
      UARTState = UART_IDLE;
      if(prev) sei();
    }
  }


  TOSH_INTERRUPT(SIG_UART0_RECV)
  {
  }

}
