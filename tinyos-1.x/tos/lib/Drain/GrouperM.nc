//$Id: GrouperM.nc,v 1.1 2005/10/27 21:31:04 gtolle Exp $

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

module GrouperM {
  provides {
    interface StdControl;
  }
  uses {
    interface ReceiveMsg;
    interface Receive;
    interface Drip;

#if defined(PLATFORM_TELOSB)
    interface DS2411;
#endif

    interface Leds;

    interface GroupManager;
  }
}

implementation {

  GrouperCmdMsg cmdMsgCache;

  void processCmd(GrouperCmdMsg *cmdMsg);

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call Drip.init();
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    processCmd((GrouperCmdMsg*) msg->data);
    return msg;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, void* payload, 
				   uint16_t payloadLen) {
    GrouperCmdMsg *cmdMsg = (GrouperCmdMsg *) payload;
    memcpy(&cmdMsgCache, cmdMsg, sizeof(cmdMsgCache));
    processCmd(cmdMsg);
    return msg;
  }

  void processCmd(GrouperCmdMsg *cmdMsg) {

#if defined(PLATFORM_TELOSB)

    uint8_t i;
    uint8_t id[SERIAL_ID_LEN];
    
    memset(&id[0], 0, SERIAL_ID_LEN);

    call DS2411.copy_id(&id[0]);

    for(i = 0; i < SERIAL_ID_LEN; i++) {
      if (cmdMsg->serialID[i] != id[i]) {
	// not for me
	return;
      }
    }
#endif

    // for me. change my group ID
    switch (cmdMsg->op) {

    case GROUPER_JOIN:
      if (call GroupManager.joinGroup(cmdMsg->groupID, cmdMsg->timeout)) {
	return;
      }
      break;
    case GROUPER_LEAVE:
      if (call GroupManager.leaveGroup(cmdMsg->groupID)) {
	return;
      }
      break;
    default:
      // do nothing.
    }
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, void* payload) {

    GrouperCmdMsg *cmdMsg = (GrouperCmdMsg *) payload;
    memcpy(cmdMsg, &cmdMsgCache, sizeof(cmdMsgCache));
    call Drip.rebroadcast(msg, payload, sizeof(cmdMsgCache));
    return SUCCESS;
  }
}



