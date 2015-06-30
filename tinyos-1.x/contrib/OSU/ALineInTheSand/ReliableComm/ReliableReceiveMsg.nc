/**
 * Copyright (c) 2003 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */



/* 
 * Authors: Hongwei Zhang, Anish Arora
 */


includes AM;
interface ReliableReceiveMsg
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
  event TOS_MsgPtr receive(TOS_MsgPtr m, uint16_t fromAddr, uint8_t   fromQueuePos);
  /*"fromAddr" denotes the ID of the node that has sent the message m, and "fromQueuePos" denotes the local sequence number of the sender of m */
}
