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
 * Sender part for testing the physical layer
 */

module PhyTestSenderM
{
  provides interface StdControl;
  uses {
    interface StdControl as PhyControl;
    interface PhyPkt;
    interface GetSetU8 as RadioTxPower;
    interface Random;
    interface Leds;
    interface Timer as TxTimer;
    interface GetSetU32 as LocalTime;
  }
}

implementation
{
#include "PhyConst.h"
#if (PHY_MAX_PKT_LEN < TST_MIN_PKT_LEN)
#error PHY_MAX_PKT_LEN must be larger or equal to TST_MIN_PKT_LEN
#endif

   typedef enum {
      FIX_LEN_INTVL,
      VAR_LEN_INTVL,
      FIX_LEN_NO_INTVL,
      VAR_LEN_NO_INTVL,
      STOP
   } TxMode;

  TxMode txMode;
  uint8_t numTx;  // number of transmitted pkts
  uint32_t txStartTime;  // timestamp when tx starts
  uint16_t txDuration;  // number of ticks used in last tx
  uint8_t pktLen;
  AppPkt dataPkt; 		// packet to be sent

  task void sendPkt();

  command result_t StdControl.init()
  {
    call Leds.init();
    call PhyControl.init();  // initialize physical layer
    call Random.init();  // initialize random number generator
#ifdef RADIO_TX_POWER
    call RadioTxPower.set(RADIO_TX_POWER);
#endif
    numTx = 0;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call PhyControl.start();
    // post task to send first packet
    call TxTimer.start(TIMER_ONE_SHOT, TST_PKT_SETUP_TIME);
    //    post sendPkt();
    return SUCCESS;
  }
  
  command result_t StdControl.stop()
  {
    call PhyControl.stop();
    return SUCCESS;
  }
  
  task void sendPkt()
  {
    // construct and send a new message
    
    uint16_t addPreamble;
    
    dataPkt.hdr.seqNo = numTx;  // record sequence number
    dataPkt.data[0] = (uint8_t)(txDuration>>8); // time used in tx last pkt
    dataPkt.data[1] = (uint8_t)(txDuration);
    // select a packet length
#ifdef TST_RANDOM_PKT_LEN
#if (PHY_MAX_PKT_LEN <= TST_MIN_PKT_LEN)
#error PHY_MAX_PKT_LEN must be larger than TST_MIN_PKT_LEN for random pkt length
#endif
    pktLen = (uint8_t)(call Random.rand() % 
            (PHY_MAX_PKT_LEN - TST_MIN_PKT_LEN)) + TST_MIN_PKT_LEN;
#else
    pktLen = (uint8_t)PHY_MAX_PKT_LEN;
#endif
    // add preamble to base preamble
#ifdef TST_ADD_FIXED_PREAMBLE
    addPreamble = (uint16_t)(TST_ADD_FIXED_PREAMBLE);
#else
    addPreamble = call Random.rand() & 0xff; // add random preamble
#endif
    txStartTime = call LocalTime.get();
    call PhyPkt.send(&dataPkt, pktLen, addPreamble);
  }
  
  event result_t TxTimer.fired()
  {
    post sendPkt();
    return SUCCESS;
  }

  event result_t PhyPkt.sendDone(void* msg)
  {
    call Leds.redToggle();
    numTx++;
    txDuration = (uint16_t)(call LocalTime.get() - txStartTime);
    if (numTx < TST_NUM_PKTS) {
#if (TST_PKT_INTERVAL == 0)
      post sendPkt();
#else
      // start timer to schedule next tx
      call TxTimer.start(TIMER_ONE_SHOT, TST_PKT_INTERVAL);
#endif
    } else {  // send all packets
      // turn on LEDs to show final results
      call Leds.redOn();
      call Leds.greenOn();
      call Leds.yellowOff();
    }
    return SUCCESS;
  }
  
  
  event void* PhyPkt.receiveDone(void* data, uint8_t error)
  {
    return data;
  }

}  // end of implementation

