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
 * Date last modified: 2/18/03
 */

/**
 * This interface allows to send big messages (longer than what
 * fits in a single TOS_Msg). The data to be sent can be a continuous
 * buffer, or the concatenation of more buffers (gather).
 */
interface SendBigMsg
{
	/**
	 * Sends a message to <code>address</code>.
	 * @param start1 the start of the data to be sent
	 * @param end1 points one byte after the last byte of the data.
	 * @return FAIL if the component is busy sending another message,
	 *		or there is nothing to send (<code>end1 <= start1</code>).
	 */
	command result_t send(uint16_t address, 
		void *start1, void *end1);

	/**
	 * Sends a message to <code>address</code>.
	 * @param start1 the start of the first part of the data to be sent
	 * @param end1 points one byte after the last byte of the first data.
	 * @param start2 the start of the second part of the data to be sent
	 * @param end2 points one byte after the last byte of the second data.
	 * @return FAIL if the component is busy sending another message,
	 *		or there is nothing to send (<code>end1 <= start1 && end2 <= start2</code>).
	 */
	command result_t send2(uint16_t address, 
		void *start1, void *end1,
		void *start2, void *end2);

	/**
	 * Sends a message to <code>address</code>.
	 * @param start1 the start of the first part of the data to be sent
	 * @param end1 points one byte after the last byte of the first data.
	 * @param start2 the start of the second part of the data to be sent
	 * @param end2 points one byte after the last byte of the second data.
	 * @param start3 the start of the third part of the data to be sent
	 * @param end3 points one byte after the last byte of the third data.
	 * @return FAIL if the component is busy sending another message,
	 *		or there is nothing to send (<code>end1 <= start1 && end2 <= start2</code>).
	 */
	command result_t send3(uint16_t address, 
		void *start1, void *end1,
		void *start2, void *end2,
		void *start3, void *end3);

	/**
	 * Fired when a successfully initiated <code>send</code> terminates.
	 * @param success SUCCESS, if the message was sent succesfully.
	 */
	event void sendDone(result_t success);
}
