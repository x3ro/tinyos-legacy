// $Id: ReceiveMsg.nc,v 1.1.1.1 2007/11/05 19:09:03 jpolastre Exp $

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
 * TinyOS AM packet reception interface.
 *
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @modified 6/25/02
 */

includes AM;
interface ReceiveMsg
{

  /**
   * A packet has been received. The packet received is passed as a
   * pointer parameter. The event handler should return a pointer to a
   * packet buffer for the reception layer to use for the next
   * reception. This allows an application to swap buffers back and
   * forth with the messaging layer, preventing the need for
   * copying. The signaled component should not maintain a reference
   * to the buffer that it returns. It may return the buffer it was
   * passed. For example:
   * <code><pre>
   * event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
   *    return m;
   * }
   * </pre></code>
   *
   * A more common example:
   * <code><pre>
   * TOS_MsgPtr buffer;
   * event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
   *    TOS_MsgPtr tmp;
   *    tmp = buffer;
   *    buffer = m;
   *	post receiveTask();
   *	return tmp;
   * }
   * </pre></code>
   *
   * @return A buffer for the provider to use for the next packet.
   *
   */
  event TOS_MsgPtr receive(TOS_MsgPtr m);
}
