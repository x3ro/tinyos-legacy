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
/* Authors: Wei Ye
 *
 * listens all packets and pass them to UART.
 * Support different packet length. The first byte must be packet length.
 * Data is received from radio and passed to UART on a per byte basis.
 * If on a per packet basis, a short packet following a long packet may get
 * lost because the UART can't finish sending the long packet when the short
 * packet arrives.
 * The contents of each packet can be displayed by snoope.c at tools/.
 *
 */

module SnooperM
{
   provides interface StdControl;
   uses {
      interface StdControl as PhyControl;
      interface PhyNotify;
      interface PhyStreamByte;
      interface PhyPkt;
      interface StdControl as UARTControl;
      interface ByteComm as UARTComm;
   }
}

implementation
{
#ifdef PLATFORM_MICAZ
#error "This snooper does not work on MicaZ. Use ../SnooperZ/ instead."
#endif

#ifndef TOS_UART_ADDR
#define TOS_UART_ADDR 0x7e
#endif

  char bufByte;
  char flagUart;
  char flagBuf;


   command result_t StdControl.init()
   {
      flagUart = 0;
      flagBuf = 0;
      call UARTControl.init();
      call PhyControl.init();
      return SUCCESS;
   }


   command result_t StdControl.start()
   {
      call UARTControl.start();
      call PhyControl.start();
      return SUCCESS;
   }


   command result_t StdControl.stop()
   {
      call UARTControl.stop();
      call PhyControl.stop();
      return SUCCESS;
   }


   async event result_t PhyNotify.startSymSent(void* pkt)
   {
      return SUCCESS;
   }


   async event result_t PhyNotify.startSymDetected(void* pkt, uint8_t bitOffset)
   {
      call UARTComm.txByte(TOS_UART_ADDR);
      return SUCCESS;
   }


   event void PhyStreamByte.rxDone(uint8_t* buffer, uint8_t byteIdx)
   {
      // suppose UART speed is faster than data arrival rate from radio
      // send byte in tx buffter
      uint8_t data;
      data = *(buffer + byteIdx);
      if (flagUart == 0) {
         flagUart = 1;
         call UARTComm.txByte(data);
      } else if (flagBuf == 0) {
         bufByte = data;
         flagBuf = 1;
      }
   }


   async event result_t UARTComm.txByteReady(bool success)
   {
      if (flagBuf == 1) {
         call UARTComm.txByte(bufByte);
         flagBuf = 0;
      } else {
         flagUart = 0;
      }
      return SUCCESS; 
   }


   async event result_t UARTComm.rxByteReady(uint8_t data, bool error, uint16_t strength)
   {
      return SUCCESS;
   }


   async event result_t UARTComm.txDone()
   {
      return SUCCESS;
   }
   

   event void* PhyPkt.receiveDone(void* packet, uint8_t error)
   {
      if (packet == 0) {
         call UARTComm.txByte(0); // stop snoop.c
      }
      return packet;
   }


   event result_t PhyPkt.sendDone(void* packet)
   {
      return SUCCESS;
   }

}  // end of implementation

