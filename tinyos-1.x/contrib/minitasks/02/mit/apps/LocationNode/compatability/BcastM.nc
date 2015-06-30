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
includes Bcast;

/**
 * 
 **/
module BcastM {
  provides {
    interface StdControl;
    interface Receive[uint8_t id]; // receive(TOS_MSgPtr, *payload, payloadLen)

    // New base-station interface
    interface SendData[uint8_t id];
  }
  uses {
    interface StdControl as SubControl;
    interface ReceiveMsg[uint8_t id];  // receive(TOS_MsgPtr m)
    interface SendMsg[uint8_t id];
  }
}

implementation {

  enum {
    FWD_QUEUE_SIZE = 4
  };

  int16_t BcastSeqno;
  struct TOS_Msg FwdBuffer[FWD_QUEUE_SIZE];
  struct TOS_Msg sendBuffer;
  TOS_MsgPtr sendPtr;
  char sendBufferInUse;
  uint8_t iFwdBufHead, iFwdBufTail;

  /***********************************************************************
   * Initialization 
   ***********************************************************************/

  static void initialize() {
    iFwdBufHead = iFwdBufTail = 0;
    BcastSeqno = 0;
    sendBufferInUse = 0;
    sendPtr = &sendBuffer;
  }

  /***********************************************************************
   * Internal functions
   ***********************************************************************/

  static bool newBcast(int16_t proposed) {
    /*	This handles sequence space wrap-around. Overlow/Underflow makes
     * the result below correct ( -, 0, + ) for any a, b in the sequence
     * space. Results:	result	implies
     *			  - 	 a < b
     *			  0 	 a = b
     *			  + 	 a > b
     */
    if ((proposed - BcastSeqno) > 0) {
      BcastSeqno = proposed; // was BcastSeqno++
      // (changed in case we miss a broadcast, we don't want to handle the
      //  message twice!)
      return TRUE;
    } else {
      return FALSE;
    }
  }

/* Each unique broadcast wave is signaled to application and
   rebroadcast once.
*/

  static void FwdBcast(TOS_BcastMsg *pRcvMsg, uint8_t Len, uint8_t id) {
    TOS_BcastMsg *pFwdMsg;
    
    if (((iFwdBufHead + 1) % FWD_QUEUE_SIZE) == iFwdBufTail) {
      // Drop message if forwarding queue is full.
      return;
    }
    
    pFwdMsg = (TOS_BcastMsg *) &FwdBuffer[iFwdBufHead].data; //forward_packet.data;
    
    memcpy(pFwdMsg,pRcvMsg,sizeof(TOS_BcastMsg));

    dbg(DBG_USR1, "Bcast: FwdMsg (seqno 0x%x)\n", pFwdMsg->seqno);
    if (call SendMsg.send[id](TOS_BCAST_ADDR, sizeof(TOS_BcastMsg), &FwdBuffer[iFwdBufHead]) == SUCCESS) {
      iFwdBufHead++; iFwdBufHead %= FWD_QUEUE_SIZE;
    }
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/

  command result_t StdControl.init() {
    initialize();
    return call SubControl.init();
  }

  command result_t StdControl.start() {
    return call SubControl.start();
  }

  command result_t StdControl.stop() {
    return call SubControl.stop();
  }

  event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr pMsg, bool success) {
    if (pMsg == &FwdBuffer[iFwdBufTail]) {
      iFwdBufTail++; iFwdBufTail %= FWD_QUEUE_SIZE;
    }
    else if(pMsg == sendPtr) {
      sendBufferInUse = 0;
      signal SendData.sendDone[id](NULL, SUCCESS);
    }
    return SUCCESS;
  }

  // >>> New Base-station interface >>>
  command result_t SendData.send[uint8_t id](uint8_t* data, uint8_t numBytes) {
    TOS_BcastMsg *pFwdMsg;

    if(sendBufferInUse == 0) {      
      pFwdMsg = (TOS_BcastMsg *) &sendPtr->data; //forward_packet.data;
      
      memcpy(&pFwdMsg->data,data,numBytes < (sizeof(TOS_BcastMsg) - 2) ? numBytes : sizeof(TOS_BcastMsg) - 2);
      pFwdMsg->seqno = ++BcastSeqno;
      
      if(call SendMsg.send[id](TOS_BCAST_ADDR, sizeof(TOS_BcastMsg), sendPtr) == SUCCESS) {
	sendBufferInUse = 1;

	// send it to our consumer to let them process it.
	sendPtr = signal Receive.receive[id](sendPtr,&pFwdMsg->data,numBytes < (sizeof(TOS_BcastMsg) - 2) ? numBytes : sizeof(TOS_BcastMsg) - 2);
	return SUCCESS;
      }
    }

    return FAIL;
  }

  // When we signal the event, data will be NULL because we copy the input
  //  buffer before send returns, so you have no outstanding buffer to 
  //  worry about.
  default event result_t SendData.sendDone[uint8_t id](uint8_t* data, result_t success) {
    return SUCCESS;
  }
  // <<< End new base-station interface <<<

  event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr pMsg) {
    TOS_BcastMsg *pBCMsg = (TOS_BcastMsg *)pMsg->data;
    uint16_t Len = pMsg->length - offsetof(TOS_BcastMsg,data);

    dbg(DBG_USR2, "Bcast: Msg rcvd, seq 0x%02x\n", pBCMsg->seqno);

    if (newBcast(pBCMsg->seqno)) {
      FwdBcast(pBCMsg,pMsg->length,id);
      signal Receive.receive[id](pMsg,&pBCMsg->data[0],Len);
    }
    return pMsg;
  }

  default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr pMsg, void* payload, 
						       uint16_t payloadLen) {
    return pMsg;
  }
  
}



