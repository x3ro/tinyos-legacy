/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/**
 * @modified 3/8/06
 *
 * @author Arsalan Tavakoli <arsalan@cs.berkeley.edu>
 * @author Sukun Kim <binetude@cs.berkeley.edu>
 */
#include "SP.h"
interface SPReceive {
  /*
   * Event informs the network layer that a packet has been
   *  received
   *
   * @param _msg - The actual packet received
   * @param payload - A pointer to the beginning of the
   *   message payload
   * @param payloadLen - Length of the payload
   * @param sp_handle - The SP-Handle of the source.  Set to
   *   TOS_UART_HANDLE if the message came over the UART,
   *   TOS_OTHER_HANDLE if from a neighbor not in the
   *   neighbor table, and TOS_NO_HANDLE if no source
   *   embedded in message.
   * @param dest_handle - The SP-Handle of the packet
   *   destination.  TOS_LOCAL_HANDLE if it is addressed
   *   to this node.
   *
   * @result - Message buffer must be passed down
   */
   event TOS_MsgPtr receive(TOS_MsgPtr _msg, void* payload, uint16_t payloadLen, uint8_t sp_handle, uint8_t dest_handle);
}
