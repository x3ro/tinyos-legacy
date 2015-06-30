//$Id: GrenadeM.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Implementation for the Grenade timer using X1226 Real Timer Clock. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;

module GrenadeM
{
  provides {
    interface StdControl;
    interface Grenade;
  }
  uses {
    interface X1226;
    interface StdControl as X1226Control;
    interface StdControl as IOSwitch2Control;
    interface IOSwitch as IOSwitch2;
    interface Timer as InitTimer;
  }
}

implementation
{
  enum {
    X1226_ADDR_STATUS  = 0x003f,
    X1226_ADDR_RTC_SEC = 0x0030,
    X1226_ADDR_INT     = 0x0011,
    X1226_ADDR_ALM0_SEC = 0x0000,
  };

  enum {
    STATE_IDLE = 0,
    STATE_INIT_INT0,
    STATE_INIT_INT1,
    STATE_INIT_INT2,
    STATE_INIT_ALM0_SEC0,
    STATE_INIT_ALM0_SEC1,
    STATE_INIT_ALM0_SEC2,
    STATE_ARM_ALM0_SEC0,
    STATE_ARM_ALM0_SEC1,
    STATE_ARM_ALM0_SEC2,
    STATE_ARM_RTC_SEC0,
    STATE_ARM_RTC_SEC1,
    STATE_ARM_RTC_SEC2,
    STATE_ARM_INT0,
    STATE_ARM_INT1,
    STATE_ARM_INT2,
    STATE_ARM_MCU_RESET,
    STATE_ARM_GRENADE_CK0,
    STATE_ARM_GRENADE_CK1,
  };

  enum {
    X1226_INT_FLAG_OFF = 0x00,
    X1226_INT_FLAG_ON  = 0xa0,
    X1226_ALARM_ENABLE = 0x80,
  };

  // Frame variables
  uint8_t state = STATE_IDLE;   /* state of this module */
  uint8_t data[8];
  uint8_t init_data[8];
  int8_t m_interval_hour;
  int8_t m_interval_min;
  int8_t m_interval_sec;

  task void Grenade_init_task();
  task void Grenade_arm_task();

  command result_t StdControl.init() {
    call IOSwitch2Control.init();
    call X1226Control.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IOSwitch2Control.start();
    call X1226Control.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call IOSwitch2Control.stop();
    call X1226Control.stop();
    return SUCCESS;
  }

  command result_t Grenade.Init() {
    post Grenade_init_task();
    return SUCCESS;
  }

  command result_t Grenade.GrenadeArmNow(int8_t interval_hour,
                                         int8_t interval_min,
                                         int8_t interval_sec) 
  {
    atomic {
      m_interval_hour = interval_hour;
      m_interval_min  = interval_min;
      m_interval_sec  = interval_sec;
    }
    post Grenade_arm_task();
    return SUCCESS;
  }

  event result_t InitTimer.fired() {
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_INIT_INT2) {
      atomic state = STATE_INIT_ALM0_SEC0;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x02);
    }
    else if (_state == STATE_ARM_ALM0_SEC2) {
      atomic state = STATE_ARM_RTC_SEC0;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x02);
    }
    else if (_state == STATE_ARM_RTC_SEC2) {
      atomic state = STATE_ARM_INT0;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x02);
    }
    else if (_state == STATE_ARM_INT2) {
      atomic state = STATE_ARM_MCU_RESET;
      call IOSwitch2.setPort0Pin(IOSWITCH2_MCU_RESET, TRUE);
    }
    else if (_state == STATE_ARM_MCU_RESET) {
      atomic state = STATE_ARM_GRENADE_CK0;
      call IOSwitch2.setPort0Pin(IOSWITCH2_GRENADE_CK, FALSE);
    }
    else if (_state == STATE_ARM_GRENADE_CK0) {
      atomic state = STATE_ARM_GRENADE_CK1;
      call IOSwitch2.setPort0Pin(IOSWITCH2_GRENADE_CK, TRUE);
    }

    return SUCCESS;
  }

  task void Grenade_init_task() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      init_data[0] = 0x00;
      init_data[1] = 0x00;
      init_data[2] = 0x00;
      init_data[3] = 0x00;
      init_data[4] = 0x00;
      init_data[5] = 0x00;
      init_data[6] = 0x00;
      init_data[7] = 0x00;

      atomic state = STATE_INIT_INT0;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x02);
    }
  }

  task void Grenade_arm_task() {
    uint8_t _state;
    uint8_t ten_digit, one_digit;
    atomic _state = state;

    if (_state == STATE_IDLE) {
      if (m_interval_hour < 0 || m_interval_hour > 23) return;
      if (m_interval_min  < 0 || m_interval_min  > 59) return;
      if (m_interval_sec  < 0 || m_interval_sec  > 59) return;

      // conversion to BCD format.

      // second
      ten_digit = (m_interval_sec / 10) & 0x07;
      one_digit = (m_interval_sec - ten_digit * 10) & 0x0f;
      data[0] = (ten_digit << 4) | one_digit | X1226_ALARM_ENABLE;

      // minute
      ten_digit = (m_interval_min / 10) & 0x07;
      one_digit = (m_interval_min - ten_digit * 10) & 0x0f;
      data[1] = (ten_digit << 4) | one_digit | X1226_ALARM_ENABLE;

      // hour
      ten_digit = (m_interval_hour / 10) & 0x03;
      one_digit = (m_interval_hour - ten_digit * 10) & 0x0f;
      data[2] = (ten_digit << 4) | one_digit | X1226_ALARM_ENABLE;

      data[3] = 0x00; // Day
      data[4] = 0x00; // Month
      data[5] = 0x00; // Year
      data[6] = 0x00; // Day of the week
      data[7] = 0x00; // Y2K

      atomic state = STATE_ARM_ALM0_SEC0;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x02);
    }
  }

  event void X1226.setRegByteDone(result_t result) { 
    int i;
    uint8_t _state;
    atomic _state = state;

    // clear the interrupt flag. 
    if (_state == STATE_INIT_INT0) {
      atomic state = STATE_INIT_INT1;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x06);
    }
    else if (_state == STATE_INIT_INT1) {
      atomic state = STATE_INIT_INT2;
      call X1226.setRegByte(X1226_ADDR_INT, X1226_INT_FLAG_OFF);
    }
    // clear the alarm 0 register.
    else if (_state == STATE_INIT_INT2) {
      call InitTimer.start(TIMER_ONE_SHOT, 50);
    }
    else if (_state == STATE_INIT_ALM0_SEC0) {
      atomic state = STATE_INIT_ALM0_SEC1;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x06);
    }
    else if (_state == STATE_INIT_ALM0_SEC1) {
      atomic state = STATE_INIT_ALM0_SEC2;
      for (i = 0; i < 8; i++) {
        data[i] = 0x00;
      }
      call X1226.setRegPage(X1226_ADDR_ALM0_SEC, 8, init_data);
    }

    // set the alarm 0 register.
    else if (_state == STATE_ARM_ALM0_SEC0) {
      atomic state = STATE_ARM_ALM0_SEC1;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x06);
    }
    else if (_state == STATE_ARM_ALM0_SEC1) {
      atomic state = STATE_ARM_ALM0_SEC2;
      call X1226.setRegPage(X1226_ADDR_ALM0_SEC, 8, data);
    }

    // clear the clock.
    else if (_state == STATE_ARM_RTC_SEC0) {
      atomic state = STATE_ARM_RTC_SEC1;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x06);
    }
    else if (_state == STATE_ARM_RTC_SEC1) {
      atomic state = STATE_ARM_RTC_SEC2;
      for (i = 0; i < 8; i++) {
        data[i] = 0x00;
      }
      call X1226.setRegPage(X1226_ADDR_RTC_SEC, 8, init_data);
    }

    // set the interrupt flag. 
    else if (_state == STATE_ARM_INT0) {
      atomic state = STATE_ARM_INT1;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x06);
    }
    else if (_state == STATE_ARM_INT1) {
      atomic state = STATE_ARM_INT2;
      call X1226.setRegByte(X1226_ADDR_INT, X1226_INT_FLAG_ON);
    }
    else if (_state == STATE_ARM_INT2) {
      call InitTimer.start(TIMER_ONE_SHOT, 50);
    }
  }

  event void X1226.setRegPageDone(result_t result) { 
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_INIT_ALM0_SEC2) {
      atomic state = STATE_IDLE;
    }
    else if (_state == STATE_ARM_ALM0_SEC2) {
      call InitTimer.start(TIMER_ONE_SHOT, 50);
    }
    else if (_state == STATE_ARM_RTC_SEC2) {
      call InitTimer.start(TIMER_ONE_SHOT, 50);
    }
  }

  event void IOSwitch2.setPortDone(result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_ARM_MCU_RESET) {
      call InitTimer.start(TIMER_ONE_SHOT, 25);
    }
    else if (_state == STATE_ARM_GRENADE_CK0) {
      call InitTimer.start(TIMER_ONE_SHOT, 25);
    }
    else if (_state == STATE_ARM_GRENADE_CK1) {
      atomic state = STATE_IDLE;
    }
  }

  event void X1226.getRegByteDone(uint8_t databyte, result_t result) { }
  event void X1226.getRegPageDone(uint8_t datalen, uint8_t* databytes,
                            result_t result) { }
  event void IOSwitch2.getPortDone(uint16_t _bits, result_t _success) { }

}

