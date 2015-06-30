/**
 * Copyright (c) 2008 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

module ScheduleM {
  provides {
    interface Schedule;
  }
  uses {
    interface SystemTime;
    interface Timer;
  }
}

implementation {

  uint32_t _slotLength;  // in milliseconds
  uint32_t _slotStartTime; // in milliseconds

  command result_t Schedule.start(uint32_t offset, uint32_t slotLength) {
    uint32_t delay;
    call Timer.stop();  // In case it is already running.
    _slotLength = slotLength;
    _slotStartTime = call SystemTime.getCurrentTimeMillis() - offset;
    dbg(DBG_USR1, "SCHEDULE: started at %u ms\n", _slotStartTime);
    delay = _slotLength - offset;
    if (delay < 3) delay = 3;
    call Timer.start(TIMER_ONE_SHOT, delay);
    return SUCCESS;
  }

  command result_t Schedule.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  command uint16_t Schedule.getSlotTime() {
    return call SystemTime.getCurrentTimeMillis() - _slotStartTime;
  }
  
  command uint16_t Schedule.getSlotTimeLeft() {
    uint32_t timeNow = call SystemTime.getCurrentTimeMillis();
    return _slotLength - (timeNow - _slotStartTime);
  }
  
  event result_t Timer.fired() {
    _slotStartTime = call SystemTime.getCurrentTimeMillis();
    dbg(DBG_USR2, "SCHEDULE: slot started at %u ms, jitter = %u ms\n", 
      _slotStartTime, _slotStartTime % _slotLength);
    call Timer.start(TIMER_ONE_SHOT, _slotLength);
    signal Schedule.slotChanged();
    return SUCCESS;
  }

}
