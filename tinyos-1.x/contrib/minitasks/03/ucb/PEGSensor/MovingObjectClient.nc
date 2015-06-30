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
 * DATE:   6/19/03
 */

include MovingRoute;
include MagCenter;

/**
 * Interface implemented by the pursuers (a MovingObject); the interface
 * delivers messages to the giving "MovingObject".
 *
 * It is the responsibility of the MovingObject to call the updateLocation
 * call whenever its location changes: this informs the routing layer how to
 * deliver packets to it. Failure to call this after a position change will
 * result in lost messages. 
 */
interface MovingObjectClient
{
  /**
   * Notifies the MovingObject of a received message.
   */
  event TOS_MsgPtr receive( TOS_MsgPtr msg );

  /**
   * Informs the routing layer of a change in the pursuer's location. It is
   * safe to call this function multiple times with the same value and not
   * suffer a performance penalty: the routing layer will ensure that messages
   * are sent only when the position changes.
   */
  command result_t updateLocation(MovingObjectID_t id, MagPosition_t position);
}
