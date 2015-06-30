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

interface VarSend {

  /**
   * Initiate a send operation of an arbitrary sized buffer. This command 
   * only passes in an opaque Handle of the applications choosing and the
   * total size (in bytes) of the message to send.  The actual paylod itself
   * is pulled from the application via the PullSegment event.
   *
   * @param Handle An opaque reference assigned by the application which 
   * is bound to this message instance being sent.
   * @param numBytes The total size of the message payload in bytes.
   * @return SUCCESS if the resources are available and the message is
   * accepted for sending.
   */
  command result_t postSend(void *Handle, uint16_t NumBytes, uint16_t destAddr);

  /**
   * Signaled by the provider to indicate it is ready to accept SegSize 
   * bytes starting at MsgOffset bytes in the message identified by Handle. 
   * Payload bytes are to be copied into SegBuf. This operation is split-phase. 
   * The application must call pullSegDone whent the transfer is finished or 
   * return FAIL to abort message transmission. Multiple outstanding 
   * pullSegReqs may be issued, each requiring a subequent, separate pullSegDone.
   *
   * @param Handle The application handle for the message being sent.
   * @param MsgOffset The offset, in bytes, in the message payload to start sending.
   * @param SegBuf The buffer to store the bytes
   * @param SegSize The number of bytes to put into SegBuf
   *
   * @return FAIL if the message transmission is to be aborted. SUCCESS otherwise.
   *
   */
  event result_t pullSegReq(void *Handle, uint16_t MsgOffset, 
	uint8_t *SegBuf, uint8_t SegSize);

  /**
   * Called by the application following a pulSeqReq event to indicate completion of 
   * the segment transfer request. 
   *
   * @param Handle The application handle for the message being sent.  It must be the same 
   * the one passed in by pullSegReq.
   * @param MsgOffset The MsgOffset passed in by pullSegReq
   *
   * @return SUCCESS if the segment transfer is accepted.
   */
  command result_t pullSegDone(void *Handle, uint16_t MsgOffset, result_t Result);

  /**
   * Signaled to notify the application that no further pullSeqReq events will be issued
   * and the application can safely dispose of the original message payload.  Depending
   * on the semantics of the provider it MAY (reliable transmission) or MAY NOT 
   * (unreliable transmission) indicate the message was successfully recieved at
   * the destination. 
   *
   * @param Handle The application handle for the message being sent.
   * @param Result The status of the message transmission. FAIL indicates
   * a resource confict and MAY indicate the message was not delivered (reliable
   * transports only).
   * 
   * @return SUCCESS always.
   */
  event result_t sendDone(void *Handle, result_t Result);

  /**
   * Called by the application to abort the present message transfer identified by 
   * the given Handle.
   *
   * @param Handle The Handle of the original message to terminate transmission
   * 
   * @return SUCCESS always
   */
  command result_t abortSend(void *Handle);
}
