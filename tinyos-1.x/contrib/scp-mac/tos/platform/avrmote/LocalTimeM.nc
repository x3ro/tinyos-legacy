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
 * Authors:	Wei Ye
 *
 * This timer component has a resolution of 1ms. It is based on the
 * asynchronous counter 0 (8-bit). The timer provides a 32-bit system time
 * as well as normal timer functions. It supports CPU deep sleep mode when
 * there is no scheduled timer events.
 */
 
module LocalTimeM
{
  provides {
    interface StdControl as TimeControl;
    interface GetSetU32 as LocalTime;
    interface TestSignal as TestSigOverflow;
  }
  
  uses {
    interface StdControl as CntrControl;
    interface GetSetU8 as CntrValue;
    interface Cntr8bOverInt as CntrOverInt;
  }
}

implementation
{
  // counter states
  enum {UNINITIALIZED = 0, 
        INITIALIZED = 1,
        RUNNING = 2, 
       };

  uint8_t state = UNINITIALIZED; // counter state
  uint32_t localTime; // local time since boot
  
  command result_t TimeControl.init()
  {
    if (state != UNINITIALIZED) return SUCCESS;  // already done
    localTime = 0;
    // initialize hardware counter
    call CntrControl.init();
    state = INITIALIZED;
    return SUCCESS;
  }
  
  
  command result_t TimeControl.start()
  {
    if (state == RUNNING) return SUCCESS;
    if (state == UNINITIALIZED) {
      call TimeControl.init();  // initialize first
    }
    call CntrOverInt.enable(); // enable overflow interrupt
    call CntrControl.start(); // start counter for local time
    state = RUNNING;
    return SUCCESS;
  }
  
  
  command result_t TimeControl.stop()
  {
    // as a free running counter, should never stop it
    return FAIL;
  }
  
  
  command uint32_t LocalTime.get()
  {
    // get current local time in milliseconds represented as a 32-bit
    // unsigned integer. this function does not update system time, which is
    // only updated at overflow interrupts
    // note that there may be
    // a hardware delay of 1 clock cycle in interrupts
    
    uint32_t currTime;
    uint8_t counterVal;
    atomic {
      counterVal = call CntrValue.get();
      currTime = localTime + counterVal;
      if (bit_is_set(TIFR, TOV0) && (int8_t)counterVal >= 0) {
        // overflow just occured, but has not been handled yet
        currTime += 256;
      }
    }
    return currTime;
  }
  
  
  command result_t LocalTime.set(uint32_t time)
  {
    // set local time in binary milliseconds
    atomic localTime = time;
    return SUCCESS;
  }
  
  
  async event void CntrOverInt.fire()
  {
    // handling the overflow interrupt on the 8-bit, free-running counter
    // only used to update system time
    // global interrupt is disabled when this handler is called
    
    localTime += 256;
    signal TestSigOverflow.received();
  }


  // default handlers for testing the overflow interrupt
  
  default async event void TestSigOverflow.received() { }
}
   
