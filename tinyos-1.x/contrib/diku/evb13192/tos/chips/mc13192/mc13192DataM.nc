/* Copyright (c) 2006, Jan Flora <janflora@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
  @author Jan Flora <janflora@diku.dk>
*/

#include <mcuToRadioPorts.h>

module mc13192DataM {
	provides {
		interface StdControl;
		interface mc13192Send as Send;
		interface mc13192Receive as Recv;
		interface mc13192StreamEvents as StreamOp;
		interface mc13192CCA as CCA;
	}
	uses {
		interface mc13192State as State;
		interface mc13192DataInterrupt as Interrupt;
		interface FastSPI as SPI;
		interface mc13192Regs as Regs;
		interface mc13192TimerCounter as Time;
		interface mc13192EventTimer as EventTimer;
		interface mc13192Timer as Timer1;
		interface Debug;
	}
}
implementation
{
	// Level 1 = List function calls.
	// Level 2 = Function calls + return values.
	// Level 3 = Extensive debug.
	#define DBG_LEVEL 4
	#define DBG_MIN_LEVEL 4
	#include "Debug.h"

	// Globals
	receiveItem_t recvItemBuffer[RX_QUEUE_SIZE];
	uint8_t recvHead = 0;
	uint8_t recvCount = RX_QUEUE_SIZE;
	uint8_t recvQueueSize = RX_QUEUE_SIZE;

	// These are all protected by the opMode semaphore.
	// (note: The IRQ interrupt handler is NOT reentrant)..
	
	// RX packet variables
	receiveItem_t *rxPacket;

	// TX packet variables
	norace uint8_t *txPacket;
	norace uint8_t txLength;
	
	norace uint8_t dataTransferMode = PACKET_MODE;
	norace uint8_t *nextByte;
	norace uint8_t *lastByte;

	// CCA globals
	uint8_t ccaType;

	// There are no race conditions on this semaphore,
	// since it is locked in sync context.
	norace uint8_t opMode = NO_OPERATION;

	// RX buffer queue variables
	uint8_t *bufQueue[RX_BUFFER_QUEUE_SIZE];
	uint8_t bufHead = 0;
	uint8_t bufCount = 0;
	uint8_t queueSize = RX_BUFFER_QUEUE_SIZE;
	
	// 802.15.4 acknowledgement support.
	bool ackedOperation = FALSE;
	uint8_t seqNum;
	uint8_t ackWaitTime = 54;
	uint8_t ackFrame[2] = {0x02, 0x00};
	bool acking = FALSE;
	
	// 802.15.4 filter parameters.
	uint8_t filterPanId[2] = {0xDE, 0xFE};
	uint8_t filterShortAddr[2] = {0x1F, 0x00};
	uint8_t filterExtAddr[8] = {0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09};
	
	// 802.15.4 filtering.
	mhrFrameControl_t *rxFrameControl;
	uint8_t rxDstAddrLength;
	uint8_t *filterValue;
	uint8_t rxSeqNum;
	bool (*filterWord)(uint8_t*);
	bool ackFilter(uint8_t *data);
	bool headerFilter(uint8_t *data);
	bool seqNumFilter(uint8_t *data);
	bool dstPanFilter(uint8_t *data);
	bool dstAddrFilter(uint8_t *data);
	bool srcPanFilter(uint8_t *data);
	bool dummyFilter(uint8_t *dummy) { return TRUE; }
	
	// Forward function declarations
	void prepareTxBuffer(uint8_t *packet, uint8_t length);
	result_t prepareRxBuffer();
	result_t send();
	result_t receive();
	uint8_t getCCAFinal();
	inline void abortOperation();
	void writeTXPacketLength();
	bool readRXPacketLength();
	void writeTXPacket();
	void readRXPacket();
	void finishStreamOperation();
	void finalizeReceive();
	void finalizeSend(result_t status);

	/* **********************************************************************
	 * Setup/Init code
	 * *********************************************************************/

	/* Init */
	command result_t StdControl.init()
	{
		return SUCCESS;
	}

	/* start */
	command result_t StdControl.start()
	{
		// Set registers according to chosen mode
		// of operation.
		if (dataTransferMode == STREAM_MODE) {
			uint16_t reg;
			// Enable stream mode.
			reg = call Regs.read(CONTROL_B);
			reg |= 0x0020;
			call Regs.write(CONTROL_B, reg);
			// Enable stream error reporting.
			reg = call Regs.read(IRQ_MASK);
			reg |= 0x0400;
			call Regs.write(IRQ_MASK, reg);
			call Interrupt.enableStreamMode();
		}
		return SUCCESS;
	}

	/* stop - never called */
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	command result_t Recv.initRxQueue(uint8_t *packetBuf)
	{
		if (bufCount >= queueSize) {
			//DBG_STR("No more room for buffers in RX queue",2);
			return FAIL;
		}
		bufQueue[(bufHead+bufCount)%queueSize] = packetBuf;
		bufCount++;
		return SUCCESS;
	}
	
	command void Send.prepareData(uint8_t *packet, uint8_t length, bool ack, uint8_t mode)
	{
		// Write the TX packet length!
		uint16_t reg;
		reg = call Regs.read(TX_PKT_CTL);
		reg = (0xFF80 & reg) | (length+2); // Include 2 CRC bytes.
		call Regs.write(TX_PKT_CTL, reg);
		ackedOperation = ack;
		seqNum = packet[2];
		
		if (mode == PACKET_MODE) {
			uint8_t i = 0;		
			// Not pretty, but fast!
			// Worst case write is 31 symbol periods.
			TOSH_CLR_RADIO_CE_PIN();
			call SPI.fastWriteByte(TX_PKT_RAM);
			while (i<length) {
				call SPI.fastWriteWordSwapped(packet+i);
				i += 2;
			}
			TOSH_SET_RADIO_CE_PIN();
			if (dataTransferMode != mode) {
				//reg = call Regs.read(CONTROL_B);
				//reg &= 0xFFDF;
				//call Regs.write(CONTROL_B, reg);
				call Regs.write(CONTROL_B, 0x7C00);
				call Interrupt.disableStreamMode();
				dataTransferMode = mode;
			}
		} else {
			// assume stream mode.
			// Write first word to packet ram.
			call Regs.seqWriteStart(TX_PKT_RAM);
			call Regs.seqWriteWord(packet);
			call Regs.seqEnd();
			nextByte = txPacket = packet+2;
			txLength = length;
			lastByte = packet + length;
			// Enable stream mode.
			if (dataTransferMode != mode) {
				// Enable stream mode.
				//reg = call Regs.read(CONTROL_B);
				//reg |= 0x0020;
				//call Regs.write(CONTROL_B, reg);
				call Regs.write(CONTROL_B, 0x7C20);
				call Interrupt.enableStreamMode();
				dataTransferMode = mode;
			}
		}
	}

	command void Send.ccaSend(uint8_t numCca)
	{
		uint16_t mode;

		if (numCca == 1) {
			mode = TX_CCA_MODE1;
		} else {
			// assume 2.
			mode = TX_CCA_MODE2;
		}
		opMode = TX_OPERATION;
		if (call EventTimer.isSet()) mode |= 0x0080;
		TOSH_CLR_RADIO_RXTXEN_PIN();
		call Regs.write(CONTROL_A, mode);
		TOSH_SET_RADIO_RXTXEN_PIN();
	}
	
	command void Send.send()
	{
		uint16_t mode;
		
		if (dataTransferMode == STREAM_MODE) {
			mode = TX_STRM_MODE;
		} else {
			mode = TX_MODE;
		}
		opMode = TX_OPERATION;
		if (call EventTimer.isSet()) mode |= 0x0080;
		TOSH_CLR_RADIO_RXTXEN_PIN();
		call Regs.write(CONTROL_A, mode);
		TOSH_SET_RADIO_RXTXEN_PIN();
	}

/*	command result_t Send.send(uint8_t *packet, uint8_t length)
	{
		DBG_STR("Packet length is:",3);
		DBG_INT(length,3);

		// We can't send if another operation is already going on.
		if (opMode) {
			DBG_STR("Operation already in progress:",2);
			DBG_INT(opMode,2);
			return FAIL;
		}
		// Data can only be sent 125 bytes at a time!
		if (length > 125) {
			DBG_STR("Packet too big (>125 bytes)",2);
			return FAIL;
		}
		
		opMode = TX_OPERATION;
		
		prepareTxBuffer(packet, length);
		prepareRxBuffer();
		return send();
	}*/
	
	default async event void Send.sendDone(uint8_t *packet, result_t status) {}
	
	command result_t Recv.enableReceiver()
	{
		if (opMode) {
			DBG_STR("Operation already in progress:",2);
			DBG_INT(opMode,2);
			return FAIL;
		}
		opMode = RX_OPERATION;
		call Time.resetTimerCounter();

		if (prepareRxBuffer() == FAIL)
		{
			DBG_STR("No more buffers in RX buffer queue",2);
			return FAIL;
		}
		filterWord = headerFilter;
		return receive();
	}
	
	// Disable receiver forces radio into idle mode
	command void Recv.disableReceiver()
	{
		bool wasTimedRecv;

		if (opMode == TX_OPERATION || opMode == NO_OPERATION) {
			DBG_STR("Radio already idle, or currently transmitting",2);
			return;
		}

		// Put buffer back.
		bufQueue[(bufHead+bufCount)%queueSize] = rxPacket->buffer;
		bufCount++;
		recvCount++;

		abortOperation();
	}
	
	default async event uint8_t* Recv.dataReady(uint8_t *packet, uint8_t length, bool crc, uint8_t lqi) {return packet;}
	
	command result_t CCA.energyDetect()
	{
		if (opMode) {
			DBG_STR("Operation already in progress:",2);
			DBG_INT(opMode,2);
			return FAIL;
		}
		
		opMode = CCA_OPERATION;
		ccaType = ENERGY_DETECT;
		call State.setEDMode(dataTransferMode);
		return SUCCESS;
	}
	
	default async event void CCA.energyDetectDone(uint8_t power) {}

	command result_t CCA.clearChannelAssessment(uint8_t threshold)
	{
		uint16_t ccaCtl;

		if (opMode) {
			DBG_STR("Operation already in progress:",2);
			DBG_INT(opMode,2);
			return FAIL;
		}
		
		opMode = CCA_OPERATION;
		ccaCtl = threshold;
		ccaCtl = (ccaCtl << 8);
		ccaCtl |= (call Regs.read(CCA_THRESH) & 0x00FF);
		call Regs.write(CCA_THRESH, ccaCtl);

		ccaType = CLEAR_CHANNEL_ASSESSMENT;

		return call State.setCCAMode(dataTransferMode);
	}

	default async event void CCA.clearChannelAssessmentDone(bool isClear) {}

	
	default async event void StreamOp.rxStart() {}
	default async event void StreamOp.rxEnd() {}
	default async event void StreamOp.txStart() {}
	default async event void StreamOp.txEnd() {}
	
	/******************************/
	/*     Interrupt handlers     */
	/******************************/

	// RX uses 175 bus cycles to complete = 22 micro seconds
	// TX uses 167 bus cycles to complete = 21 micro seconds
	inline async event bool Interrupt.fastAction()
	{
		// TIME CRITICAL SECTION
		// NO DBG IN HERE (Except for well-chosen places ;-))
		if (opMode == RX_OPERATION) {
			// Receive mode. Read next byte.
			TOSH_CLR_RADIO_CE_PIN();
			call SPI.fastWriteByte(RX_PKT_RAM|0x80);
			call SPI.fastReadWordSwapped(nextByte);
			TOSH_SET_RADIO_CE_PIN();
			nextByte += 2;
			//ENABLE_IRQ;
			// Process word.
			if (!filterWord(nextByte-2)) {
				// Discard packet.
				abortOperation();
				DBG_STR("Discarded by filter!",4);
			}
		} else {
			// Transmit mode. Supply next word.
			//ASSERT_CE; // Enable SPI
			TOSH_CLR_RADIO_CE_PIN();
			call SPI.fastWriteByte(TX_PKT_RAM);
			call SPI.fastWriteWordSwapped(nextByte);
			//DEASSERT_CE;
			TOSH_SET_RADIO_CE_PIN();
			nextByte += 2;
		}

		if (nextByte >= lastByte) {
			finishStreamOperation();
			return FALSE;
		}
		return TRUE;
	}
	
	async event void Interrupt.strmTxDone()
	{

	}
	
	async event void Interrupt.strmRxDone()
	{

	}
	
	async event result_t Timer1.fired()
	{
		if (ackedOperation) {
			DBG_STR("ACK timer fired!",4);
			ackedOperation = FALSE;
			// Force transciever into idle mode.
			TOSH_CLR_RADIO_RXTXEN_PIN();
			finalizeSend(FAIL);
		}
		return SUCCESS;
	}
	
	// Interrupt indicating packet mode tx done.
	async event void Interrupt.txDone()
	{
		if (ackedOperation) {
			uint32_t timeout;
			TOSH_CLR_RADIO_RXTXEN_PIN();
			call Regs.write(CONTROL_A, RX_MODE);
			TOSH_SET_RADIO_RXTXEN_PIN();
			prepareRxBuffer();
			timeout = call Time.getTimerCounter() + ackWaitTime;
			call Timer1.start(timeout);
		} else {
			// We're done!
			finalizeSend(SUCCESS);
		}
	}

	// Interrupt indicating that a packet receive is about to commence
	// in stream mode.
	// This function takes 269 bus cycles to complete if successful.
	inline async event bool Interrupt.streamRead()
	{
		// TIME CRITICAL SECTION
		// NO DBG IN HERE (This time I mean it!!)
		if (opMode == RX_OPERATION) {
			// Read packet length.
			if (readRXPacketLength()) {
				signal StreamOp.rxStart();
				return TRUE;
			}
			// Abort and retry here.
			// Packet contained no data. Abort receive.
			TOSH_CLR_RADIO_RXTXEN_PIN();
			call Time.resetTimerCounter();
			while(TOSH_READ_RADIO_OOI_PIN());
			call Regs.write(CONTROL_A, RX_STRM_MODE);
			TOSH_SET_RADIO_RXTXEN_PIN();
		}
		return FALSE;
	}

	// Interrupt indicating that data has been received in
	// packet mode.
	async event void Interrupt.dataIndication(bool crc)
	{
		if (readRXPacketLength()) {
			readRXPacket(); // Read data from MC13192.
			if (crc && ackedOperation) {
				if (rxPacket->buffer[2] == seqNum) {
					ackedOperation = FALSE;
					call Timer1.stop();
					DBG_STR("Got ack and finishing up operation!",4);
					finalizeSend(SUCCESS);
					return;
				}
				return;
			}
 			rxPacket->crc = crc;
 			finalizeReceive();
 		} else {
 			// Restart receive operation.
			receive();
 		}
	}

	async event void Interrupt.lockLost()
	{
		// Handle restart of operations.
		if (opMode == RX_OPERATION) {
			DBG_STR("Restarting RX operation",3);
			nextByte = rxPacket->buffer;
			lastByte = nextByte + rxPacket->length;
			receive();
		} else if (opMode == TX_OPERATION) {
			DBG_STR("Restarting TX operation",3);
			nextByte = txPacket;
			lastByte = txPacket + txLength;
			send();
		} else if (opMode == CCA_OPERATION) {
			DBG_STR("Restarting CCA operation",3);
			// Just restart previous operation
			if (ccaType == ENERGY_DETECT) {
				call State.setEDMode(dataTransferMode);
			} else {
				// Must be CCA.
				call State.setCCAMode(dataTransferMode);
			}
		}
	}

	async event void Interrupt.ccaDone(bool isClear)
	{
		// Put radio in idle mode.
		call Regs.write(CONTROL_A, IDLE_MODE);
		// If we were cca'ing in stream mode, restore
		// register 0x38 value.
		if (dataTransferMode == STREAM_MODE) {
			call Regs.write(0x38, 0x0008);
		}

		opMode = NO_OPERATION;
		if (ccaType == ENERGY_DETECT) {
			DBG_STR("Energy detect done",3);
			signal CCA.energyDetectDone(getCCAFinal());
		} else { 
			DBG_STR("Clear channel assessment done",3);
			// Must be a clear channel assessment.
			signal CCA.clearChannelAssessmentDone(isClear);
		}
		signal StreamOp.opDone();
	}

	/******************************/
	/*   RX/TX helper functions   */
	/******************************/

	inline void prepareTxBuffer(uint8_t *packet, uint8_t length)
	{
		atomic {
			nextByte = txPacket = packet;
			txLength = length;
			lastByte = nextByte + txLength;
		}	
	}
	
	inline result_t prepareRxBuffer()
	{
		if (!bufCount) {
			// No free receive buffers.
			DBG_STR("bufCount is:",3);
			DBG_INT(bufCount,3);
			return FAIL;
		}
		if (!recvCount) {
			// No free receive structures.
			DBG_STR("No more room in receive item buffer!",3);
			return FAIL;
		}
		
		// Get new receive buffer item.
		rxPacket = &(recvItemBuffer[recvHead]);
		recvHead = (recvHead+1)%recvQueueSize;
		recvCount--;
		
		// Get new receive buffer.
		nextByte = rxPacket->buffer = bufQueue[bufHead];
		bufHead = (bufHead+1)%queueSize;
		bufCount--;
		return SUCCESS;
	}

	bool cont = FALSE;
	inline result_t send()
	{
		writeTXPacketLength();
		if (dataTransferMode == STREAM_MODE) {
			// Write first word to packet ram.
			call Regs.seqWriteStart(TX_PKT_RAM);
			call Regs.seqWriteWord(nextByte);
			call Regs.seqEnd();
			nextByte += 2;
			
			// Wait if we still have a transmission going on.
			while(TOSH_READ_RADIO_OOI_PIN());
			signal StreamOp.txStart();
			call State.setTXStreamMode();
			return SUCCESS;
		}
		writeTXPacket();
		return call State.setTXMode();
	}
	
	inline result_t receive()
	{
		if (dataTransferMode == STREAM_MODE) {
			// Wait if radio is still busy transmitting.
			while(TOSH_READ_RADIO_OOI_PIN());
			return call State.setRXStreamMode();
		}
		// Assume packet mode.
		return call State.setRXMode();
	}
	
	inline void abortOperation()
	{
		// This function is used to abort receives.
		signal StreamOp.rxEnd();
		call Interrupt.disableFastAction();
		opMode = NO_OPERATION;
		// Switch to idle mode.
		call State.setIdleMode();
	}
	
	inline uint8_t getCCAFinal()
	{
		uint16_t power;
		power = call Regs.read(RX_STATUS);
		power = ((power & 0xFF00) >> 8);
		return (uint8_t)power;
	}
	
	inline void writeTXPacketLength()
	{
		uint16_t reg;
		reg = call Regs.read(TX_PKT_CTL);
		reg = (0xFF80 & reg) | (txLength+2); // Mask out old length setting and update. Include 2 CRC bytes.
		call Regs.write(TX_PKT_CTL, reg); // Update the TX packet length field	
	}

	inline bool readRXPacketLength()
	{
		uint8_t status[2];
		
		// TIME CRITICAL SECTION.
		// NO DEBUG IN HERE.
		// This is time critical in stream mode, so we
		// call the SPI operations directly..
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(RX_STATUS|0x80);
		call SPI.fastReadWord(status);
		TOSH_SET_RADIO_CE_PIN();
		
		// Read out link quality and packet length.
		rxPacket->lqi = status[0];
		rxPacket->length = status[1] & 0x007F;
		
		if (rxPacket->length < 3) {
			// This is not valid.
			return FALSE;
		}
		
		// MC13192 reports length with 2 CRC bytes. We don't need them.
		rxPacket->length -= 2;
		lastByte = nextByte + rxPacket->length;
		return TRUE;
	}
	
	
	/******************************/
	/*   Packet mode functions    */
	/******************************/
	
	inline void writeTXPacket()
	{
		uint8_t i = 0;
		
		// Not pretty, but fast!
		// Worst case write is 31 symbol periods.
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(TX_PKT_RAM);
		while (i<txLength) {
			call SPI.fastWriteWordSwapped(txPacket+i);
			i += 2;
		}
		TOSH_SET_RADIO_CE_PIN();
	}
	
	inline void readRXPacket()
	{
		call Regs.seqReadStart(RX_PKT_RAM);
		call Regs.seqReadWord(nextByte); // Receive register will contain garbage for first read.

		while (nextByte <= lastByte) {
			call Regs.seqReadWord(nextByte);			
			nextByte += 2;
		}

		call Regs.seqEnd();	
	}
	
	/******************************/
	/*   Stream mode functions    */
	/******************************/
	
	void finishStreamOperation()
	{
		// We're done.
		if (opMode == RX_OPERATION) {
			signal StreamOp.rxEnd();
			// We need to wait for the radio to go out of idle
			// before we can read the correct CRC result.
			while(TOSH_READ_RADIO_OOI_PIN());
			rxPacket->crc = TOSH_READ_RADIO_CRC_PIN();
			// If we are waiting for an ack.
			if (rxPacket->crc && ackedOperation) {
				if (rxPacket->buffer[2] == seqNum) {
					ackedOperation = FALSE;
					call Timer1.stop();
					DBG_STR("Got ack and finishing up operation!",4);
					finalizeSend(SUCCESS);
					return;
				}
				return;
			}
			if (rxPacket->crc && rxFrameControl->AckRequest) {
				// We ack the packet.
				uint16_t reg;
				reg = call Regs.read(TX_PKT_CTL);
				reg = (0xFF80 & reg) | 5; // Include 2 CRC bytes.
				call Regs.write(TX_PKT_CTL, reg);
				call Regs.seqWriteStart(TX_PKT_RAM);
				call Regs.seqWriteWord(ackFrame);
				call Regs.seqEnd();
				nextByte = lastByte = &rxSeqNum;
				acking = TRUE;
				call Interrupt.disableFastAction();
				
				TOSH_CLR_RADIO_RXTXEN_PIN();
				call Regs.write(CONTROL_A, TX_STRM_MODE);
				TOSH_SET_RADIO_RXTXEN_PIN();
				// clear interrupt flag to allow tx to finish up.
				__nesc_enable_interrupt();
			}
			finalizeReceive();
		} else {
			if (ackedOperation) {
				uint32_t timeout;
				filterWord = ackFilter;
				while(TOSH_READ_RADIO_OOI_PIN());
				call Interrupt.disableFastAction();
				opMode = RX_OPERATION;
				TOSH_CLR_RADIO_RXTXEN_PIN();
				call Regs.write(CONTROL_A, RX_STRM_MODE);
				TOSH_SET_RADIO_RXTXEN_PIN();
				// clear interrupt flag to allow rx to finish up.
				__nesc_enable_interrupt();
				prepareRxBuffer();
				timeout = call Time.getTimerCounter() + ackWaitTime;
				call Timer1.start(timeout);
				return;
			}
			signal StreamOp.txEnd();
			if (acking) {
				acking = FALSE;
				return;
			}
			finalizeSend(SUCCESS);
		}
	}
	
	/******************************/
	/*           Tasks            */
	/******************************/
	
	void finalizeReceive()
	{
		//bool retCrc;
		uint8_t *buf;
		// Get next element to finalize.
		receiveItem_t *myPacket = &(recvItemBuffer[(recvHead+recvCount)%recvQueueSize]);

		opMode = NO_OPERATION;
		buf = signal Recv.dataReady(myPacket->buffer, myPacket->length, myPacket->crc, myPacket->lqi);
		// Put buffer in queue if we have enough space.
		if (bufCount < queueSize) {
			DBG_STR("New buffer added to the RX buffer queue",3);
			bufQueue[(bufHead+bufCount)%queueSize] = buf;
			bufCount++;
		}
		recvCount++;
		signal StreamOp.opDone();
	}
	
	void finalizeSend(result_t status)
	{
		// Radio is automatically switch to idle mode.
		opMode = NO_OPERATION;
		//signal Send.sendDone(txPacket, status);
		signal StreamOp.opDone();
	}

	// 802.15.4 filtering functions.
	bool ackFilter(uint8_t *data)
	{
		rxFrameControl = (mhrFrameControl_t*)data;
		if (rxFrameControl->FrameType == 2) {
			filterWord = dummyFilter;
			return TRUE;
		}
		return FALSE;
	}

	bool headerFilter(uint8_t *data)
	{
		rxFrameControl = (mhrFrameControl_t*)data;
		
		// Discard if wrong frameType
		if (rxFrameControl->FrameType > 3) {
			DBG_STR("Invalid frame type!",4);
			return FALSE;
		}
		// Discard if unknown address mode.
		if (rxFrameControl->DestAddrMode == 1 || rxFrameControl->SrcAddrMode == 1) {
			DBG_STR("Invalid addressing mode!",4);
			return FALSE;
		}

		// Preaccept beacons when not associated.
		if (!(rxFrameControl->FrameType) && filterPanId[0] == 0xFF && filterPanId[1] == 0xFF) {
			filterWord = dummyFilter;
			return TRUE;
		}
		
		// Calculate address lengths.
		rxDstAddrLength = 0;
		if (rxFrameControl->DestAddrMode) {
			if (rxFrameControl->DestAddrMode == 2) {
				rxDstAddrLength = 2;
			} else {
				rxDstAddrLength = 8;
			}
		}
		filterWord = seqNumFilter;
		return TRUE;
	}

	bool seqNumFilter(uint8_t *data)
	{
		// Not a real filter. Just fetch the sequence number
		// and prepare the right filter.
		rxSeqNum = data[0];
		if (rxDstAddrLength) {
			filterValue = filterPanId;
			filterWord = dstPanFilter;
		} else {
			filterValue = filterPanId;
			filterWord = srcPanFilter;
		}
		return TRUE;
	}

	bool dstPanFilter(uint8_t *data)
	{
		// Read PANId for short address.
		uint8_t *myPan = data-1;
		if ((myPan[0] == filterValue[0] && myPan[1] == filterValue[1]) ||
		    (myPan[0] == 0xFF && myPan[0] == myPan[1])) {
			// Broadcast pan is also accepted.
			if (rxDstAddrLength == 2) {
				filterValue = filterShortAddr;
			} else {
				filterValue = filterExtAddr;
			}
			filterWord = dstAddrFilter;
			return TRUE;
		}
		DBG_STR("Invalid destination PAN Id!",4);
		return FALSE;
	}

	bool dstAddrFilter(uint8_t *data)
	{
		uint8_t *myAddr = data-1;
		if (rxDstAddrLength > 2) {
			// We are handling an extended address.
			if ((myAddr[0] == filterValue[0] && myAddr[1] == filterValue[1])) {
				filterValue += 2;
				rxDstAddrLength -= 2;
				return TRUE;
			} else {
				DBG_STR("Invalid destination address1!",4);
				return FALSE;
			} 
		} else {
			// last part.
			// We also accept broadcast address if short address.
			if ((myAddr[0] == filterValue[0] && myAddr[1] == filterValue[1]) ||
			    (rxFrameControl->DestAddrMode == 2 &&
			    (myAddr[0] == 0xFF && myAddr[0] == myAddr[1]))) {
			
				// Filter was passed.
				filterWord = dummyFilter;
				return TRUE;
			} else {
				DBG_STR("Invalid destination address2!",4);
				return FALSE;
			}
		}
	}
	
	bool srcPanFilter(uint8_t *data)
	{
		// Read PANId for short address.
		uint8_t *myPan = data-1;
		if ((myPan[0] == filterValue[0] && myPan[1] == filterValue[1])) {
			filterWord = dummyFilter;
			return TRUE;
		}
		DBG_STR("Invalid source PAN Id!",4);
		return FALSE;
	}

}
