// $Id: EasyECM.nc,v 1.2 2006/11/30 23:59:21 binetude Exp $

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

module EasyECM {
	provides {
		interface StdControl;
		interface Send;
		interface Receive;
	}
	uses {
		interface SendMsg;
		interface ReceiveMsg;
		interface ErasureCode;
		interface Leds;
	}
}
implementation {
	bool busy;
	uint8_t buf[MaxM * MaxP];
	uint8_t channel[MaxN * MaxP];
	uint8_t codeNumList[MaxM];
	uint8_t mm;
	uint8_t nn;
	uint8_t pp;

	void dump_buf() {
		uint8_t i, j;
		dbg(DBG_USR1, "dump_buf\n");
		for (i = 0; i < mm; i++) {
			for (j = 0; j < pp; j++) {
				dbg(DBG_USR1, "%d\t", buf[i * pp + j]);
			}
		}
		dbg(DBG_USR1, "\n");
	}
	void dump_channel() {
		uint8_t i, j;
		dbg(DBG_USR1, "dump_channel\n");
		for (i = 0; i < nn; i++) {
			for (j = 0; j < pp; j++) {
				dbg(DBG_USR1, "%d\t", channel[i * pp + j]);
			}
		}
		dbg(DBG_USR1, "\n");
	}
	void dump_codeNumList() {
		uint8_t i;
		dbg(DBG_USR1, "codeNumList\n");
		for (i = 0; i < mm; i++) {
			dbg(DBG_USR1, "%d", codeNumList[i]);
		}
		dbg(DBG_USR1, "\n");
	}
	command result_t StdControl.init() {
		result_t r1 = call Leds.init();
		return r1;
	}
	command result_t StdControl.start() {
		int i, j;
		busy = FALSE;
		mm = 7;
		nn = 35;
		pp = 20;
		for (i = 0; i < mm; i++) {
			for (j = 0; j < pp; j++) {
				buf[i * pp + j] = i + j;
			}
		}
		call ErasureCode.setMsg(mm, pp, buf);
		dump_buf();
		for (i = 0; i < nn; i++) {
			call ErasureCode.getCode(channel + i * pp, i);
		}
		dump_channel();
		for (i = 0; i < mm; i++) {
			for (j = 0; j < pp; j++) {
				buf[i * pp + j] = channel[2 * i * pp + j];
			}
			codeNumList[i] = 2 * i;
		}
		call ErasureCode.setCode(mm, pp, buf, codeNumList);
		dump_codeNumList();
		dump_buf();
		call ErasureCode.decode();
		dump_buf();
		return SUCCESS;
	}
	command result_t StdControl.stop() {
		return SUCCESS;
	}

	command result_t Send.send(TOS_MsgPtr msg, uint16_t length) {
		if (busy) return FAIL;
	}
	command void* Send.getBuffer(TOS_MsgPtr msg, uint16_t* length) {
		if (busy) return NULL;
	}
	default event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
		return SUCCESS;
	}
	default event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, void* payload,
		uint16_t payloadLen) {
		return msg;
	}

	event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
		return SUCCESS;
	}
	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
		return msg;
	}
}

