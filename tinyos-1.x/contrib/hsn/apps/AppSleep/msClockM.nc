/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:     Nithya Ramanathan
 *
 */
                                                                                
includes TosTime;

module msClockM {
  provides {
    interface StdControl;
    interface SysTime;
  }
  uses {
    interface Timer;
    interface SysTime as SysClock;
  }
}

implementation
{
  // Interval can't be higher than 64 cuz we only grab
  // 16 bits for usec offset!
  uint32_t INTERVAL = 511;
  uint32_t partial_time;
  uint32_t last_usec_offset;

  command result_t StdControl.init() {
    atomic {
      partial_time=0; 
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, INTERVAL);
    return SUCCESS ;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  async command uint16_t SysTime.getTime16() {
    uint32_t t;

    t = call SysTime.getTime32();
    return (uint16_t) t;
  }

  async command uint32_t SysTime.getTime32() {
    uint32_t current_usec = call SysClock.getTime32();
    uint32_t usec_offset = (current_usec - last_usec_offset)/1000;
    uint32_t t;

    atomic {
      t  = partial_time + usec_offset;
    }
    return t;
  }

  async command uint32_t SysTime.castTime16(uint16_t n) {
    return 0;
  }

  event result_t Timer.fired() {
    uint32_t new_time;
    atomic {
      new_time = call SysClock.getTime32();
      partial_time += (new_time - last_usec_offset)/1000;
      last_usec_offset = new_time;
    }
    return SUCCESS;
  }
}
