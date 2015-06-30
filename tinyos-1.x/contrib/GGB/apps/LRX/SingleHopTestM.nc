// $Id: SingleHopTestM.nc,v 1.4 2006/12/01 00:04:09 binetude Exp $

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

#define MAX_ARRAY_SIZE 64
#define TOTAL_NUMBER_OF_BLOCK 256
module SingleHopTestM {
	provides {
		interface StdControl;
	}
	uses {
		interface LRXSend;
		interface LRXReceive;

		interface Timer;
		interface SendMsg;
		interface ReceiveMsg;
		interface Leds;

		command result_t get_stats();
	}
}
implementation {
	bool isSender;
	uint8_t blockArray[MAX_ARRAY_SIZE][MAX_BLOCK_SIZE];
	uint8_t blockSize[MAX_ARRAY_SIZE];
	uint8_t desc[MAX_BLOCK_SIZE];
	uint8_t descSize;

	uint8_t numofBlock;

	uint8_t debug_count;
	bool rwCheck[MAX_BLOCK_SIZE];
	TOS_Msg outPkt;

	uint16_t repeatIndex;
	uint16_t outSuccess;
	uint16_t inSuccess;
	
	result_t init_sender();
	result_t init_receiver();
	result_t verify_receiver();
	result_t clear_mem(uint8_t *memArray, uint8_t clearSize);
	result_t copy_mem(uint8_t *copySrc, uint8_t *copyDest, uint8_t copySize);

	result_t print_memory();
	result_t init_rwCheck();
	result_t verify_rwCheck();
	result_t number_packet(uint8_t fisrtNum, uint8_t secondNum);
	
	command result_t StdControl.init() {
		call Leds.init();
		return SUCCESS;
	}
	command result_t StdControl.start() {
		call Leds.redOff();
		call Leds.greenOff();
		call Leds.yellowOff();
		outSuccess = 0;
		inSuccess = 0;
		if (TOS_LOCAL_ADDRESS == 0)
			init_sender();
		else
			init_receiver();
		return SUCCESS;
	}
	command result_t StdControl.stop() {
		return SUCCESS;
	}

	task void new_transfer_task() {
		call LRXSend.transfer(1, numofBlock, desc, descSize);
	}
	
	event result_t LRXSend.transferDone(uint8_t *aDesc, result_t success) {
		dbg(DBG_USR2, "\"\"\" LRXSend.transferDone    success = %d\n", success);
		repeatIndex--;
		if (success) outSuccess++;
		if (repeatIndex) {
			call Leds.redToggle();
			//call LRXSend.transfer(1, numofBlock, desc, descSize);
			//post new_transfer_task();
			call Timer.start(TIMER_ONE_SHOT, 1000);
		} else {
			call Leds.redOff();
		}
		/*
		if (!success) call Leds.redOn();
		if (!verify_rwCheck()) call Leds.redOn();
		*/
		return SUCCESS;
	}
	event uint8_t LRXSend.readDataBlock(uint8_t blockNum, uint8_t *blockBuf) {
		dbg(DBG_USR2, "\"\"\" LRXSend.readDataBlock    blockNum = %d\n", blockNum);
		call Leds.redToggle();
		debug_count++;
		rwCheck[blockNum] = TRUE;

		copy_mem(blockArray[blockNum], blockBuf, blockSize[blockNum]);
		return blockSize[blockNum];
	}

	event result_t LRXReceive.transferRequested(uint16_t sourceID,
		uint8_t aNumofBlock, uint8_t *aDesc, uint8_t aDescSize) {
		dbg(DBG_USR2, "\"\"\" LRXReceive.transferRequested    sourceID = %d, numofBlock = %d\n", sourceID, aNumofBlock);
//		call Leds.redOff();
//		call Leds.greenOff();
//		call Leds.yellowOff();
		debug_count = 0;

		call Leds.redToggle();
		copy_mem(aDesc, desc, aDescSize);
		numofBlock = aNumofBlock;
		descSize = aDescSize;
		init_rwCheck();
		return SUCCESS;
	}
	event result_t LRXReceive.acceptedTransferDone(result_t success) {
		dbg(DBG_USR2, "\"\"\" LRXReceive.acceptedTransferDone    success = %d\n", success);
		if (success) inSuccess++;
		call Leds.redOff();
		/*
		if (!success) call Leds.redOn();
		if (!verify_rwCheck()) call Leds.redOn();
		//print_memory();
		if (verify_receiver()) {
			dbg(DBG_USR2, "%%%%%% verify_receiver SUCCESS\n");
		} else {
			dbg(DBG_USR2, "%%%%%% verify_receiver FAIL\n");
			call Leds.yellowOn();
		}
		*/
		return SUCCESS;
	}
	event result_t LRXReceive.writeDataBlock(uint8_t blockNum,
		uint8_t *blockBuf, uint8_t aBlockSize) {
		dbg(DBG_USR2, "\"\"\" LRXReceive.writeDataBlock    blockNum = %d\n", blockNum);
		call Leds.redToggle();
		debug_count++;
		rwCheck[blockNum] = TRUE;

		copy_mem(blockBuf, blockArray[blockNum], aBlockSize);
		blockSize[blockNum] = aBlockSize;
		return SUCCESS;
	}
	
	event result_t Timer.fired() {
		//call Leds.redOff();
		//call Leds.greenOff();
		//call Leds.yellowOff();
		//debug_count = 0;
		//init_rwCheck();

		if (isSender) {
			call LRXSend.transfer(1, numofBlock, desc, descSize);
//			if (call LRXSend.transfer(1, numofBlock, desc, descSize)) {
//				call Leds.redOn();
//			}
		}
		return SUCCESS;
	}
	

	event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
		return SUCCESS;
	}
	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
		struct SimpleCmdMsg *msgContent = (struct SimpleCmdMsg *) msg->data;
		int arrayIndex = msgContent->args.ss_args.interval;
		int i;
		
		call Leds.greenToggle();
		if (arrayIndex == 99) {
			if (isSender) {
				debug_count = 0;
				init_rwCheck();
				descSize = 0;
				numofBlock = msgContent->args.ss_args.nsamples;
				repeatIndex = TOTAL_NUMBER_OF_BLOCK
					/ msgContent->args.ss_args.nsamples;
				for (i = 0; i < numofBlock; i++) {
					blockSize[i] = MAX_BLOCK_SIZE;
				}
				call Leds.redOn();
				call LRXSend.transfer(1, numofBlock, desc, descSize);
			}
		} else if (arrayIndex == 101) {
			call get_stats();
		} else if (arrayIndex == 102) {
			copy_mem(blockSize, outPkt.data, MAX_ARRAY_SIZE);
			call SendMsg.send(TOS_UART_ADDR, MAX_BLOCK_SIZE, &outPkt);
		} else if (arrayIndex == 103) {
			copy_mem(desc, outPkt.data, MAX_BLOCK_SIZE);
			call SendMsg.send(TOS_UART_ADDR, MAX_BLOCK_SIZE, &outPkt);
		} else if (arrayIndex == 104) {
			outPkt.data[0] = numofBlock; outPkt.data[1] = 0;
			outPkt.data[2] = repeatIndex; outPkt.data[3] = repeatIndex << 8;
			outPkt.data[4] = outSuccess; outPkt.data[5] = outSuccess << 8;
			outPkt.data[6] = inSuccess; outPkt.data[7] = inSuccess << 8;
			call SendMsg.send(TOS_UART_ADDR, 8, &outPkt);
		} else if (arrayIndex == 120) {
		} else {
			copy_mem(blockArray[arrayIndex], outPkt.data, MAX_BLOCK_SIZE);
			call SendMsg.send(TOS_UART_ADDR, MAX_BLOCK_SIZE, &outPkt);
		}
		return msg;
	}



	
	result_t init_sender() {
		int i, j;
		isSender = TRUE;
		numofBlock = 11;
		for (i = 0; i < numofBlock; i++) {
			blockSize[i] = 2 * (i + 1);
			for (j = 0; j < blockSize[i]; j++) {
				blockArray[i][j] = 0x10 * (i + 1) + (j + 1);
			}
		}
		descSize = 5;
		for (i = 0; i < descSize; i++)
			desc[i] = 0xf0 + (16 - i - 1);
//		call Timer.start(TIMER_ONE_SHOT, 1000);
		//call LRXSend.transfer(1, numofBlock, desc, descSize);
		dbg(DBG_USR2, "%%%%%% Sender\n");
		//print_memory();
		return SUCCESS;
	}
	result_t init_receiver() {
		int i, j;
		isSender = FALSE;
		numofBlock = 7;
		for (i = 0; i < MAX_ARRAY_SIZE; i++) {
			blockSize[i] = i + 1;
			for (j = 0; j < MAX_BLOCK_SIZE; j++) {
				blockArray[i][j] = 0x08 * i + j;
			}
		}
		descSize = 7;
		for (i = 0; i < MAX_BLOCK_SIZE; i++)
			desc[i] = 0x20 + i;
		dbg(DBG_USR2, "%%%%%% Receiver\n");
		//print_memory();
		return SUCCESS;
	}
	result_t verify_receiver() {
		int i = 0;
		int j = 0;
		for (i = 0; i < numofBlock; i++) {
			for (j = 0; j < blockSize[i]; j++) {
				if (blockArray[i][j] != 0x10 * (i + 1) + (j + 1)) {
					number_packet(i, j);
					return FAIL;
				}
			}
			for (; j < MAX_BLOCK_SIZE; j++) {
				if (blockArray[i][j] != 0x08 * i + j) {
					number_packet(i, j);
					return FAIL;
				}
			}
		}
		for (; i < MAX_ARRAY_SIZE; i++) {
			for (j = 0; j < MAX_BLOCK_SIZE; j++) {
				if (blockArray[i][j] != 0x08 * i + j) {
					number_packet(i, j);
					return FAIL;
				}
			}
		}
		for (i = 0; i < descSize; i++) {
			if (desc[i] != 0xf0 + (16 - i - 1)) {
				number_packet(i, j);
				return FAIL;
			}
		}
		for (; i < MAX_BLOCK_SIZE; i++) {
			if (desc[i] != 0x20 + i) {
				number_packet(i, j);
				return FAIL;
			}
		}
		//print_memory();
		return SUCCESS;
	}
	
	
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
	
	result_t print_memory() {
		int i, j;
		dbg(DBG_USR2, "%%%%%% print_memory\n");
		dbg(DBG_USR2, "numofBlock = %d, descSize = %d\n", numofBlock, descSize);
		dbg(DBG_USR2, "blockArray\n");
		for (i = 0; i < MAX_ARRAY_SIZE; i++) {
			dbg(DBG_USR2, "blockSize[%d] = %d\n", i, blockSize[i]);
			for (j = 0; j < MAX_BLOCK_SIZE; j++) {
				dbg(DBG_USR2, "%x ", blockArray[i][j]);
			}
			dbg(DBG_USR2, "\n");
		}
		
		dbg(DBG_USR2, "desc(%d) ", descSize);
		for (i = 0; i < MAX_BLOCK_SIZE; i++) {
			dbg(DBG_USR2, "%x ", desc[i]);
		}
		dbg(DBG_USR2, "\n");
		dbg(DBG_USR2, "%%%%%% end of print_memory\n");
		return SUCCESS;
	}
	result_t init_rwCheck() {
		int i;
		for (i = 0; i < numofBlock; i++) {
			rwCheck[i] = FALSE;
		}
		return SUCCESS;
	}
	result_t verify_rwCheck() {
		int i;
		for (i = 0; i < numofBlock; i++) {
			if (!rwCheck[i]) return FAIL;
		}
		return SUCCESS;
	}
	result_t number_packet(uint8_t fisrtNum, uint8_t secondNum) {
		outPkt.data[0] = fisrtNum;
		outPkt.data[1] = secondNum;
		call SendMsg.send(TOS_UART_ADDR, 2, &outPkt);
		return SUCCESS;
	}
	
}


