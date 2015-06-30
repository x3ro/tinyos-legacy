/*
 * Copyright (C) 2005 the University of Southern California.
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
 * This application tests the local system time (since a node boots) with
 * CPU sleep enabled
 */

module LocalTimeTestM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as PhyControl;
    interface StdControl as TimeControl;
    interface GetSetU32 as LocalTime;
    interface TestSignal as TestSigOverflow;
    interface PhyPkt;
    interface Leds;
  }
}

implementation
{
  uint32_t overflowCount;
  uint32_t localTime;
  uint32_t lastTxTime;
  AppPkt pkt;  // packet buffer
  
  
  command result_t StdControl.init()
  {
     overflowCount = 0;
     call Leds.init();
     call PhyControl.init();
     call TimeControl.init();
     return SUCCESS;
  }
  
  
  command result_t StdControl.start()
  {
    call Leds.yellowOn();
    call Leds.redOn();
    call TimeControl.start();  // start local time counter
#ifdef DISABLE_PKT_TX
    call PhyControl.stop();
#else
    call PhyControl.start();  // start radio
#endif
    return SUCCESS;
  }
  
  
  command result_t StdControl.stop()
  {
    call PhyControl.stop();  // stop radio
    call TimeControl.start();  // start local time counter
    return SUCCESS;
  }
  
  
  async event void TestSigOverflow.received()
  {
    // event handler for counter overflow interrupts
    // the period between each overflow interrupt is 250ms
    overflowCount++;
    if ((overflowCount & 3) == 0) { // one second has 4 interrupts
      localTime = call LocalTime.get();
      call Leds.yellowToggle();

      // test with red led
      if (overflowCount << 8 == localTime) {
        call Leds.redToggle();
      }
#ifndef DISABLE_PKT_TX
      // show time values with packets
      pkt.lastTxTime = lastTxTime;
      pkt.currentTime = localTime;
      call PhyPkt.send(&pkt, sizeof(pkt), 0);
#endif
    }
  }

  
  event result_t PhyPkt.sendDone(void* packet)
  {
    lastTxTime = call LocalTime.get();
    return SUCCESS;
  }
  
  event void* PhyPkt.receiveDone(void* packet, uint8_t error)
  {
    return packet;
  }
  
}


