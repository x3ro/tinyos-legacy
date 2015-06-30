// $Id: VarSend.nc,v 1.1 2004/02/11 19:39:45 philipb Exp $

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
 * An interface for sending arbitrary sized messages. The interface is designed to 
 * support a fragmenting implmentation with minimal data movement.
 * @author Philip Buonadonna
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
  event result_t pullSegReq(void *Handle, uint16_t MsgOffset, uint8_t *SegBuf, uint8_t SegSize);

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
  command result_t pullSegDone(void *Handle, uint16_t MsgOffset);

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







