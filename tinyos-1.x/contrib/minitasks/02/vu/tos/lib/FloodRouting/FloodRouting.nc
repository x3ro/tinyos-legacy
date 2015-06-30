/*
 * Copyright (c) 2003, Vanderbilt University
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
 * Date last modified: 06/30/03
 */

interface FloodRouting
{
	/**
	 * Initiates the flood routing. The flood routing handles regular 
	 * sized data blocks and stores them in a buffer before 
	 * retransmitting them. If the length of the data block allows,
	 * multiple blocks will be agregated into a single message. 
	 * The data blocks must be uniquely identifiable by their first 
	 * few (maybe all) bytes. Therefore, the same data block will not 
	 * be sent twice in a row.
	 *
	 * @param dataLength The length of the data block. It must be
	 *	in the range [2,FLOODROUTING_MAXDATA].
	 * @param uniqueLength The length of the unique portion (first bytes)
	 *	of the data block. It must be in the range [1,dataLength].
	 * @param buffer A user-provided buffer which will be used
	 *	by the flood routing to store data and its state.
	 * @param bufferLength The length of the buffer in bytes.
	 * @return SUCCESS if the routing was succesfully initialized,
	 *	FAIL otherwise.
	 */
	command result_t init(uint8_t dataLength, uint8_t uniqueLength,
		void *buffer, uint16_t bufferLength);

	/**
	 * Stops the flood routing of this type of data. The buffer 
	 * specified at <code>init</code> can be freely used afterwards.
	 */
	command void stop();

	/**
	 * Sends this data according to the flooding policy. The length 
	 * of the data block is <code>dataLength</code> that was specified 
	 * in <code>init</code>.
	 *
	 * @param data The address of the data to be sent. The data is copied
	 *	to the buffer immediately.
	 * @return SUCCESS if the data was succesfully scheduled to be sent,
	 *	FAIL if the same data is already scheduled.
	 */
	command result_t send(void *data);

	/**
	 * Fired when new data is avaliable at this node. Applications
	 * have a chance to change the data, or force it to be droped.
	 * Note, that this event is fired at each hop towards the target.
	 *
	 * @param data The address of the new data we received. Applications 
	 *	should not modify the first <code>uniqueLength</code> bytes.
	 * @return FAIL if the data should not be sent forward, SUCCESS 
	 *	otherwise. Most applications should always return SUCCESS. 
	 */
	event result_t receive(void *data);
}
