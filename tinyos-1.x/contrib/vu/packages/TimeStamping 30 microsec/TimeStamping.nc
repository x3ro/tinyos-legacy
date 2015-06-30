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
 * Author: Miklos Maroti
 * Date last modified: 12/05/03
 */

interface TimeStamping
{
	/**
	 * Returns the time stamp of the last received message. This
	 * method should be called when the ReceiveMsg.receive() is fired.
	 * The returned value contains the 32-bit local time when the message
	 * was received.
	 */
	command uint32_t getStamp();

	/**
	 * Adds a time stamp to the next message sent by the radio. This
	 * method must be called immediatelly after SendMsg.send() returns
	 * SUCCESS. The message must include space for the 32-bit time stamp. 
	 * The offset parameter is the offset of the time stamp field
	 * in the TOS_Msg.data payload. It must be a value between 0 and 25,
	 * although implementations can require a smaller range (e.g. [2,25]).
	 * It is advisable to put the time stamp field at the end of the message.
	 * The local time will be ADDED to this time stamp field in the message
	 * at the time of transmission. Therefore, if the time stamp field
	 * is initialized to 0 when SendMsg.send() is invoked, the receiver
	 * will receive the local time of the sender when it actually sent the
	 * message. On the other hand, if the time stamp field in the message
	 * is initialized with the negative of the local time of some event,
	 * then the receiver will receive the elapsed time since that event.
	 * @return SUCCESS if the offset is in the valid range, or FALSE
	 *	if the message will not be time stamped.
	 */
	command result_t addStamp(int8_t offset);
}
