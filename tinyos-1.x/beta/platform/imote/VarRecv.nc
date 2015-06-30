/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

interface VarRecv {

  /**
   * Notify the application that a remote sender has requested to send
   * a bulk transfer. 
   *
   * @param SrcAddr The TOS source address of the sender.
   * @param MaxBytes The size of message the sender wants to deliver.
   * @param TransactionID An ID assigned by the provider to be used in accepting
   * or rejecting the connection.
   * @return SUCCESS always.
   */
  event result_t recvReq(uint16_t SrcAddr, uint16_t NumBytes, uint8_t TransactionID);

  /**
   * Notify the communication provider that the caller is prepared accept
   * the message transaction identified by TransactionID
   *
   * @param Handle An opaque reference assigned by the application which 
   * is bound to this message instance.
   * @param TransactionID the transaction ID associated with this exchange
   * as passed in by recvReq.
   * @return SUCCESS always.
   */
  command result_t acceptRecv(void *Handle, uint8_t TransactionID);

  /**
   * Notify the communication provider that the caller rejects the 
   * the proposed message transaction identified by TransactionID. No
   * data will be received.
   * @param TransactionID the transaction ID associated with this exchange
   * as passed in by recvReq.
   * @return SUCCESS always.
   */

  command result_t rejectRecv(uint8_t TransactionID);
  /**
   * Signaled by the provider to indicate that SegSize bytes at MsgOffset 
   * in the payload are avaiable in SegBuf. The putSegReq operation is 
   * split-phase. The application must call putSegDone when the transfer 
   * is complete or return FAIL to abort the reception. Multiple outstanding
   * putSeqReqs may be issued, each requiring a subsequent, separate putSegDone.
   *
   * @param Handle The application handle for the receive operation.
   * @param MsgOffset The offset, in bytes, in the message payload this 
   * recieve represents.
   * @param SegBuf The buffer containing the segment
   * @param SegSize The number of bytes in the segment
   *
   * @return FAIL if the message reception is to be aborted. SUCCESS otherwise.
   *
   */
  event result_t putSegReq(void *Handle, uint16_t MsgOffset, uint8_t *SegBuf, uint8_t SegSize);

  /**
   * Called by the application following a putSeqReq event to indicate disposition
   * of the segment to the provider. This command must called once for each 
   * individual putSeqReq event.
   * 
   * @param Handle The application handle for the receive operation.  It must be
   * the same as the one passed in by pullSegReq.
   * @param MsgOffset The MsgOffset passed in by putSegReq. It mussed be the same as
   * the value passed in by the assoc. putSegReq.
   *
   * @return SUCCESS if the segment transfer is accepted.
   */
  command result_t putSegDone(void *Handle, uint16_t MsgOffset);

  /**
   * Signaled to notify the application that no further putSeqReq events will be issued.
   * 
   *
   * @param Handle The application handle for the message being sent.
   * @param Result The status of the message transmission. SUCCESS indicates all
   * segments were received. FAIL indicates the connection was lost or the sender
   * aborted the transaction.
   * 
   * @return SUCCESS always.
   */
  event result_t recvDone(void *Handle, result_t Result);

  /**
   * Called to abort the present message receive identified by the given Handle.
   *
   * @param Handle The Handle of the original message to terminate transmission
   * 
   * @return SUCCESS always
   */
  command result_t abortRecv(void *Handle);
}

