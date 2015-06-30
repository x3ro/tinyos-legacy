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
 * This module implements the hardware clock with a resolution of 1ms.
 * The hardware counter is running asynchronously with a separate watch
 * crystal (32,768Hz). The counter is free-running, and each tick
 * is 1ms (actually 1000/1024 ms). It is able to maintain a local system time 
 * while enabling CPU deep sleep mode.
 */

module CounterAsyncM
{
  provides {
    interface StdControl;
    interface GetSetU8 as CntrValue;
    interface Cntr8bCompInt as CntrCompInt;
    interface Cntr8bOverInt as CntrOverInt;
  }
  
  // for CPU deep sleep mode
  uses {
    interface PowerManagement;
  }
}

implementation
{

#define SCALE_1ms 3  // clk/32 -- 1000/1024 = 0.9766ms/tick
   
  // counter states
  enum {UNINITIALIZED = 0, 
        INITIALIZED = 1,
        RUNNING = 2, 
        STOPPED = 3};

  uint8_t state = UNINITIALIZED; // counter state


  command result_t StdControl.init()
  {
    // initialize the asynchronous counter
    // running on an external clock (32,768Hz)
    if (state != UNINITIALIZED) return SUCCESS;  // already done
    // set Timer/Counter0 to be asynchronous
    // be aware of different hardware delays in asynchronous mode
    sbi(ASSR, AS0); 
    cbi(TIMSK, TOIE0); // disable overflow interrupt
    cbi(TIMSK, OCIE0); //disable compare match interrupt
#ifndef DISABLE_CPU_SLEEP
    call PowerManagement.enable(); // enable CPU sleep modes
#endif
    state = INITIALIZED;
    return SUCCESS;
  }


  command result_t StdControl.start()
  {
    // start the counter if it is not running
    
    if (state == RUNNING) return SUCCESS;
    if (state == UNINITIALIZED) {
      call StdControl.init();  // initialize first
    }
    // just initialized or being stopped
    outp(SCALE_1ms, TCCR0);  //start and prescale the timer
    outp(0, TCNT0);  // clear counter value
    // wait until writing is done
    // there's a hardware delay when writing to TNT0, TCCR0 and OCR0
    while (bit_is_set(ASSR, TCN0UB) || bit_is_set(ASSR, TCR0UB)) { };
    state = RUNNING;
    return SUCCESS;
  }


  command result_t StdControl.stop()
  {
    // stop the counter.
    // shouldn't be called if need a running local system time!
    
    outp(0, TCCR0);  // stop Timer/Counter0
    state = STOPPED;
    return SUCCESS;
  }
  

  command uint8_t CntrValue.get()
  {
    // return current counter value
    
    return inp(TCNT0);
  }


  command result_t CntrValue.set(uint8_t value)
  {
    // set counter value
    // this counter is designed as free-running once started
    // the counter register TCNT0 should never be reset
    
    return FAIL;
  }


  command void CntrCompInt.enable()
  {
    // enable output compare interrupt
    
    sbi(TIFR, OCF0);  // clear possible pending interrupt
    sbi(TIMSK, OCIE0);
  }


  command void CntrCompInt.disable()
  {
    // disable output compare interrupt
    
    cbi(TIMSK, OCIE0);  //disable output compare interrupt
  }

  
  command uint8_t CntrCompInt.getCompReg()
  {
    // return current value in the output compare register
    
    return inp(OCR0);
  }


  command void CntrCompInt.setCompReg(uint8_t value)
  {
    // set output compare register with specified value
    
    outp(value, OCR0);
    // there is a hardware delay writing to OCR0
    while (bit_is_set(ASSR, OCR0UB)) { };
  }


  TOSH_SIGNAL(SIG_OUTPUT_COMPARE0) {
    // interrupt handler for the output compare match
    // global interrupt is disabled when this handler is called
    
    signal CntrCompInt.fire();
    __nesc_enable_interrupt();
    call PowerManagement.adjustPower();
  }


  // Default signal handler on output compare match interrupt
  default async event void CntrCompInt.fire() { };


  command void CntrOverInt.enable()
  {
    // enable overflow interrupt
    
    sbi(TIFR, TOV0);  // clear possible pending interrupt
    sbi(TIMSK, TOIE0);
  }


  command void CntrOverInt.disable()
  {
    // disable overflow interrupt
    
    cbi(TIMSK, TOIE0);
  }


  TOSH_SIGNAL(SIG_OVERFLOW0) {
    // interrupt handler for counter overflow (every 256 ticks)
    // global interrupt is disabled when this handler is called
    
    signal CntrOverInt.fire();
    __nesc_enable_interrupt();
    call PowerManagement.adjustPower();
  }

  // Default signal handler on output compare match interrupt
  default async event void CntrOverInt.fire() { };
}
