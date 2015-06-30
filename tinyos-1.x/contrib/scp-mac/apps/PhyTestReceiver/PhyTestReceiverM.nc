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
 * Authors: Wei Ye
 *
 * Receiver part for testing the physical layer
 */

module PhyTestReceiverM
{
  provides interface StdControl;
  uses {
    interface StdControl as PhyControl;
    interface PhyPkt;
    interface PhyNotify;
    interface Timer as TxTimer;
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
  uint8_t numSeq;    // sequence number for packet
  bool finished;

  command result_t StdControl.init()
  {
    numRx = 0;
    numLenErr = 0;
    numErrPkt = 0;
    numStart = 0;
    numSeq = 0;
    finished = FALSE;
    call Leds.init();
    call PhyControl.init();  // initialize physical layer
    return SUCCESS;
  }
  
  
  command result_t StdControl.start()
  {
    call PhyControl.start();
    return SUCCESS;
  }
  
  
  command result_t StdControl.stop()
  {
    call PhyControl.stop();
    return SUCCESS;
  }
  
  
  event result_t PhyPkt.sendDone(void* msg)
  {
    call Leds.greenToggle();
    return SUCCESS;
  }
  
  
  async event result_t PhyNotify.startSymSent(void* pkt)
  {
    return SUCCESS;
  }
  
  
  async event result_t PhyNotify.startSymDetected(void* pkt, uint8_t bitOffset)
  {
    numStart++;
    return SUCCESS;
  }
  
  
  event void* PhyPkt.receiveDone(void* data, uint8_t error)
  {
    if (call TxTimer.getRemainingTime() == 0) {
      call TxTimer.start(TIMER_REPEAT, TST_REPORT_DELAY);
    } else {
      call TxTimer.setRemainingTime(TST_REPORT_DELAY);
    }
    if (data == NULL) {
      numLenErr++;
      return data;
    }
    if (error)
      numErrPkt++;
    else {
      numRx++;
      if (numRx < TST_NUM_PKTS) {
        call Leds.redToggle();
      } else {
	if (finished == FALSE){
	  finished = TRUE;
	  // turn on all LEDs to show successful Rx of all packets
	  call Leds.greenOff();
	  call Leds.yellowOn();
	  call Leds.redOff();
	}
	else{
	  // Received extra packets after finishing
	  call Leds.redToggle();
	}
      }
    }
    return data;
  }
  
  
  event result_t TxTimer.fired()
  {
    // time to report my results
    
    // remember result of this group of packets
    dataPkt.hdr.seqNo = numSeq++;
    dataPkt.data[0] = numRx; // received pkts without error
    dataPkt.data[1] = numLenErr; // num of errors in length field
    dataPkt.data[2] = numErrPkt; // received pkts w/ CRC errors
    dataPkt.data[3] = numStart; // pkts whose first byte is received
    // report my reception result
    call PhyPkt.send(&dataPkt, sizeof(AppPkt), 0);
    return SUCCESS;
  }

}  // end of implementation

