//$Id: WakeupCommM.nc,v 1.3 2005/06/14 18:19:35 gtolle Exp $

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
 */

/**
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

module WakeupCommM {
  provides interface SendMsg as WakeupSendMsg[uint8_t id];
  uses interface SendMsg[uint8_t id];
  uses interface Timer;
}
implementation {

  bool busy;
  uint8_t sendCount;
  uint16_t address;
  uint8_t length;
  uint8_t id;
  TOS_MsgPtr msg;
  
  command result_t WakeupSendMsg.send[uint8_t _id](uint16_t _address, 
						   uint8_t _length, 
						   TOS_MsgPtr _msg) {

    if (busy)
      return FAIL;
    busy = TRUE;
    sendCount = 0;

    address = _address; length = _length; msg = _msg; id = _id;
    return call Timer.start(TIMER_REPEAT, WAKE_LENGTH);
  }

  event result_t Timer.fired() {

    if (sendCount >= WAKE_PERIOD / WAKE_LENGTH) {
      call Timer.stop();
      signal WakeupSendMsg.sendDone[id](msg, SUCCESS);
      busy = FALSE;
      return SUCCESS;
    }

    call SendMsg.send[id](address, length, msg);
    return SUCCESS;
  }

  event result_t SendMsg.sendDone[uint8_t _id](TOS_MsgPtr _msg, 
					       result_t _success) {
    if (msg == _msg && _success) {
      sendCount++;
    }
    return SUCCESS;
  }

  default event result_t WakeupSendMsg.sendDone[uint8_t _id](TOS_MsgPtr _msg, 
							     result_t _success) {
    return SUCCESS;
  }
}
