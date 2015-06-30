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
 * Implementation file for TestSounder. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes TestTrioMsg;

module TestSounderM
{
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface StdControl as SounderControl;
    interface Sounder;
    interface StdControl as CommControl;
    interface SendMsg;
    interface ReceiveMsg;
  }
}

implementation
{
  TOS_Msg send_msg;
  TOS_MsgPtr m_received_msg = NULL;
  uint8_t sounder_status = 0;

  command result_t StdControl.init() {
    call CommControl.init();
    call SounderControl.init();
    call Leds.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call CommControl.start();
    call SounderControl.start();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call CommControl.stop();
    call SounderControl.stop();

    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t result) {
    return SUCCESS;
  }

  
  task void processMsgTask() {
    struct TestTrioMsg *pMsg;

    atomic {
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
    case CMD_SOUNDER:
      call Sounder.setStatus(pMsg->subcmd);
      break;
    case CMD_SOUNDER_READ:
      call Sounder.getStatus();
      break;
    }
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    atomic m_received_msg = m;
    post processMsgTask();
    return m;
  }

  task void sounder_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_SOUNDER_READ;
    atomic pMsg->subcmd = sounder_status;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void Sounder.getStatusDone(bool high, result_t result) {
    atomic sounder_status = high;
    post sounder_report_task();
  }

}










