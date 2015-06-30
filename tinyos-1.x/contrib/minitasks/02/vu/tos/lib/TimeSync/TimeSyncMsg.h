/*
 * Copyright (c) 2002, 2003 Vanderbilt University
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
 * Author: Brano Kusy, Miklos Maroti
 * Date last modified: 05/20/03
 */
//	!!!!!IMPORTANT!!!!!!:
//compile your application with -DVANDY_TIME_SYNC_POLLER -DVANDY_TIME_SYNC pflag in Makefile 

typedef struct TimeSyncMsg
{
	uint16_t	rootID;		// the node id of the synchronization root
	uint16_t	nodeID;
	uint8_t		seqNum;		// sequence number for the root


	/*
		This field is updated in the radio stack. When sending the
		message, set this field to the current offset (globalTime - localTime).
		The radio stack will add the current localTime to this field at the 
		time of transmission.
	*/
	uint32_t	sendingTime;	// in global time of the sender

	/*
		This field is NOT transmitted over the radio. The radio stack will
		put this timestamp on the message. This value is the local time
		on the receiver side.
	*/
	uint32_t	arrivalTime;	// in local time of the receiver

} TimeSyncMsg;

enum {
	AM_TIMESYNCMSG = 0xAA,
	TIMESYNCMSG_LEN = sizeof(TimeSyncMsg) - sizeof(uint32_t),
};
