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

/**
 * Interface implemented by the magnetic sensors to route information to the
 * pursuers.
 */
interface SendToMovingObjects
{
  /**
   * Sends a message to the given moving object identifier. Some moving object
   * identifiers are "special". see the enum in MovingRoute to send to all
   * pursuers, for example. 
   */
  command result_t send( MovingObjectID_t id, TOS_MsgPtr msg );

  /**
   * Notifies the sender that a message has been sent and that the TosMsgPtr
   * can be reused.
   */
  event result_t sendDone( TOS_MsgPtr msg, result_t success );
} 
