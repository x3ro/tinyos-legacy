// $Id: Snoop.nc,v 1.3 2003/10/07 21:46:14 idgay Exp $

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
 * Authors:		Wei Hong
 * Date last modified:  03/03/03
 *
 */

/**
 * @author Wei Hong
 */


includes AM;
interface Snoop {
  /**
   *
   * Signals that a message that was not destined to the current node
   * has been received promiscuously.  Allows applications to perform
   * certain optimizations taking advantage of the broadcast media.
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
   * @param sender The address of the sender of the snooped message.
   *
   */
  event void snoop(TOS_MsgPtr msg, void* payload, uint16_t payloadLen, uint16_t sender);
}
