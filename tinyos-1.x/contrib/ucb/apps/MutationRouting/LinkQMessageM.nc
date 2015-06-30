/*									
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * Author: August Joki <august@berkeley.edu>
 *
 *
 *
 */


module LinkQMessageM {
  provides {
    interface SendMsg[uint8_t am];
    interface ReceiveMsg[uint8_t am];
    interface StdControl;
  }
  uses {
    interface SendMsg as BottomSendMsg[uint8_t am];
    interface ReceiveMsg as BottomRecvMsg[uint8_t am];
  }
}
implementation {
  uint16_t macSeqNo;

  command result_t StdControl.init() {
    macSeqNo = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t SendMsg.send[uint8_t am](uint16_t addr, uint8_t length, TOS_MsgPtr data) {
    macSeqNo++;
    if (am == 127) {
      ((MRMsg*)(data->data))->macSeqNo = macSeqNo;
    }
    else if (am == 128) {
      ((RREQMsg*)(data->data))->macSeqNo = macSeqNo;
    }
    else if (am == 129) {
      ((RREPMsg*)(data->data))->macSeqNo = macSeqNo;
    }
    //dbg(DBG_USR3, "sending with macSeqNo %d\n", macSeqNo);
    return call BottomSendMsg.send[am](addr, length, data);
  }

  event result_t BottomSendMsg.sendDone[uint8_t am](TOS_MsgPtr msg, result_t success) {
    return signal SendMsg.sendDone[am](msg, success);
  }
  
  default event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  event TOS_MsgPtr BottomRecvMsg.receive[uint8_t am](TOS_MsgPtr packet) {
    return signal ReceiveMsg.receive[am](packet);
  }

  default event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr packet) {
    return packet;
  }
}
