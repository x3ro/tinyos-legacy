// $Id: LRXMsg.h,v 1.4 2006/12/01 00:04:09 binetude Exp $

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
/*
 *
 * Authors:		Sukun Kim
 * Date last modified:  11/30/06
 *
 */

/**
 * @author Sukun Kim
 */

enum {
	AM_LRXMSG = 55,
	MAX_BLOCK_SIZE = 26,
	MAX_WINDOW_SIZE = 64,


	MSG_CTRL_OPEN = 1,
	MSG_CTRL_DATA = 2,
	MSG_CTRL_ACK = 3,
	
	STATE_IDLE = 9,
	
	STATE_SEND_OPEN = 11,
	STATE_SEND_DATA = 12,
	STATE_SEND_ACK = 13,
	
	STATE_RECEIVE_OPEN = 21,
	STATE_RECEIVE_DATA = 22,
	STATE_RECEIVE_ACK = 23,
	
	TIMEOUT_OPEN = 5,
	TIMEOUT_DATA = 5,
	TIMEOUT_ACK = 5,
};

typedef struct LRXPkt {
	uint16_t sourceID;
	uint8_t ctrlandBlockNum;
	uint8_t data[MAX_BLOCK_SIZE];
} LRXPkt;

typedef struct LRXOpenMsg {
	uint8_t numofBlock;
	uint8_t desc[MAX_BLOCK_SIZE - 1];
} LRXOpenMsg;

typedef struct LRXAckMsg {
	uint8_t subCtrl;
	uint8_t bitVector[(MAX_WINDOW_SIZE + 7) / 8];
} LRXAckMsg;

