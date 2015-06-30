//$Id: DrainGroupManagerM.nc,v 1.1 2005/10/27 21:31:04 gtolle Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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

module DrainGroupManagerM {
  provides interface DrainGroup;

  uses interface Intercept;
  uses interface Send;
  uses interface SendMsg;
  uses interface GroupManager;
}
implementation {
  TOS_Msg msgBuf;
  bool msgBufBusy;

  command result_t DrainGroup.joinGroup(uint16_t group, uint16_t timeout) {
    uint16_t length;

    DrainGroupRegisterMsg *regMsg = (DrainGroupRegisterMsg*) 
      call Send.getBuffer(&msgBuf, &length);

    if (msgBufBusy) { return FAIL; }
    msgBufBusy = TRUE;

    regMsg->group = group;
    regMsg->timeout = timeout; // XXX: pick something good

    if (call SendMsg.send(TOS_DEFAULT_ADDR,
			  sizeof(DrainGroupRegisterMsg),
			  &msgBuf) == FAIL) {
      msgBufBusy = FALSE;
      dbg(DBG_ROUTE, "DrainGroupManagerM: couldn't send group-join %d\n", group);
      return FAIL;
    } else {
      dbg(DBG_ROUTE, "DrainGroupManagerM: joining group %d\n", group);
      call GroupManager.joinGroup(group, timeout);
    }	

    return SUCCESS;
  }

  event result_t Intercept.intercept(TOS_MsgPtr msg, void* payload, 
				     uint16_t payloadLen) {

    DrainGroupRegisterMsg *regMsg = (DrainGroupRegisterMsg*) payload;

    call GroupManager.joinForward(regMsg->group, regMsg->timeout);

    dbg(DBG_ROUTE, "DrainGroupManagerM: becoming forwarder for group %d\n", 
	regMsg->group);

    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    // do-nothing
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (msg == &msgBuf) {
      msgBufBusy = FALSE;
    }
    return SUCCESS;
  }
}
