//$Id: RpcM.nc,v 1.1.1.1 2007/11/05 19:09:17 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * @author Kamin Whitehouse
 */

includes Drain;
includes Rpc;
includes DestMsg;

module RpcM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as SubControl;

    interface ReceiveMsg as CommandReceiveLocal;

    interface Send as ResponseSendDrain;
    interface SendMsg as ResponseSendMsgDrain;

    interface Receive as CommandReceiveDrip;
    interface Drip as CommandDrip;
    interface Dest;
  }
}
implementation {

  TOS_Msg dripStore;
  uint16_t dripStoreLength;
  uint16_t queryID;
  uint16_t returnAddress;

  command result_t StdControl.init() {
    call SubControl.init();
    dbg(DBG_USR2, "init in dummy file\n");
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call SubControl.start();
    call CommandDrip.init();
    dbg(DBG_USR2, "start in dummy file\n");
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    dbg(DBG_USR2, "stop in dummy file\n");
    return SUCCESS;
  }

  event TOS_MsgPtr CommandReceiveDrip.receive(TOS_MsgPtr pMsg, void* payload, uint16_t payloadLength) {
    dbg(DBG_USR2, "Received drip message in dummy file\n");
    return pMsg;
  }

  event TOS_MsgPtr CommandReceiveLocal.receive(TOS_MsgPtr pMsg) {
    dbg(DBG_USR2, "Received local message in dummy file\n"); 
   return pMsg;
  }

  event result_t CommandDrip.rebroadcastRequest(TOS_MsgPtr msg, void *payload) {
    dbg(DBG_USR2, "Received rebroadcast request in dummy file\n");
    return SUCCESS;
  }

  event result_t ResponseSendMsgDrain.sendDone(TOS_MsgPtr pMsg, result_t success) {
    dbg(DBG_USR2, "send done in dummy file\n");
    return SUCCESS;
  }

  event result_t ResponseSendDrain.sendDone(TOS_MsgPtr pMsg, result_t success) {
    dbg(DBG_USR2, "send done in dummy file\n");
    return SUCCESS;
  }

  

}
