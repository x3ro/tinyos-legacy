/*
 * "Copyright (c) 2002-2005 The Regents of the University  of California.  
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
 * Interface for QueuePolicy 
 *
 * The goal of this interface is to allow network layer
 * protocols to implement their own communication scheduling
 * policies on QueuedASend. This is for protocols that manage
 * when messages are actually sent, such as needed to indicate
 * radio awake and sleep times. Routing layer and application
 * messages queue their messages with QueuedASend and the
 * messages are sent at a later time according to the
 * policy implemented.  
 *
 * Implementing QueuePolicy is optional. If a
 * QueuePolicy component is not provided, QueuedASend
 * forwards messages as soon as the are queued.
 *
 * The network protocol should call forward() when 
 * QueuedASend should forward the next message.
 * 
 * @author Barbara Hohlt 
 * @date   February 4 2005
 */

interface QueuePolicy {

  /**
   * Called when the queue should forward the next message.
   */
  command void forward();

  /**
   * Signals when a message has been queued.
   */
  event void next();
}
