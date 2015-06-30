// $Id: Intercept.nc,v 1.1.1.1 2007/11/05 19:09:03 jpolastre Exp $

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
/*
 * Authors:		Philip Levis
 * Date last modified:  1/30/03
 *
 * The Intercept interface should be provided by all protocols above layer
 * 2 (GenericComm/AM). For example, ad-hoc routing protocols should
 * provide this interface for in-network packet processing.
 *
 * The goal of this interface is to allow transmission hops to 
 * process packet payloads without having to know about the internal
 * structure of the packet or the layers below them in the stack.
 *
 * The Interface interface is only used by nodes that are forwarding a
 * multihop messages. A protocol layer does not perform a buffer swap, but
 * can tell lower layers to not forward a packet by giving a FAIL return value.
 * Using this, an in-network intermediary can receive multiple packets, aggregate
 * their results, then forward them on to the destination.
 *
 * For example, if a packet takes the route A->B->C->D
 *
 * A: send();
 * B: intercept();
 * C: intercept();
 * D: receive();
 */

/**
 * @author Philip Levis
 */


includes AM;
interface Intercept {
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
