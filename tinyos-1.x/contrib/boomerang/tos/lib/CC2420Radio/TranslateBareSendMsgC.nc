/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Translates conventional BareSendMsg interface to link-specific
 * CC2420BareSendMsg interface. 
 * <p>
 * This component is only provided as glue between legacy applications that
 * use RadioCRCPacket and the CC2420 communications driver.  New applications
 * should use SPC instead.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module TranslateBareSendMsgC {
  provides {
    interface BareSendMsg;
  }
  uses {
    interface CC2420BareSendMsg;
  }
}
implementation {
#warning Using old communication interfaces; recommend switch to SP

  command result_t BareSendMsg.send(TOS_MsgPtr msg) {
    return call CC2420BareSendMsg.send(msg);
  }

  event result_t CC2420BareSendMsg.sendDone(TOS_MsgPtr msg, cc2420_error_t success) {
    return signal BareSendMsg.sendDone(msg, success == CC2420_SUCCESS);
  }
}

