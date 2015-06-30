// $id$

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

module VXM {
  provides {
    interface VarSend;
    interface StdControl;
  }
  uses {
    interface Send;
    interface Receive;
  }
}

implementation {

  enum {
    VX_STATE_IDLE = 0,
    VX_STATE_DATA = 1,
    VX_STATE_RXMT = 2,
    VX_STATE_ABORT = 3
  };

  uint8_t gState;
  uint8_t gFlags;

  void *ghCurrentHandle;
  uint16_t gSndSize;
  uint16_t gSndSeq;
  uint16_t gSndAcked;
  uint16_t gRcvSeq;


  task void SendFrag() {
    

  }

  task void ResendFrag() {

  }

  command result_t StdControl.init() {

    atomic {
      gState = VX_STATE_IDLE;
      gFlags = 0;
    }

  }

  command result_t StdControl.start() {

    return SUCCESS;
  }

  command result_t StdControl.stop() {

    return SUCCESS;
  }

  command result_t VarSend.postSend(void *Handle, uint16_t NumBytes) {
    result_t Result = SUCCESS;
    
    atomic {
      if (fFlags & VX_FLAGS_BUSY) {
	Result = FAIL;
      }
      else {
	fFlags |= VX_FLAGS_BUSY;
	if (NumBytes > VX_MAX_BYTES) {
	  fFlags &= ~VX_FLAGS_BUSY;
	  Result = FAIL;
	}
      }
    }

    if (Result == FAIL) {
      return Result;
    }

    ghCurrentHandle = Handle;
    gSendSize = NumBytes;
    gSndSeq = 0;
    gSndAcked = 0;
    gRcvSeq = 0;

    if (Result == FAIL) {
      atomic fFlags &= ~VX_FLAGS_BUSY;
    }

    return Result;
    
  }

  command result_t VarSend.pullSegDone(void *Handle, uint16_t MsgOffset) {

    return SUCCESS;
  }

  command result_t abortSend(void *Handle) {

    return SUCCESS;
  }

  event result_t SendTimer.fired() {

    post SendFrag();

    return SUCCESS;

  }

  event result_t Send.sendDone(TOS_MsgPtr Msg, result_t success) {

    return SUCCESS;

  }

  event result_t Receive.receive(TOS_MsgPtr Msg, void *Data, uint16_t Len) {

    return SUCCESS;

  }

  default event result_t VarSend.pullSeqReq(void *Handle, uint16_t MsgOffset, 
					     uint8_t SegBuf, uint8_t SegSize) {
    
    return FAIL;
    
  }

  
  default event result_t VarSend.sendDone(uint8_t *PktData, result_t PktResult) {
    
    return SUCCESS;
    
  }


}
