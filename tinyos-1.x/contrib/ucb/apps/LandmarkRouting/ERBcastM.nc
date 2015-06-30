/*									tab:4
 *
 *
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * Author: Matt Welsh, David Culler
 * Created: 24 Dec 2002
 * 
 */

includes AM;
includes ERBcast;
includes Config;

//!! Config 31 { uint16_t ERB_RFThreshold = 200; }
//!! Config 32 { ERB_RetransmitTime_t ERB_RetransmitTime = { bias:20, shift:255 }; }

/**
 * 
 **/
module ERBcastM {
  provides
  {
    interface StdControl;
    interface Receive[uint8_t id];
  }
  uses
  {
    interface RoutingReceive as ReceiveMsg[uint8_t id];
    interface RoutingSendByImplicit as SendMsg[uint8_t id];
    interface Timer;
    interface Random;
    event void epochExpired(uint8_t *payload);
  }
}

implementation { 

  enum {
    TIMER_SET = 1,
    TIMER_EXPIRED = 3
  };

  uint8_t timerSet;
  TOS_Msg msgToSend;

  command result_t StdControl.init() {
    call Random.init();
    timerSet = TIMER_EXPIRED;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t SendMsg.sendDone[uint8_t id]( TOS_MsgPtr pMsg, bool success) {
    return SUCCESS;
  }
  int16_t currentSeqno = 0;

  void saveSeqno(int16_t newSeqno) {
    currentSeqno = newSeqno;
  }
  uint8_t isNewMsg(int16_t newSeqno) {
    return (newSeqno - currentSeqno) > 0;
  }
  uint8_t signalableMsg(int16_t newSeqno) {
    return (newSeqno - currentSeqno) >= 0;
  }


  int16_t forwardSeqno = 1;
  uint8_t rememberLength;

  event result_t Timer.fired() {
    TOS_BcastMsg* pBCMsg = (TOS_BcastMsg*) msgToSend.data;

    timerSet = TIMER_EXPIRED;
    // signal up to upper layer to send next message
    signal epochExpired(&pBCMsg->data[0]);
    
    if (isNewMsg(forwardSeqno)) {
      saveSeqno(forwardSeqno);
      pBCMsg->seqno = forwardSeqno;

      initRoutingMsg(&msgToSend, 0);
      msgToSend.length = rememberLength;
      // no multiple send in bcast msg
      msgToSend.ext.retries = 0;
      
      // send it out
      call SendMsg.send[ERBCAST_AMHANDLER](&msgToSend);
    }
    return SUCCESS;
  }
  


  event TOS_MsgPtr ReceiveMsg.receive[uint8_t id]( TOS_MsgPtr pMsg ) {
    // fitler signal strength
    TOS_BcastMsg* pBCMsg = (TOS_BcastMsg*)pMsg->data;
    uint16_t delay;
    ERMsg *pmsg;
    //dbg(DBG_USR3, "Received  message in ERBcastM.nc : ReceiveMsg.receive\n");
    //dbg(DBG_USR3, "id: %d\n", id);
#ifdef PLATFORM_PC
    if (id == 53) { // build span tree msg
      pmsg = (ERMsg*)pBCMsg->data;
      dbg(DBG_USR3, "RSSI: %d\n", pmsg->u.treeBuild.parent);
      pMsg->strength = generic_adc_read(TOS_LOCAL_ADDRESS, 131, 0L); // RSSI_PORT
    }
#endif

    // just to maintain their interface
    if (id != ERBCAST_AMHANDLER)
      return pMsg;

    // signal too big, (means too weak) discard
    if (pMsg->strength > 75) {
      dbg(DBG_USR3, "signal strength too weak\n");
      dbg(DBG_USR3, "strength: %d threshold: %d\n", pMsg->strength, 75);
      return pMsg;
    }
    
    if (signalableMsg(pBCMsg->seqno)) {
      rememberLength = pMsg->length;

      signal Receive.receive[id](pMsg, &pBCMsg->data[0], pMsg->length - offsetof(TOS_BcastMsg, data));
      if (timerSet == TIMER_SET) {
	call Timer.stop();
      }
      // if we got a timer running, kill it, start a new one
      // do some randomization
      delay = G_Config.ERB_RetransmitTime.bias;
      delay += (call Random.rand() & G_Config.ERB_RetransmitTime.shift);
      // start the timer
      timerSet = TIMER_SET;
      call Timer.start(TIMER_ONE_SHOT, delay);
      // Find the maximnum sequence number heard for so long
      forwardSeqno = (pBCMsg->seqno - forwardSeqno > 0) ? pBCMsg->seqno : forwardSeqno;
    }

    return pMsg;
  }

  default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr msg, void* payload, uint16_t payloadLen){
    return msg;
  }


}




