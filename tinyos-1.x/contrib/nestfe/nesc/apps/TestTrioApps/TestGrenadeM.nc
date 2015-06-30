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
 * Implementation file for TestGrenade <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

module TestGrenadeM
{
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as X1226Control;
    interface X1226;
    interface Leds;
    interface Grenade;
    interface StdControl as GrenadeControl;
    interface StdControl as CommControl;
    interface SendMsg;
    interface ReceiveMsg;
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
    STATE_READ_STATUS,
    STATE_READ_INT,
    STATE_READ_RTC_SEC,
    STATE_READ_ALM0_SEC,
    STATE_SET_INT0,
    STATE_SET_INT1,
    STATE_SET_INT2,
    STATE_SET_RTC_SEC0,
    STATE_SET_RTC_SEC1,
    STATE_SET_RTC_SEC2,
    STATE_SET_ALM0_SEC0,
    STATE_SET_ALM0_SEC1,
    STATE_SET_ALM0_SEC2,
  };

  uint8_t state = STATE_IDLE;   /* state of this module */
  uint8_t data[8];
  uint8_t port0_bits = 0x00; // initial port data
  uint8_t port1_bits = 0x00;
  TOS_Msg send_msg;
  TOS_MsgPtr m_received_msg = NULL;

  task void X1226_INT_set_task();
  task void X1226_RTC_set_task();
  task void X1226_ALM0_set_task();

  task void X1226_STAT_read_task();
  task void X1226_INT_read_task();
  task void X1226_RTC_read_task();
  task void X1226_ALM0_read_task();

  command result_t StdControl.init() {
    call CommControl.init();
    call X1226Control.init();
    call GrenadeControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call CommControl.start();
    call X1226Control.start();
    call GrenadeControl.start();
    call Leds.set(0x07);
    call InitTimer.start(TIMER_ONE_SHOT, 200);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call CommControl.stop();
    call X1226Control.stop();
    call GrenadeControl.stop();
    return SUCCESS;
  }

  event result_t InitTimer.fired() {
    call Leds.set(0);
    call Grenade.Init();
    return SUCCESS;
  }

  task void X1226_STAT_read_task() {
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_STATUS;
      call X1226.getRegByte(X1226_ADDR_STATUS);
    }
  }

  task void X1226_INT_read_task() {
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_INT;
      call X1226.getRegByte(X1226_ADDR_INT);
    }
  }

  task void X1226_RTC_read_task() {
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_RTC_SEC;
      call X1226.getRegPage(X1226_ADDR_RTC_SEC, 8);
    }
  }

  task void X1226_ALM0_read_task() {
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_ALM0_SEC;
      call X1226.getRegPage(X1226_ADDR_ALM0_SEC, 8);
    }
  }

  task void X1226_RTC_set_task() {
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_IDLE) {
      atomic state = STATE_SET_RTC_SEC0;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x02);
    }
  }

  task void X1226_ALM0_set_task() {
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_IDLE) {
      atomic state = STATE_SET_ALM0_SEC0;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x02);
    }
  }

  task void X1226_INT_set_task() {
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_IDLE) {
      atomic state = STATE_SET_INT0;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x02);
    }
  }

  task void stat_send_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_X1226_READ;
    pMsg->subcmd = SUBCMD_X1226_STATUS;
    pMsg->arg[0] = data[0];

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void int_send_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_X1226_READ;
    pMsg->subcmd = SUBCMD_X1226_INT;
    pMsg->arg[0] = data[0];

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void alarm0_send_task() {
    int i;
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_X1226_READ;
    pMsg->subcmd = SUBCMD_X1226_ALM0;
    for (i = 0; i < 8; i++) {
      pMsg->arg[i] = data[i];
    }
    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void clock_send_task() {
    int i;
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_X1226_READ;
    pMsg->subcmd = SUBCMD_X1226_RTC;
    for (i = 0; i < 8; i++) {
      pMsg->arg[i] = data[i];
    }
    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void processMsgTask() {
    int i;
    uint8_t _state;
    struct TestTrioMsg *pMsg;

    atomic {
      _state = _state;
      pMsg = (TestTrioMsg *) m_received_msg->data;
    }

    switch (pMsg->cmd) {
    case CMD_REDLED:
      if (pMsg->subcmd == 0) call Leds.redOff();
      else call Leds.redOn();
      break;
    case CMD_GREENLED:
      if (pMsg->subcmd == 0) call Leds.greenOff();
      else call Leds.greenOn();
      break;
    case CMD_YELLOWLED:
      if (pMsg->subcmd == 0) call Leds.yellowOff();
      else call Leds.yellowOn();
      break;
    case CMD_GRENADE:
      if (pMsg->subcmd == SUBCMD_ON) {
        call Grenade.GrenadeArmNow(0,0,30);  // reset after 30 sec.
      }
      else if (pMsg->subcmd == SUBCMD_OFF) {
        call Grenade.Init(); 
      }
      break;
    case CMD_X1226_READ:
      if (pMsg->subcmd == SUBCMD_X1226_STATUS) {
        post X1226_STAT_read_task();
      }
      else if (pMsg->subcmd == SUBCMD_X1226_INT) {
        post X1226_INT_read_task();
      }
      else if (pMsg->subcmd == SUBCMD_X1226_RTC) {
        post X1226_RTC_read_task();
      }
      else if (pMsg->subcmd == SUBCMD_X1226_ALM0) {
        post X1226_ALM0_read_task();
      }
      break;  
    case CMD_X1226_SET:
      if (pMsg->subcmd == SUBCMD_X1226_INT) {
        data[0] = pMsg->arg[0];
        post X1226_INT_set_task();
      }
      else if (pMsg->subcmd == SUBCMD_X1226_RTC) {
        for (i = 0; i < 8; i++) {
          data[i] = pMsg->arg[i];
        }
        post X1226_RTC_set_task();
      }
      else if (pMsg->subcmd == SUBCMD_X1226_ALM0) {
        for (i = 0; i < 8; i++) {
          data[i] = pMsg->arg[i];
        }
        post X1226_ALM0_set_task();
      }
      break;
    }
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    atomic m_received_msg = m;
    post processMsgTask();
    return m;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t result) {
    return SUCCESS;
  }

  event void X1226.setRegByteDone(result_t result) { 
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_SET_INT0) {
      atomic state = STATE_SET_INT1;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x06);
    }
    else if (_state == STATE_SET_INT1) {
      atomic state = STATE_SET_INT2;
      call X1226.setRegByte(X1226_ADDR_INT, data[0]);
    }
    else if (_state == STATE_SET_INT2) {
      atomic state = STATE_IDLE;
    }
    else if (_state == STATE_SET_RTC_SEC0) {
      atomic state = STATE_SET_RTC_SEC1;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x06);
    }
    else if (_state == STATE_SET_RTC_SEC1) {
      atomic state = STATE_SET_RTC_SEC2;
      call X1226.setRegPage(X1226_ADDR_RTC_SEC, 8, data);
    }
    else if (_state == STATE_SET_ALM0_SEC0) {
      atomic state = STATE_SET_ALM0_SEC1;
      call X1226.setRegByte(X1226_ADDR_STATUS, 0x06);
    }
    else if (_state == STATE_SET_ALM0_SEC1) {
      atomic state = STATE_SET_ALM0_SEC2;
      call X1226.setRegPage(X1226_ADDR_ALM0_SEC, 8, data);
    }
  }

  event void X1226.setRegPageDone(result_t result) { 
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_SET_RTC_SEC2) {
      atomic state = STATE_IDLE;
    }
    else if (_state == STATE_SET_ALM0_SEC2) {
      atomic state = STATE_IDLE;
    }
  }

  event void X1226.getRegByteDone(uint8_t databyte, result_t result) { 
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_READ_STATUS) {
      atomic state = STATE_IDLE;
      data[0] = databyte;
      post stat_send_task();
    }
    else if (_state == STATE_READ_INT) {
      atomic state = STATE_IDLE;
      data[0] = databyte;
      post int_send_task();
    }
  }

  event void X1226.getRegPageDone(uint8_t datalen, uint8_t* databytes,
                            result_t result) { 
    int i;
    uint8_t _state;
    atomic _state = state;

    if (_state == STATE_READ_RTC_SEC) {
      atomic state = STATE_IDLE;
      for (i = 0; i < datalen; i++) {   
        data[i] = databytes[i];
      }
      post clock_send_task();
    }
    else if (_state == STATE_READ_ALM0_SEC) {
      atomic state = STATE_IDLE;
      for (i = 0; i < datalen; i++) {
        data[i] = databytes[i];
      }
      post alarm0_send_task();
    }
  }

  task void data_send2_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_IOSWITCH2_READ;
    pMsg->subcmd = 2;
    pMsg->arg[0] = port0_bits;
    pMsg->arg[1] = port1_bits;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }



}










