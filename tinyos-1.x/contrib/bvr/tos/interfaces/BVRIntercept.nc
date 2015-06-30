// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: BVRIntercept.nc,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $

/*                                                                      
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * Authors:  Rodrigo Fonseca
 * Date Last Modified: 2005/05/26
 */


includes AM;
includes BVR;

interface BVRIntercept {
  /**
   *
   * Signals that a message has been received, which is supposed to be
   * forwarded to another destination. Allows protocol layers above the
   * routing layer to perform data aggregation or make application-specific
   * decisions on whether to forward.
   *
   * @param msg The complete buffer received.
   *
   * @param payload The payload portion of the packet for this
   * protocol layer. If this layer has layers above it, it should signal
   * receive() with payload incremented by the size of its header. Payload
   * is a pointer into the msg structure.
   *
   * @param payloadLen The length of the payload buffer. If this layer
   * has layers above it, it should signal receive() with payloadLen
   * decreased by the size of its headers and footers.
   *
   * @return SUCCESS indicates the packet should be forwarded, FAIL
   * indicates that it should not be forwarded.
   *
   */
  event result_t intercept(TOS_MsgPtr msg, void* payload, uint16_t payloadLen);
  
}
