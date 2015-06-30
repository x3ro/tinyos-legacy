// $Id: LRX.nc,v 1.4 2006/12/01 00:04:09 binetude Exp $

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

#define PKT_XFER_TIME 100
#define SEND_DATA_INTERVAL 100
module LRX {
	provides {
		interface StdControl;
		interface LRXSend;
		interface LRXReceive;

		command result_t get_stats();
	}
	uses {
		interface SendMsg;
		interface ReceiveMsg;
		interface Timer;
	}
}
implementation {

////////////////  Variables  ////////////////
// Finite State Machine Control
	uint8_t state;
	uint8_t timeout;

// Window
	uint8_t ackBuf[(MAX_WINDOW_SIZE + 7) / 8];
	uint8_t ackWin[MAX_WINDOW_SIZE];
	uint8_t slotNumWin[MAX_WINDOW_SIZE];
	uint8_t numofSlot;
	uint8_t prevLastBlock;

	uint8_t blockIndex;
	uint8_t slotIndex;
	uint8_t ackBufSize;

// Communication
	TOS_Msg outPkt;

// Overall
	uint16_t correspondentID;
	uint8_t numofBlock;

// Etc
	uint16_t prevCorrespondentID;
	uint8_t prevNumofBlock;
	bool history_valid;
	uint8_t *desc;
	uint8_t descSize;

// Debug
	//uint8_t open_loss;
	//uint8_t data_loss;
	//uint8_t ack_loss;

	uint16_t out_open_count;
	uint16_t out_data_count;
	uint16_t out_ao_count;
	uint16_t out_ad_count;
	uint16_t out_aa_count;
	uint16_t out_error_count;
	
	uint16_t in_open_count;
	uint16_t in_data_count;
	uint16_t in_ao_count;
	uint16_t in_ad_count;
	uint16_t in_aa_count;
	uint16_t in_error_count;

////////////////  Functions  ////////////////
// Finite State Machine Control
	uint8_t get_ctrl(uint8_t ctrlandBlockNum);
	uint8_t get_blockNum(uint8_t ctrlandBlockNum);
	uint8_t combine_ctrl_and_blockNum(uint8_t ctrl, uint8_t blockNum);
	result_t write_history();
	result_t transit(uint8_t newState);

// Window
	result_t encode_ackBuf();
	result_t decode_ackBuf();
	uint8_t next_block_num();

// Communication
	result_t send_open_msg();
	result_t send_data_msg(uint8_t blockNum);
	result_t send_ack_msg(uint8_t subCtrl);
	result_t send_prev_ack_msg();
	result_t send_nack_msg_busy(uint16_t sourceID);

// Overall
	result_t init_send(uint16_t destID, uint8_t aNumofBlock,
		uint8_t *aDesc, uint16_t aDescSize);
	result_t init_receive(uint16_t sourceID, uint8_t aNumofBlock);

	result_t process_open_msg_common(TOS_MsgPtr msg);
	result_t process_data_msg(TOS_MsgPtr msg);
	result_t process_ack_msg(TOS_MsgPtr msg);
	result_t send_next_data();
	result_t update_slotNumWin();

// Etc
	result_t clear_mem(uint8_t *memArray, uint8_t clearSize);
	result_t copy_mem(uint8_t *copySrc, uint8_t *copyDest, uint8_t copySize);

// Debug
	result_t check_receive(TOS_MsgPtr msg);
	result_t print_pkt(TOS_MsgPtr msg);
	result_t print_window_info();
	result_t out_count(uint8_t outCtrl, uint8_t outSubCtrl);
	result_t in_count(uint8_t inCtrl, uint8_t inSubCtrl);
	result_t send_count_info(uint16_t destID);




	command result_t StdControl.init() {
		return SUCCESS;
	}
	command result_t StdControl.start() {
		state = STATE_IDLE;
		history_valid = FALSE;
	
		out_open_count = 0;
		out_data_count = 0;
		out_ao_count = 0;
		out_ad_count = 0;
		out_aa_count = 0;
		out_error_count = 0;
		
		in_open_count = 0;
		in_data_count = 0;
		in_ao_count = 0;
		in_ad_count = 0;
		in_aa_count = 0;
		in_error_count = 0;

		return SUCCESS;
	}
	command result_t StdControl.stop() {
		return SUCCESS;
	}
	
	command result_t LRXSend.transfer(uint16_t destID, uint8_t aNumofBlock,
		uint8_t *aDesc, uint8_t aDescSize) {
		dbg(DBG_USR1, "... LRXSend.transfer    state = %d, numofBlock = %d\n", state, aNumofBlock);
		if (state != STATE_IDLE) return FAIL;
		
		//open_loss = 0;
		transit(STATE_SEND_OPEN);
		init_send(destID, aNumofBlock, aDesc, aDescSize);
	
		timeout = TIMEOUT_OPEN;
		send_open_msg();
		call Timer.start(TIMER_ONE_SHOT, PKT_XFER_TIME * 2);

		return SUCCESS;
	}
	command result_t LRXSend.abortSend() {
		dbg(DBG_USR1, "... LRXSend.abortSend    state = %d\n", state);
		if (state == STATE_IDLE) return FAIL;
		call Timer.stop();
		transit(STATE_IDLE);
		signal LRXSend.transferDone(desc, FAIL);
		return SUCCESS;
	}
	command result_t LRXReceive.abortReceive() {
		dbg(DBG_USR1, "... LRXReceive.abortReceive    state = %d\n", state);
		if (state == STATE_IDLE) return FAIL;
		call Timer.stop();
		transit(STATE_IDLE);
		signal LRXReceive.acceptedTransferDone(FAIL);
		return SUCCESS;
	}




	event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
//		dbg(DBG_USR2, "<<< SendMsg.sendDone   state = %d\n", state);
		switch (state) {
		case STATE_IDLE: break;
		
		case STATE_SEND_OPEN: break;
		case STATE_SEND_DATA: break;
		case STATE_SEND_ACK: break;
		
		case STATE_RECEIVE_OPEN: break;
		case STATE_RECEIVE_DATA: break;
		case STATE_RECEIVE_ACK: break;
		
		default:
			dbg(DBG_USR3, "!!! SendMsg.sendDone   state = %d\n", state);
			break;
		}
		return SUCCESS;
	}




	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
		LRXPkt *pktContent = (LRXPkt *)msg->data;
		LRXOpenMsg *openMsg = (LRXOpenMsg *)pktContent->data;
		LRXAckMsg *ackMsg = (LRXAckMsg *)pktContent->data;
		LRXPkt *outPktContent = (LRXPkt *)outPkt.data;
		LRXAckMsg *outAckMsg = (LRXAckMsg *)outPktContent->data;
		dbg(DBG_USR1, "((( ReceiveMsg.receive   state = %d\n", state);
		print_pkt(msg);
		in_count(get_ctrl(pktContent->ctrlandBlockNum), ackMsg->subCtrl);

		if (state == STATE_IDLE) {
			if (history_valid && (pktContent->sourceID == prevCorrespondentID)
				&& (get_ctrl(pktContent->ctrlandBlockNum) == MSG_CTRL_DATA)) {
				
				send_prev_ack_msg();
				
				return msg;
			} else if (get_ctrl(pktContent->ctrlandBlockNum) != MSG_CTRL_OPEN) {
				return msg;
			}
		} else if (pktContent->sourceID != correspondentID) {
			if (history_valid && (pktContent->sourceID == prevCorrespondentID)
				&& (get_ctrl(pktContent->ctrlandBlockNum) == MSG_CTRL_DATA)) {
				
				send_prev_ack_msg();
				
				return msg;
			} else if (get_ctrl(pktContent->ctrlandBlockNum) == MSG_CTRL_OPEN) {
			
				send_nack_msg_busy(pktContent->sourceID);
				
				return msg;
			} else {
				return msg;
			}
		}
		
		switch (state) {
		
		case STATE_IDLE: //////////////// open
			if (signal LRXReceive.transferRequested(pktContent->sourceID,
					openMsg->numofBlock, openMsg->desc, msg->length - 4)) {
				
				//data_loss = 0;
				//ack_loss = 0;
				prevLastBlock = MAX_BLOCK_SIZE;
				transit(STATE_RECEIVE_OPEN);
				init_receive(pktContent->sourceID, openMsg->numofBlock);
				timeout = TIMEOUT_ACK;
				process_open_msg_common(msg);
				
			} else {
			
				send_ack_msg(MSG_CTRL_ACK);
				
			}
			break;
		
		case STATE_SEND_OPEN: //////////////// ack, nack
			if (ackMsg->subCtrl == MSG_CTRL_OPEN) {
			
				process_ack_msg(msg);
				
			} else {

				call LRXSend.abortSend();

			}
			break;
			
		// case STATE_SEND_DATA: break;
		
		case STATE_SEND_ACK: //////////////// ack

			process_ack_msg(msg);
			
			break;
		
		case STATE_RECEIVE_OPEN: //////////////// open, data
			if (get_ctrl(pktContent->ctrlandBlockNum) == MSG_CTRL_OPEN) {
			
				call Timer.stop();
				timeout--;
				process_open_msg_common(msg);
				
			} else {
			
				process_data_msg(msg);
				
			}
			break;
			
		case STATE_RECEIVE_DATA: //////////////// data
		
				process_data_msg(msg);
			
			break;

		case STATE_RECEIVE_ACK: //////////////// data
		
				process_data_msg(msg);
			
			break;
		
		default:
			dbg(DBG_USR3, "!!! ReceiveMsg.receive   state = %d\n", state);
			break;
		}
		return msg;
	}




	event result_t Timer.fired() {
		dbg(DBG_USR2, "[[[ Timer.fired   state = %d\n", state);
		
		switch (state) {
		// case STATE_IDLE: break;
		
		case STATE_SEND_OPEN: ////////////////
			timeout--;
			if (timeout) {
			
				send_open_msg();
				call Timer.start(TIMER_ONE_SHOT, PKT_XFER_TIME * 2);

			} else {
				call LRXSend.abortSend();
			}
			break;
		case STATE_SEND_DATA: ////////////////
			send_next_data();
			break;
		case STATE_SEND_ACK: ////////////////
			timeout--;
			if (timeout) {
			
				send_next_data();
				
			} else {
				call LRXSend.abortSend();
			}
			break;
		
		case STATE_RECEIVE_OPEN: ////////////////
			call LRXReceive.abortReceive();
			break;
		case STATE_RECEIVE_DATA: ////////////////
			call LRXReceive.abortReceive();
			break;
		case STATE_RECEIVE_ACK: ////////////////
			call LRXReceive.abortReceive();
			break;
		
		default:
			dbg(DBG_USR3, "!!! Timer.fired   state = %d\n", state);
			break;
		}
		return SUCCESS;
	}



	
	command result_t get_stats() {
		return send_count_info(TOS_UART_ADDR);
	}








// Finite State Machine Control	
	uint8_t get_ctrl(uint8_t ctrlandBlockNum) {
		return (ctrlandBlockNum & 0xc0) >> 6;
	}
	uint8_t get_blockNum(uint8_t ctrlandBlockNum) {
		return ctrlandBlockNum & 0x3f;
	}
	uint8_t combine_ctrl_and_blockNum(uint8_t ctrl, uint8_t blockNum) {
		return ((ctrl & 0x03) << 6) | (blockNum & 0x3f);
	}
	result_t write_history() {
		prevCorrespondentID = correspondentID;
		prevNumofBlock = numofBlock;
		history_valid = TRUE;
		return SUCCESS;
	}
	result_t transit(uint8_t newState) {
		state = newState;
		return SUCCESS;
	}




// Window
	result_t encode_ackBuf() {
		int i, j;
		for (i = 0; i < ackBufSize; i++) {
			uint8_t winIndex = 0x80;
			ackBuf[i] = 0;
			for (j = 0; j < 8; j++) {
				if (8 * i + j >= numofBlock) break;
				ackBuf[i] |= ackWin[8 * i + j] ? winIndex : 0;
				winIndex >>= 1;
			}
		}
		return SUCCESS;
	}
	result_t decode_ackBuf() {
		int i, j;
		for (i = 0; i < ackBufSize; i++) {
			uint8_t winIndex = 0x80;
			for (j = 0; j < 8; j++) {
				if (8 * i + j >= numofBlock) break;
				ackWin[8 * i + j] = (ackBuf[i] & winIndex) ? 1 : 0;
				winIndex >>= 1;
			}
		}
		return SUCCESS;
	}
	uint8_t next_block_num() {
		int i;
		for (i = blockIndex; i < numofBlock; i++)
			if (!ackWin[i]) break;
		return i;
	}




// Communication
	result_t send_open_msg() {
		LRXPkt *pktContent = (LRXPkt *)outPkt.data;
		LRXOpenMsg *openMsg = (LRXOpenMsg *)pktContent->data;
		pktContent->sourceID = TOS_LOCAL_ADDRESS;
		pktContent->ctrlandBlockNum =
			combine_ctrl_and_blockNum(MSG_CTRL_OPEN, TIMEOUT_OPEN - timeout);
		openMsg->numofBlock = numofBlock;
		copy_mem(desc, openMsg->desc, descSize);
		dbg(DBG_USR1, "@@@ send_open_msg    state = %d, blockNum = %d, descSize = %d\n", state, TIMEOUT_OPEN - timeout, descSize);
		out_count(MSG_CTRL_OPEN, MSG_CTRL_OPEN);
		call SendMsg.send(correspondentID, 4 + descSize, &outPkt);
		return SUCCESS;
	}
	result_t send_data_msg(uint8_t blockNum) {
		LRXPkt *pktContent = (LRXPkt *)outPkt.data;
		uint8_t blockSize;
		pktContent->sourceID = TOS_LOCAL_ADDRESS;
		pktContent->ctrlandBlockNum =
			combine_ctrl_and_blockNum(MSG_CTRL_DATA, blockNum);
		blockSize = signal LRXSend.readDataBlock(blockNum, pktContent->data);
		dbg(DBG_USR1, "@@@ send_data_msg    state = %d, blockNum = %d, blockSize = %d\n", state, blockNum, blockSize);

		//copy_mem(slotNumWin, pktContent->data, numofBlock);
		//pktContent->data[0] = slotIndex;
		//pktContent->data[1] = blockIndex;
		
		out_count(MSG_CTRL_DATA, MSG_CTRL_DATA);
		call SendMsg.send(correspondentID, 3 + blockSize, &outPkt);
		return SUCCESS;
	}
	result_t send_ack_msg(uint8_t subCtrl) {
		LRXPkt *pktContent = (LRXPkt *)outPkt.data;
		LRXAckMsg *ackMsg = (LRXAckMsg *)pktContent->data;
		pktContent->sourceID = TOS_LOCAL_ADDRESS;
		pktContent->ctrlandBlockNum =
			combine_ctrl_and_blockNum(MSG_CTRL_ACK, TIMEOUT_ACK - timeout);
		ackMsg->subCtrl = subCtrl;
		encode_ackBuf();
		copy_mem(ackBuf, ackMsg->bitVector, ackBufSize);
		dbg(DBG_USR1, "@@@ send_ack_msg    state = %d, blockNum = %d subCtrl = %d\n", state, TIMEOUT_ACK - timeout, subCtrl);
		out_count(MSG_CTRL_ACK, subCtrl);
		call SendMsg.send(correspondentID, 4 + ackBufSize, &outPkt);
		return SUCCESS;
	}
	result_t send_prev_ack_msg() {
		LRXPkt *pktContent = (LRXPkt *)outPkt.data;
		LRXAckMsg *ackMsg = (LRXAckMsg *)pktContent->data;
		uint8_t prevAckBufSize = (prevNumofBlock + 7) / 8;
		int i, j;
		pktContent->sourceID = TOS_LOCAL_ADDRESS;
		pktContent->ctrlandBlockNum =
			combine_ctrl_and_blockNum(MSG_CTRL_ACK, 0);
		ackMsg->subCtrl = MSG_CTRL_DATA;
		for (i = 0; i < prevAckBufSize; i++) {
			uint8_t winIndex = 0x80;
			ackMsg->bitVector[i] = 0;
			for (j = 0; j < 8; j++) {
				if (8 * i + j >= prevNumofBlock) break;
				ackMsg->bitVector[i] |= winIndex;
				winIndex >>= 1;
			}
		}
		dbg(DBG_USR1, "@@@ send_prev_ack_msg    state = %d, blockNum = %d subCtrl = %d\n", state, TIMEOUT_ACK - timeout, MSG_CTRL_DATA);
		out_count(MSG_CTRL_ACK, MSG_CTRL_DATA);
		call SendMsg.send(prevCorrespondentID, 4 + prevAckBufSize, &outPkt);
		return SUCCESS;
	}
	result_t send_nack_msg_busy(uint16_t sourceID) {
		LRXPkt *pktContent = (LRXPkt *)outPkt.data;
		LRXAckMsg *ackMsg = (LRXAckMsg *)pktContent->data;
	
		pktContent->sourceID = TOS_LOCAL_ADDRESS;
		pktContent->ctrlandBlockNum =
			combine_ctrl_and_blockNum(MSG_CTRL_ACK, 0);
		ackMsg->subCtrl = MSG_CTRL_ACK;
		dbg(DBG_USR1, "@@@ send_nack_msg_busy    state = %d, blockNum = %d subCtrl = %d\n", state, TIMEOUT_ACK - timeout, MSG_CTRL_ACK);
		out_count(MSG_CTRL_ACK, MSG_CTRL_ACK);
		call SendMsg.send(sourceID, 4, &outPkt);
		return SUCCESS;
	}




// Overall
	result_t init_send(uint16_t destID, uint8_t aNumofBlock,
		uint8_t *aDesc, uint16_t aDescSize) {
		correspondentID = destID;
		numofBlock = aNumofBlock;
		desc = aDesc;
		descSize = aDescSize;
		ackBufSize = (numofBlock + 7) / 8;
		clear_mem(ackWin, numofBlock);
		encode_ackBuf();
		update_slotNumWin();
		return SUCCESS;
	}
	result_t init_receive(uint16_t sourceID, uint8_t aNumofBlock) {
		correspondentID = sourceID;
		numofBlock = aNumofBlock;
		ackBufSize = (numofBlock + 7) / 8;
		clear_mem(ackWin, numofBlock);
		encode_ackBuf();
		update_slotNumWin();
		return SUCCESS;
	}

	result_t process_open_msg_common(TOS_MsgPtr msg) {
		//open_loss++;
		//if (open_loss % 2 != 0) return FAIL;
		dbg(DBG_USR1, "### process_open_msg_common\n");
		send_ack_msg(MSG_CTRL_OPEN);
		call Timer.start(TIMER_ONE_SHOT, PKT_XFER_TIME * 2 * TIMEOUT_OPEN);
		return SUCCESS;
	}
	result_t process_data_msg(TOS_MsgPtr msg) {
		LRXPkt *pktContent = (LRXPkt *)msg->data;
		//data_loss++;
		//if (data_loss % 2 != 0) return FAIL;
		dbg(DBG_USR1, "### process_data_msg\n");
		blockIndex = get_blockNum(pktContent->ctrlandBlockNum);
		call Timer.stop();
		if (!ackWin[blockIndex]) { // unseen message
		
			dbg(DBG_USR2, "*** unseen message\n");
			signal LRXReceive.writeDataBlock(blockIndex, pktContent->data,
				msg->length - 3);
			ackWin[blockIndex] = 1;
			slotIndex++;
			print_window_info();
			
			if (slotNumWin[blockIndex] == numofSlot - 1) { // last slot
			
				dbg(DBG_USR2, "*** last slot\n");
				prevLastBlock = blockIndex;
				update_slotNumWin();
				timeout = TIMEOUT_ACK;
				if (!numofSlot) { // every block delivered
				
					dbg(DBG_USR2, "*** full\n");
					write_history();
					transit(STATE_IDLE);
					send_ack_msg(MSG_CTRL_DATA);
					call Timer.stop();
					signal LRXReceive.acceptedTransferDone(SUCCESS);
					
				} else {
				
					dbg(DBG_USR2, "*** some lost packets\n");
					transit(STATE_RECEIVE_ACK);
					send_ack_msg(MSG_CTRL_DATA);
					call Timer.start(TIMER_ONE_SHOT,
						PKT_XFER_TIME * 2 * TIMEOUT_ACK);

				}
			} else { // not last slot
		
				dbg(DBG_USR2, "*** not last slot\n");
				transit(STATE_RECEIVE_DATA);
				call Timer.start(TIMER_ONE_SHOT,
					PKT_XFER_TIME * 2 * TIMEOUT_DATA);
			
			}
		} else if (blockIndex == prevLastBlock) { // previous round
		
			dbg(DBG_USR2, "*** previous round\n");
			transit(STATE_RECEIVE_ACK);
			send_ack_msg(MSG_CTRL_DATA);
			timeout--;
			call Timer.start(TIMER_ONE_SHOT, PKT_XFER_TIME * 2 * TIMEOUT_ACK);
			
		} else { // not new, nor last packet of previous round
		
			dbg(DBG_USR3, "!!! process_data_msg\n");

		}
		return SUCCESS;
	}
	result_t process_ack_msg(TOS_MsgPtr msg) {
		LRXPkt *pktContent = (LRXPkt *)msg->data;
		LRXAckMsg *ackMsg = (LRXAckMsg *)pktContent->data;
		//ack_loss++;
		//if (ack_loss % 2 != 0) return FAIL;
		dbg(DBG_USR1, "### process_ack_msg\n");
		call Timer.stop();
		copy_mem(ackMsg->bitVector, ackBuf, ackBufSize);
		decode_ackBuf();
		update_slotNumWin();
		if (numofSlot) { // still some blocks are missing
		
			timeout = TIMEOUT_ACK;
			send_next_data();

		} else { // every block is transfered
		
			transit(STATE_IDLE);
			call Timer.stop();
			signal LRXSend.transferDone(desc, SUCCESS);
			
		}
		return SUCCESS;
	}
	result_t send_next_data() {
		blockIndex = next_block_num();
		send_data_msg(blockIndex);
		if (slotIndex == numofSlot - 1) { // NO more data to send
		
			transit(STATE_SEND_ACK);
			call Timer.start(TIMER_ONE_SHOT, PKT_XFER_TIME * 2);
			
		} else { // more data to send
		
			blockIndex++;
			slotIndex++;
			transit(STATE_SEND_DATA);
			call Timer.start(TIMER_ONE_SHOT, SEND_DATA_INTERVAL);
			
		}
		return SUCCESS;
	}
	result_t update_slotNumWin() {
		int i;
		numofSlot = 0;
		clear_mem(slotNumWin, numofBlock);
		for (i = 0; i < numofBlock; i++) {
			if (ackWin[i]) continue;
			slotNumWin[i] = numofSlot;
			numofSlot++;
		}
		blockIndex = 0;
		slotIndex = 0;
		dbg(DBG_USR2, "$$$ update_slotNumWin    numofSlot = %d\n", numofSlot);
		print_window_info();
		return SUCCESS;
	}




// Etc
	result_t clear_mem(uint8_t *memArray, uint8_t clearSize) {
		int i;
		for (i = 0; i < clearSize; i++)
			memArray[i] = 0;
		return SUCCESS;
	}
	result_t copy_mem(uint8_t *copySrc, uint8_t *copyDest, uint8_t copySize) {
		int i;
		for (i = 0; i < copySize; i++)
			copyDest[i] = copySrc[i];
		return SUCCESS;
	}




// Debug
	result_t check_receive(TOS_MsgPtr msg) {
		LRXPkt *pktContent = (LRXPkt *)msg->data;
		LRXOpenMsg *openMsg = (LRXOpenMsg *)pktContent->data;
		LRXAckMsg *ackMsg = (LRXAckMsg *)pktContent->data;
		uint16_t dbgSourceID = pktContent->sourceID;
		uint8_t dbgCtrl = get_ctrl(pktContent->ctrlandBlockNum);
		uint8_t dbgBlockNum = get_blockNum(pktContent->ctrlandBlockNum);
		
		dbg(DBG_USR2, "~~~ check_receive\n");
		
		if ((dbgSourceID != correspondentID) &&
			(dbgSourceID != prevCorrespondentID))
			dbg(DBG_USR3, "sourceID = %d\n", dbgSourceID);
		if ((dbgCtrl != MSG_CTRL_OPEN) &&
			(dbgCtrl != MSG_CTRL_DATA) &&
			(dbgCtrl != MSG_CTRL_ACK))
			dbg(DBG_USR3, "ctrl = %d\n", dbgCtrl);
		if (dbgBlockNum >= numofBlock)
			dbg(DBG_USR3, "blockNum = %d\n", dbgBlockNum);

		if (dbgCtrl == MSG_CTRL_OPEN) {
			if (openMsg->numofBlock > MAX_WINDOW_SIZE)
				dbg(DBG_USR3, "numofBlock = %d\n", openMsg->numofBlock);
		}
		if (dbgCtrl == MSG_CTRL_ACK) {
			if ((ackMsg->subCtrl != MSG_CTRL_OPEN) &&
				(ackMsg->subCtrl != MSG_CTRL_DATA) &&
				(ackMsg->subCtrl != MSG_CTRL_ACK))
				dbg(DBG_USR3, "subCtrl = %d\n", ackMsg->subCtrl);
		}
	
		switch (state) {
		case STATE_IDLE:
			if (dbgCtrl != MSG_CTRL_OPEN)
				dbg(DBG_USR3, "state = %d, ctrl = %d\n", state, dbgCtrl);
			break;
		case STATE_SEND_OPEN:
			if ((dbgCtrl != MSG_CTRL_ACK) ||
				((ackMsg->subCtrl != MSG_CTRL_OPEN) &&
				 (ackMsg->subCtrl != MSG_CTRL_ACK)))
				dbg(DBG_USR3, "state = %d, ctrl = %d, subCtrl = %d\n",
					state, dbgCtrl, ackMsg->subCtrl);
			break;
		case STATE_SEND_DATA:
				dbg(DBG_USR3, "state = %d, ctrl = %d\n", state, dbgCtrl);
			break;
		case STATE_SEND_ACK:
			if ((dbgCtrl != MSG_CTRL_ACK) ||
				(ackMsg->subCtrl != MSG_CTRL_DATA))
				dbg(DBG_USR3, "state = %d, ctrl = %d\n", state, dbgCtrl);
			break;
		case STATE_RECEIVE_OPEN:
			if ((dbgCtrl != MSG_CTRL_OPEN) &&
				(dbgCtrl != MSG_CTRL_DATA))
				dbg(DBG_USR3, "state = %d, ctrl = %d\n", state, dbgCtrl);
			break;
		case STATE_RECEIVE_DATA: break;
			if (dbgCtrl != MSG_CTRL_DATA)
				dbg(DBG_USR3, "state = %d, ctrl = %d\n", state, dbgCtrl);
			break;
		case STATE_RECEIVE_ACK:
			if (dbgCtrl != MSG_CTRL_DATA)
				dbg(DBG_USR3, "state = %d, ctrl = %d\n", state, dbgCtrl);
			break;
		default:
			dbg(DBG_USR3, "state = %d\n", state);
			break;
		}
		dbg(DBG_USR2, "~~~ end of check_receive\n");
		return SUCCESS;
	}
	result_t print_pkt(TOS_MsgPtr msg) {
		LRXPkt *pktContent = (LRXPkt *)msg->data;
		LRXOpenMsg *openMsg = (LRXOpenMsg *)pktContent->data;
		LRXAckMsg *ackMsg = (LRXAckMsg *)pktContent->data;
		uint8_t ctrl = get_ctrl(pktContent->ctrlandBlockNum);
		dbg(DBG_USR2, "=== print_pkt    sourceID = %d, ctrl = %d, blockNum = %d\n",
			pktContent->sourceID, ctrl,
			get_blockNum(pktContent->ctrlandBlockNum));
		if (ctrl == MSG_CTRL_OPEN) {
			dbg(DBG_USR2, "=== OPEN    numofBlock = %d\n", openMsg->numofBlock);
		} else if (ctrl == MSG_CTRL_DATA) {
			dbg(DBG_USR2, "=== DATA    size = %d\n", msg->length - 3);
		} else if (ctrl == MSG_CTRL_ACK) {
			dbg(DBG_USR2, "=== ACK    subCtrl = %d\n", ackMsg->subCtrl);
		}
		return SUCCESS;
	}
	result_t print_window_info() {
		int i;

		dbg(DBG_USR2, "--- print_window_info\n");
		
		dbg(DBG_USR2, "--- ackBuf");
		for (i = 0; i < ackBufSize; i++)
			dbg(DBG_USR2, " %d", ackBuf[i]);
//		dbg(DBG_USR2, "\n");
		
		dbg(DBG_USR2, "--- ackWin");
		for (i = 0; i < numofBlock; i++)
			dbg(DBG_USR2, " %d", ackWin[i]);
//		dbg(DBG_USR2, "\n");
		
		dbg(DBG_USR2, "--- slotNumWin");
		for (i = 0; i < numofBlock; i++)
			dbg(DBG_USR2, " %d", slotNumWin[i]);
//		dbg(DBG_USR2, "\n");

		return SUCCESS;
	}
	result_t out_count(uint8_t outCtrl, uint8_t outSubCtrl) {
		if (outCtrl == MSG_CTRL_OPEN) { out_open_count++;
		} else if (outCtrl == MSG_CTRL_DATA) { out_data_count++;
		} else if (outCtrl != MSG_CTRL_ACK) { out_error_count++;
		} else if (outSubCtrl == MSG_CTRL_OPEN) { out_ao_count++;
		} else if (outSubCtrl == MSG_CTRL_DATA) { out_ad_count++;
		} else if (outSubCtrl == MSG_CTRL_ACK) { out_aa_count++;
		} else { out_error_count++;
		}
		return SUCCESS;
	}
	result_t in_count(uint8_t inCtrl, uint8_t inSubCtrl) {
		if (inCtrl == MSG_CTRL_OPEN) { in_open_count++;
		} else if (inCtrl == MSG_CTRL_DATA) { in_data_count++;
		} else if (inCtrl != MSG_CTRL_ACK) { in_error_count++;
		} else if (inSubCtrl == MSG_CTRL_OPEN) { in_ao_count++;
		} else if (inSubCtrl == MSG_CTRL_DATA) { in_ad_count++;
		} else if (inSubCtrl == MSG_CTRL_ACK) { in_aa_count++;
		} else { in_error_count++;
		}
		return SUCCESS;
	}
	result_t send_count_info(uint16_t destID) {
		outPkt.data[0] = out_open_count; outPkt.data[1] = out_open_count >> 8;
		outPkt.data[2] = out_data_count; outPkt.data[3] = out_data_count >> 8;
		outPkt.data[4] = out_ao_count; outPkt.data[5] = out_ao_count >> 8;
		outPkt.data[6] = out_ad_count; outPkt.data[7] = out_ad_count >> 8;
		outPkt.data[8] = out_aa_count; outPkt.data[9] = out_aa_count >> 8;
		outPkt.data[10] = out_error_count; outPkt.data[11]
			= out_error_count >> 8;

		outPkt.data[12] = in_open_count; outPkt.data[13] = in_open_count >> 8;
		outPkt.data[14] = in_data_count; outPkt.data[15] = in_data_count >> 8;
		outPkt.data[16] = in_ao_count; outPkt.data[17] = in_ao_count >> 8;
		outPkt.data[18] = in_ad_count; outPkt.data[19] = in_ad_count >> 8;
		outPkt.data[20] = in_aa_count; outPkt.data[21] = in_aa_count >> 8;
		outPkt.data[22] = in_error_count; outPkt.data[23]
			= in_error_count >> 8;

		call SendMsg.send(destID, 24, &outPkt);
		return SUCCESS;
	}

}


