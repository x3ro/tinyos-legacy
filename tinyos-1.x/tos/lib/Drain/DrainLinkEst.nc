// $Id: DrainLinkEst.nc,v 1.1 2005/10/27 21:31:04 gtolle Exp $

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
 * @author Gilman Tolle
 */

interface DrainLinkEst {

  /**
   * Given a TOS_MsgPtr, initialize its routing fields to a known
   * state, specifying that the message is originating from this node.
   * This known state can then be used by selectRoute() to fill in
   * the necessary data.
   *
   * @param msg Message to select route for and fill in init data.
   *
   * @return Should always return SUCCESS.
   *
   */

  command result_t initializeFields(TOS_MsgPtr msg, uint8_t id, 
				    uint16_t dest, uint8_t length);

  command result_t forwardFields(TOS_MsgPtr msg);
  
  /**
   * Select a route and fill in all of the necessary routing
   * information to a packet.
   *
   * @param msg Message to select route for and fill in routing information.
   *
   * @return Whether a route was selected succesfully. On FAIL the
   * packet should not be sent.
   *
   */
  
  command result_t selectRoute(TOS_MsgPtr msg);

  /**
   * Inform the link estimator that the message has been sent,
   * possibly successfully, possibly not.
   *
   */

  command result_t messageSent(TOS_MsgPtr msg, result_t success);

  command bool isRoot();
}
