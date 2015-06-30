// $Id: PhyTestSenderM.nc,v 1.4 2005/09/27 22:26:41 weiyeisi Exp $

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
 * Sender part for testing the physical layer
 *
 */

//includes PhyTestMsg;


/**
 * @author Wei Ye
 */

module PhyTestSenderM
{
   provides interface StdControl;
   uses {
      interface StdControl as PhyControl;
      interface PhyComm;
      interface Random;
      interface Leds;
      interface Clock;
   }
}

implementation
{
   typedef enum {
      FIX_LEN_INTVL,
      VAR_LEN_INTVL,
      FIX_LEN_NO_INTVL,
      VAR_LEN_NO_INTVL,
      STOP
   } TxMode;

   TxMode txMode;
   uint16_t tickCount;  // counter on clock ticks
   uint8_t numTx;  // number of transmitted pkts
   uint8_t txTickCount;  // counter for number of ticks used in tx
   uint8_t numTxTicks;  // number of ticks used in last tx
   uint8_t pktLen;
   uint8_t baseLen;
   uint8_t mask;
   char validLen;
   AppPkt dataPkt; 		// packet to be sent

   task void sendPkt()
   {
      // construct a new message
      dataPkt.hdr.seqNo = numTx;  // record sequence number
      dataPkt.data[0] = numTxTicks; // time used in tx last pkt
      // select a packet length
      if (txMode == FIX_LEN_INTVL || txMode == FIX_LEN_NO_INTVL) {
         pktLen = (uint8_t)PHY_MAX_PKT_LEN;
      } else {
         pktLen = baseLen + 
            (uint8_t)(call Random.rand() & mask);
      }
      txTickCount = 0;  // start counting time to send the pkt
      call PhyComm.txPkt(&dataPkt, pktLen);
   }


   command result_t StdControl.init()
   {
      call PhyControl.init();  // initialize physical layer
      call Random.init();  // initialize random number generator
      call Leds.init();
      numTx = 0;
      numTxTicks = 0;
      pktLen = (uint8_t)PHY_MAX_PKT_LEN;
      if (pktLen < 14 || pktLen > 250) {
         validLen = 0;
      } else {
         validLen = 1;
         if (pktLen >= 14 && pktLen < 22) {
            mask = 0x7;
         } else if (pktLen >= 22 && pktLen < 38) {
            mask = 0xf;
         } else if (pktLen >= 38 && pktLen < 70) {
            mask = 0x1f;
         } else if (pktLen >= 70 && pktLen < 134) {
            mask = 0x3f;
         } else if (pktLen >= 134 && pktLen <= 250) {
            mask = 0x7f;
         }
         baseLen = pktLen - mask;
      }
      return SUCCESS;
   }


   command result_t StdControl.start()
   {
      // initialize and start clock
      txMode = FIX_LEN_INTVL;
      tickCount = TST_PKT_INTERVAL;
      if (validLen) {
         call Clock.setRate(TOS_I1000PS, TOS_S1000PS); // 1ms resolution
      }
      return SUCCESS;
   }


   command result_t StdControl.stop()
   {
      return SUCCESS;
   }


   async event result_t Clock.fire()
   {
      // clock event handler
      txTickCount++;  // measure of transmission time
      if (tickCount > 0) {
         tickCount--;
         if (tickCount == 0) {
            post sendPkt();
         }
      }
      return SUCCESS;
   }	


   event result_t PhyComm.txPktDone(void* msg)
   {
      call Leds.redToggle();
      numTx++;
      numTxTicks = txTickCount + 1;
      if (numTx < TST_NUM_PKTS) {
         if (txMode == FIX_LEN_NO_INTVL || txMode == VAR_LEN_NO_INTVL) {
            // send next pkt without delay
            post sendPkt();
         } else {
            tickCount = TST_PKT_INTERVAL;  // start timer for next packet
         }
      } else {
         txMode++;
         if (txMode == STOP) { // test is done
            // turn on LEDs to show final results
            call Leds.redOn();
            call Leds.greenOn();
            call Leds.yellowOn();
            return SUCCESS;
         } else {
            numTx = 0;
            tickCount = TST_GRP_INTERVAL;  // start timer for next group
         }
      }
      return SUCCESS;
   }

   
   event result_t PhyComm.startSymDetected(void* pkt)
   {
      return SUCCESS;
   }
   
   
   event void* PhyComm.rxPktDone(void* data, char error)
   {
      return data;
   }

}  // end of implementation

