// $Id: CC2420BareSendMsg.nc,v 1.1.1.1 2007/11/05 19:11:23 jpolastre Exp $
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

#include "AM.h"
#include "CC2420Const.h"

/**
 * Send CC2420 specific TOS_Msg packets through the CC2420RadioC
 * communications driver.  This interface is similar to BareSendMsg
 * with the primary exception that the return type of each function
 * is <tt>cc2420_result_t</tt>.  The radio specific return type allows
 * higher layer abstractions to interpret failures and operations
 * occuring within the CC2420 communications driver.
 * <p>
 * Modified from the original BareSendMsg by Moteiv Corporation
 *
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Joe Polastre, Moteiv Corporation
 * @date January 2006
 */
interface CC2420BareSendMsg
{
  /**
   * Send a message buffer over a communiation channel.
   *
   * @return SUCCESS if the buffer will be sent, FAIL if not. If
   * SUCCESS, a sendDone should be expected, if FAIL, the event should
   * not be expected.
   */
  command result_t send(TOS_MsgPtr msg);

  /**
   * Signals that a buffer was sent; success indicates whether the
   * send was successful or not.
   *
   * @return SUCCESS always.
   *
   */
  event result_t sendDone(TOS_MsgPtr msg, cc2420_error_t success);
}
