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
 * Receiver part for testing the physical layer
 *
 */


module PhyTestReceiverM
{
   provides interface StdControl;
   uses {
      interface StdControl as PhyControl;
      interface PhyComm;
      interface Leds;
   }
}

implementation
{
	AppPkt dataPkt;    // message to be sent
	uint8_t numRx;     // number of succesfully received pkts
	uint8_t numLenErr; // number of errors in length field 
	uint8_t numErrPkt; // number of received pkts with CRC errors
	uint8_t numStart;  // number of packets that received first byte

   command result_t StdControl.init()
   {
      numRx = 0;
      numLenErr = 0;
      numErrPkt = 0;
      numStart = 0;
      call PhyControl.init();  // initialize physical layer
      call Leds.init();
      return 1;
   }


   command result_t StdControl.start()
   {
      return SUCCESS;
   }
   
   
   command result_t StdControl.stop()
   {
      return SUCCESS;
   }


   event result_t PhyComm.txPktDone(void* msg)
   {
      return SUCCESS;
   }


   event result_t PhyComm.startSymDetected(void* pkt)
   {
      numStart++;
      return SUCCESS;
   }


   event void* PhyComm.rxPktDone(void* data, char error)
   {
      if (data == NULL) {
         numLenErr++;
         return data;
      }
      if (numRx == 0) {
         call Leds.redOff();
         call Leds.yellowOff();
      }
      if (error)
         numErrPkt++;
      else {
         numRx++;
         call Leds.greenToggle();
      }
      if (((AppHeader*)data)->seqNo == TST_NUM_PKTS - 1) {  // got last pkt
         // remember result of this group of packets
         dataPkt.data[0] = numRx; // received pkts without error
         dataPkt.data[1] = numLenErr; // num of errors in length field
         dataPkt.data[2] = numErrPkt; // received pkts w/ CRC errors
         dataPkt.data[3] = numStart; // pkts whose first byte is received
         // turn on LEDs to show result
         call Leds.yellowOn();
         if (numRx == TST_NUM_PKTS) {
            call Leds.redOn();
            call Leds.greenOn();
         }
         numRx = 0;
         numLenErr = 0;
         numErrPkt = 0;
         numStart = 0;
         // report my reception result
         call PhyComm.txPkt(&dataPkt, sizeof(AppPkt));
      }
      return data;
   }

}  // end of implementation

