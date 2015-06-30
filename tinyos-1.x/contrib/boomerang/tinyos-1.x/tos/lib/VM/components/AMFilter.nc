// $Id: AMFilter.nc,v 1.1.1.1 2007/11/05 19:09:24 jpolastre Exp $

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
 * Copyright (c) 2004-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Date last modified:  8/25/03
 *
 */

/**
 * This component filters packet receptions based on AM addressing
 * requirements. Packets are filtered on two attributes: the
 * destination address must either be the local address or the
 * broadcast address, and the group ID must match the local group ID.
 *
 * @author Philip Levis
*/

includes AM;

module AMFilter {
  provides interface ReceiveMsg as UpperReceive[uint8_t id];
  uses interface ReceiveMsg as LowerReceive[uint8_t id];
}


implementation {
  
  event TOS_MsgPtr LowerReceive.receive[uint8_t id](TOS_MsgPtr msg) {
    if (((msg->addr == TOS_LOCAL_ADDRESS) ||
	 (msg->addr == TOS_BCAST_ADDR)) &&
	(msg->group == TOS_AM_GROUP)){
      dbg(DBG_AM, "AMFilter: Packet passed AM, signaling.\n");
      return signal UpperReceive.receive[id](msg);
    }
    else {
      dbg(DBG_AM, "AMFilter: Packet failed AM requirements.\n");
      return msg;
    }
  }

  default event TOS_MsgPtr UpperReceive.receive[uint8_t id](TOS_MsgPtr msg) {
    return msg;
  }
  
}
