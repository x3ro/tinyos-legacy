/*									tab:4
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * AUTHOR: nks
 * DATE:   6/21/03
 */

includes ERoute;

interface ERoute {

  /**
   * Constructs the spanning tree rooted at this node. The endpoint name for
   * this node is given in the local variable. Calling this command again will
   * rebuild the tree.
   *
   * @param local the endpoint name for the tree.
   * @returns whether the build command was successfully initiated.
   */
  command result_t build (EREndpoint local);

  /**
   * Constructs a crumb trail rooted at this node. The local endpoint name
   * should be a mobile agent, while the tree identifies which spanning tree
   * (and hence base station) to use. Seqno should be monotonically increasing
   * and never reused.
   *
   * @param local the local endpoint name for the tree
   * @param tree the underlying spanning tree that will be used to route to
   *             the landmark.
   * @param seqno a monotonically increasing value that indicates the
   *             freshness of crumb routes.
   */
  command result_t buildTrail (EREndpoint local, EREndpoint tree,
                               uint16_t seqno); 

  /**
   * Sends data to an endpoint.
   *
   * @param the destination.
   * @param dataLen the length of data to send.
   * @param data a pointer to the buffer to send.
   * @return wheter the send could be successfully initiated (possible failure
   *        reasons include unknown endpoints or nodes not on the span tree). 
   */
  command result_t send (EREndpoint dest, uint8_t dataLen, uint8_t * data);

  /**
   * Event notifying the sender that the first part of the send was
   * successfully initiated.
   */
  event result_t sendDone (EREndpoint dest, uint8_t * data);

  /**
   * Event notifiying of an incoming message for the endpoint. This will be
   * generated only after a buildTrail() or build() call has been made since
   * those calls register the receiver endpoints.
   *
   * @param dest the receiver endpoint for which the message is destined.
   * @param dataLen the amount of data being received.
   * @param data pointer to the data buffer.
   */
  event result_t receive (EREndpoint dest, uint8_t dataLen, uint8_t * data);
  
}
