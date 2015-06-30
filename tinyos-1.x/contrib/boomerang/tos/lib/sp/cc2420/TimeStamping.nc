// $Id: TimeStamping.nc,v 1.1.1.1 2007/11/05 19:11:29 jpolastre Exp $
/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 */

/**
 * Basic interface for setting and getting post-arbitration timestamps
 * of a particular packet.  Adapted by Moteiv Corporation 
 * from the Vanderbilt timestamping interface to support more general 
 * links with a wider range of functionality.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 * @author Miklos Maroti
 * @date January 2006
 */
interface TimeStamping<precision_tag, size_type>
{
  /**
   * Returns the time stamp of the last received message. This
   * method should be called when the ReceiveMsg.receive() is fired.
   * The returned value contains the 32-bit local time when the message
   * was received.
   */
  command size_type getReceiveStamp(TOS_Msg* msg);

  /**
   * Stop time stamping all together. 
   */
  command void cancel();
  
  /**
   * Adds a time stamp to the next message sent by the radio. This
   * method must be called immediatelly after SendMsg.send() returns
   * SUCCESS. The message must include space for the time stamp based
   * on the size_type specified for this interface.
   * <p>
   * The offset parameter is the offset of the time stamp field
   * in the TOS_Msg.data payload. It must be a value between 0 and 
   * <tt>(TOSH_DATA_LENGTH - sizeof(size_type))</tt>.
   * It is advisable to put the time stamp field at the end of the message.
   * The local time will replace the existing data in the message at the
   * specified offset.
   *
   * @return SUCCESS if the offset is in the valid range, or FALSE
   *	if the message will not be time stamped.
   */
  command result_t addStampAll(int8_t offset);

  /**
   * The same as <tt>addStampAll()</tt> command, with the exception that
   * it will only add a timestamp to "msg" when transmitted.  No timestamps
   * will be added to any other packets.
   */
  command result_t addStamp(TOS_MsgPtr msg, int8_t offset);

  /**
   * Convenience function to get the timestamp from a given TOSMsg
   * instead of replicating this code all over the place.
   *
   * @param msg TOSMsg with a timestamp in it
   * @param offset the offset of the timestamp
   *
   * @return a value of the timestamp at that offset
   */
  command size_type getStampMsg(TOS_MsgPtr msg, int8_t offset);

}
