/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "RemoteControl.h"

/**
 * Implementation of the RemoteControl logic for sending messages based on
 * the number of button clicks.
 *
 * @author Joe Polastre <info@moteiv.com>
 */
module RemoteControlP {
  provides {
    interface StdControl; 
  }
  uses {
    interface ButtonAdvanced;
    interface SPSend;
    interface Leds;
  }
}
implementation {

  sp_message_t spmsg;
  TOS_Msg tosmsg;

  bool m_pending;
  uint8_t m_count;

  task void sendMsgTask() {
    remote_msg_t* rmsg = (remote_msg_t*)tosmsg.data;
    if (!m_pending) {
      atomic {
        rmsg->addr = TOS_LOCAL_ADDRESS;
        rmsg->count = m_count;
      }
      if (call SPSend.send(&spmsg, &tosmsg, TOS_BCAST_ADDR, sizeof(remote_msg_t))) {
        call Leds.redOn();
        m_pending = TRUE;
      }
    }
  }

  void sendMsg(uint8_t count) {
    atomic m_count = count;
    post sendMsgTask();
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call ButtonAdvanced.enable();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  async event void ButtonAdvanced.longClick(uint32_t time) {
  }

  async event void ButtonAdvanced.multiClick(uint8_t count) {
    sendMsg(count);
  }

  event void SPSend.sendDone(sp_message_t* msg, sp_message_flags_t flags, sp_error_t error) {
    if (msg == &spmsg) {
      call Leds.redOff();
      m_pending = FALSE;
    }
  }

}
