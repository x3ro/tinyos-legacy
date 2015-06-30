// $Id: SnooperM.nc,v 1.4 2003/09/20 01:44:41 weiyeisi Exp $

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
 * Date created: 1/21/2003
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

/**
 * @author Wei Ye
 */


module SnooperM
{
   provides interface StdControl;
   uses {
      interface StdControl as PhyControl;
      interface PhyComm;
      interface PhyStreamByte;
      interface StdControl as UARTControl;
      interface ByteComm as UARTComm;
   }
}

implementation
{
#ifndef TOS_UART_ADDR
#define TOS_UART_ADDR 0x7e
#endif

#ifdef SHOW_ERR_CHECK
	uint8_t txCount;
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


   event result_t PhyComm.startSymDetected(void* pkt)
   {
#ifdef SHOW_ERR_CHECK
      txCount = 0;
#endif
      call UARTComm.txByte(TOS_UART_ADDR);
      return SUCCESS;
   }


   event result_t PhyStreamByte.rxByteDone(char data)
   {
      // suppose UART speed is faster than data arrival rate from radio
      // send byte in tx buffter
#ifdef SHOW_ERR_CHECK
      if (txCount == 0) {
         txCount = 1;
         data++;
      }
#endif
      if (flagUart == 0) {
         flagUart = 1;
         call UARTComm.txByte(data);
      } else if (flagBuf == 0) {
         bufByte = data;
         flagBuf = 1;
      }
      
      return SUCCESS;
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
   

   event void* PhyComm.rxPktDone(void* packet, char error)
   {
      if (packet == 0) {
         call UARTComm.txByte(0); // stop snoop.c
#ifdef SHOW_ERR_CHECK
      } else {
         call UARTComm.txByte(error);
#endif
      }
      return packet;
   }


   event result_t PhyComm.txPktDone(void* packet)
   {
      return SUCCESS;
   }

}  // end of implementation

