// $Id: BcastM.nc,v 1.1 2005/12/15 01:24:53 binetude Exp $

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

includes AM;
includes Bcast;

/**
 * 
 **/
module BcastM {
  provides {
    interface StdControl;
    interface Receive[uint8_t id];
  }
  uses {
    interface StdControl as SubControl;
    interface ReceiveMsg[uint8_t id];
    interface SendMsg[uint8_t id];
  }
}

implementation {

  enum {
    FWD_QUEUE_SIZE = 4
  };

  int16_t BcastSeqno;
  TOS_Msg FwdBuffer[FWD_QUEUE_SIZE];
  uint8_t iFwdBufHead, iFwdBufTail;

  /***********************************************************************
   * Initialization 
   ***********************************************************************/

  static void initialize() {
    iFwdBufHead = iFwdBufTail = 0;
    BcastSeqno = 0;
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
//      BcastSeqno++;
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
    
    memcpy(pFwdMsg,pRcvMsg,Len);

    dbg(DBG_USR1, "Bcast: FwdMsg (seqno 0x%x)\n", pFwdMsg->seqno);
    if (call SendMsg.send[id](TOS_BCAST_ADDR, Len, &FwdBuffer[iFwdBufHead]) == SUCCESS) {
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

  event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr pMsg, result_t success) {
    if (pMsg == &FwdBuffer[iFwdBufTail]) {
      iFwdBufTail++; iFwdBufTail %= FWD_QUEUE_SIZE;
    }
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr pMsg) {
    TOS_BcastMsg *pBCMsg = (TOS_BcastMsg *)pMsg->data;
    uint16_t Len = pMsg->length - offsetof(TOS_BcastMsg,data);

    dbg(DBG_USR2, "Bcast: Msg rcvd, seq 0x%02x\n", pBCMsg->seqno);

    if (pBCMsg->seqno == UART_SEQ_NO) {
      if (BcastSeqno == INIT_SEQ_NO) {
        //pBCMsg->seqno = BcastSeqno = 1;
        BcastSeqno = 1;
      } else {
	BcastSeqno++;
	if (BcastSeqno == INIT_SEQ_NO) BcastSeqno++;
        pBCMsg->seqno = BcastSeqno;
      }
    } else {
      if (BcastSeqno == INIT_SEQ_NO) {
        BcastSeqno = pBCMsg->seqno;
      } else {
        if (newBcast(pBCMsg->seqno)) {
	  BcastSeqno = pBCMsg->seqno;
        } else {
	  return pMsg;
	}
      }
    }

    FwdBcast(pBCMsg,pMsg->length,id);
    signal Receive.receive[id](pMsg,&pBCMsg->data[0],Len);
    return pMsg;
  }

  default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr pMsg, void* payload, 
						       uint16_t payloadLen) {
    return pMsg;
  }
  
}



