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
 * @author Joe Polastre <joe@polastre.com>
 */
#include "SP.h"
interface SPSend {
  /*
   * Send a message using SP
   *
   * @param msg - The message that is being sent
   *
   * @result - SUCCESS if message was inserted successfully
   *   in message pool.  Does not mean message was sent.
   */
   command result_t send(sp_message_t* msg);

  /*
   * Cancel a message that is in the message pool.
   *
   * @param msg - The sp_message that should be cancelled
   *
   * @result - SUCCESS if message was removed from pool.
   *   FAIL if message was busy or didn't exist.
   */
   command result_t cancel(sp_message_t* msg);

  /*
   * Used to get the payload information for a packet
   * 
   * @param msg - The packet that the payload information
   *   is needed for.
   * @param length - Length of the payload
   * @param src - Whether the source address will be
   *   embedded in packet
   * @param handle - The sp_handle of the destination
   *
   * @result - A pointer to the beginning of the payload
   */
   command void* getBuffer(TOS_MsgPtr msg, uint16_t* length, bool src, uint8_t handle);

  /*
   * Event indicates the radio is done sending the message
   * 
   * @param msg - The sp_message that was just sent
   * @param success - Result of attempt to send message
   */
   event result_t sendDone(sp_message_t* msg, result_t success);
}
