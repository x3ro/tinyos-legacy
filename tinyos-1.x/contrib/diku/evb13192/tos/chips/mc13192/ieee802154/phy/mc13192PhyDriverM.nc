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
#include <mc13192Const.h>
#include <mc13192Filters.h>
#include <mc13192PhyDriverConst.h>
#include <PhyTypes.h>

module mc13192PhyDriverM {
	provides
	{
		interface PhyReceive;
		interface PhyTransmit;
		interface PhyEnergyDetect;
		interface PhyAttributes;
		interface PhyControl;
		interface PhyReset;
	}
	uses
	{
		interface mc13192PhyInterrupt as Interrupt;
		interface FastSPI as SPI;
		interface mc13192PhyTimer as Timer;
		interface LocalTime as MCUTime;
		interface Debug;
	}
}
implementation
{
	#include <mc13192Registers.h>
	// Level 1 = List function calls.
	// Level 2 = Function calls + return values.
	// Level 3 = Extensive debug.
	#define DBG_LEVEL 1
	#define DBG_MIN_LEVEL 1
	#include "Debug.h"

	// Phy attribute variables.
	uint8_t curChannel = 11;
	bool (*myFilter)(uint8_t*) = NULL;

	// CCA globals
	bool edOperation = FALSE;
	uint16_t ccaMode = TX_CCA_MODE1;
	
	// RX packet variables
	rxdata_t rxPacket;
	uint8_t rxDuration;
	uint32_t rxCommenceTime;

	// Stream mode globals
	norace uint8_t dataTransferMode = PACKET_MODE;
	norace uint8_t *nextByte;
	norace uint8_t *lastByte;
	norace uint8_t opMode = NO_OPERATION;
	bool isReceiving = FALSE;

	// Defer support.
	// Defer 1 slot.
	uint8_t defer1OpType;
	bool defer1Ack;
	txdata_t *defer1Data;
	uint32_t defer1RxTime;
	bool defer1SlotFree = TRUE;
	// Defer 2 slot.	
	uint8_t defer2OpType;
	bool defer2Ack;
	txdata_t *defer2Data;
	uint32_t defer2RxTime;
	
	// 802.15.4 acknowledgement support.
	bool backoffAligned = FALSE;
	bool ackedOperation = FALSE;
	uint8_t seqNum;
	// The 802.15.4 spec states a wait time of 54. We add 12 symbol periods,
	// since a packet reception is first signalled after receiving preamble,
	// start of frame delimiter and frame length indicator. That totals 6
	// bytes equaling 12 symbol periods of transmission time.
	uint8_t ackWaitTime = 66;
	uint8_t ackFrame[2] = {0x02, 0x00};
	bool acking = FALSE;

	// Transmit and receive functions
	void enableReceiver(bool immediateCommence);
	bool sendCca(txdata_t *data, bool ack);
	void sendNoCca(txdata_t *data, bool ack);

	inline uint32_t getRxTime();
	inline void abortReceive();
	inline void restartReceive();
	inline void changeState(uint16_t state);
	//inline void writeRegister(uint8_t addr, uint16_t content);
	inline void finishStreamOperation();
	inline void finishRx();
	inline bool readRXPacketLength();
	inline uint8_t getCCAFinal();
	//inline void getReceiveBuffer();
	//inline void readRXPacket();
	inline void writeTXPacket(uint8_t *packet, uint8_t length);
	inline void writeTXPacketLength(uint8_t length);
	
	
	command void PhyReset.reset()
	{
		ccaMode = TX_CCA_MODE1;
		backoffAligned = FALSE;
	}
	
	/* **********************************************************************
	 * PhyAttributes code
	 * *********************************************************************/

	command result_t PhyAttributes.setChannel(uint8_t channel)
	{
		// Convert from IEEE 802.15.4 notation.
		channel -= 11;
		if (channel <= 0x0F) {
			uint16_t num = ((channel + 1)*5 & 0x000F)<<12;
			uint16_t div = 0x0F95;
			while (channel >= 3) {
				div++;
				channel -= 3;
			}

			writeRegister(LO1_INT_DIV,div);
			writeRegister(LO1_NUM,num);
			curChannel = channel;
			return SUCCESS;
		}
		return FAIL;
	}
	
	command result_t PhyAttributes.setContentionWindow(uint8_t size)
	{
		if (size == 1) {
			ccaMode = TX_CCA_MODE1;
		} else if (size == 2) {
			ccaMode = TX_CCA_MODE2;
		} else {
			return FAIL;
		}
		return SUCCESS;
	}

	command result_t PhyAttributes.setTransmitPower(uint8_t power)
	{
		return SUCCESS;
	}
	
	command result_t PhyAttributes.setAckBackoffAlignment(bool align)
	{
		backoffAligned = align;
		return SUCCESS;
	}

	command result_t PhyAttributes.setFilter(bool (*filter)(uint8_t*))
	{
		myFilter = filter;
		return SUCCESS;
	}
	
	command result_t PhyAttributes.clearFilter()
	{
		myFilter = NULL;
		return SUCCESS;
	}

/*	command uint8_t PhyAttributes.getChannel()
	{
		return curChannel;
	}*/

	command uint32_t PhyAttributes.getSupportedChannels()
	{
		return 0x07FFF800;
	}

	/* **********************************************************************
	 * PhyControl code
	 * *********************************************************************/

	command result_t PhyControl.trxOff(bool force)
	{
		atomic opMode = NO_OPERATION;
		abortReceive();
		return SUCCESS;
	}
	
	command void PhyControl.sleep(uint32_t wakeUpTime)
	{
	
	}

	/* **********************************************************************
	 * Setup/Init code
	 * *********************************************************************/

	command void PhyReceive.initRxBuffer(uint8_t *packetBuf)
	{
		rxPacket.frame = packetBuf;
	}

	command phy_error_t PhyReceive.rxOn(uint32_t commenceTime, bool immediateCommence)
	{
		if (immediateCommence) {
			enableReceiver(TRUE);
		} else {
			// TODO: Check that commence time is sane.
			// Defer until 12 symbols before commence time.
			bool wasFree;
			atomic {
				wasFree = defer1SlotFree;
				defer1SlotFree = FALSE;
			}
			if (wasFree) {
				// Use defer slot 1.
				defer1OpType = DEFER_RX;
				defer1RxTime = commenceTime;
				call Timer.startDeferTimer1(commenceTime-12);
			} else {
				// Use spare defer slot 2.
				defer2OpType = DEFER_RX;
				defer2RxTime = commenceTime;
				call Timer.startDeferTimer2(commenceTime-12);
			}				
		}
		return PHY_SUCCESS;
	}

	command phy_error_t PhyTransmit.tx(txdata_t *data)
	{
		bool ack = (data->frame[0] & 0x20);
		if (data->immediateCommence) {
			// Just start operation as fast as possible.
			if (data->cca) {
				if (!sendCca(data,ack)) {
					return PHY_CCA_FAIL;
				}
			} else {
				sendNoCca(data,ack);
			}
		} else {
			// TODO: Check that commence time is sane.
			// Defer until 12 symbols before commence time.
			bool wasFree;
			atomic {
				wasFree = defer1SlotFree;
				defer1SlotFree = FALSE;
			}
			if (wasFree) {
				// Use defer slot 1.
				defer1OpType = DEFER_TX;
				defer1Ack = ack;
				defer1Data = data;
				call Timer.startDeferTimer1(data->commenceTime-12);
			} else {
				// Use spare defer slot 2.
				defer2OpType = DEFER_TX;
				defer2Ack = ack;
				defer2Data = data;
				call Timer.startDeferTimer2(data->commenceTime-12);
			}
		}
		return PHY_SUCCESS;
	}

	void enableReceiver(bool immediateCommence)
	{
		// We are doing this kinda backwards. We first request the state
		// change from the radio, and then prepare for the reception,
		// while the radio is getting ready (takes 9 symbols).
		if (immediateCommence) {
			while(TOSH_READ_RADIO_OOI_PIN());
			changeState(RX_STRM_MODE);
		} else {
			changeState(RX_STRM_MODE | EVENT_TIMED);
			call Timer.startEventTimer(rxCommenceTime, STREAM_MODE);
		}
		if (dataTransferMode != STREAM_MODE) {
			// Enable stream mode.
			writeRegister(CONTROL_B, STREAM_MODE_ON);
			call Interrupt.enableStreamMode();
			dataTransferMode = STREAM_MODE;
		}
		atomic opMode = RX_OPERATION;
		nextByte = rxPacket.frame;
		filterWord = defaultFilter;
	}

	bool sendCca(txdata_t *data, bool ack)
	{
		if (isReceiving) return FALSE;
		if (!data->immediateCommence) {
			changeState(ccaMode | EVENT_TIMED);
			call Timer.startEventTimer(data->commenceTime, PACKET_MODE);
		} else {
			changeState(ccaMode);
		}

		if (dataTransferMode != PACKET_MODE) {
			writeRegister(CONTROL_B, STREAM_MODE_OFF);
			call Interrupt.disableStreamMode();
			dataTransferMode = PACKET_MODE;
		}
		// Write the TX packet length!
		writeTXPacketLength(data->length);

		// Write packet to radio.			
		writeTXPacket(data->frame, data->length);

		ackedOperation = ack;
		seqNum = data->frame[2];
		atomic opMode = TX_OPERATION;
		return TRUE;
	}

	void sendNoCca(txdata_t *data, bool ack)
	{
		abortReceive();
		// We are doing this kinda backwards. We first request the state
		// change from the radio, and then prepare for the transmission,
		// while the radio is getting ready (takes 9 symbols).
		if (!data->immediateCommence) {
			changeState(TX_STRM_MODE | EVENT_TIMED);
			call Timer.startEventTimer(data->commenceTime, STREAM_MODE);
		} else {
			changeState(TX_STRM_MODE);
		}
		
		// Write first word to packet ram.
		writeTXPacket(data->frame, 2);
		// Write the TX packet length!
		writeTXPacketLength(data->length);

		// Enable stream mode.
		if (dataTransferMode != STREAM_MODE) {
			// Enable stream mode.
			writeRegister(CONTROL_B, STREAM_MODE_ON);
			call Interrupt.enableStreamMode();
			dataTransferMode = STREAM_MODE;
		}
		
		atomic opMode = TX_OPERATION;
		// Set ack mode variables.
		ackedOperation = ack;
		seqNum = data->frame[2];
		// Set stream frame pointers correct.
		nextByte = data->frame+2;
		lastByte = data->frame + data->length;
	}
	
	default async event void PhyEnergyDetect.edDone(phy_error_t error, uint8_t power) {}
	
	command phy_error_t PhyEnergyDetect.ed()
	{	
		edOperation = TRUE;
		if (dataTransferMode != PACKET_MODE) {
			writeRegister(CONTROL_B, STREAM_MODE_OFF);
			call Interrupt.disableStreamMode();
			dataTransferMode = PACKET_MODE;
		}
		changeState(ED_MODE);
		return PHY_SUCCESS;
	}

	
	/******************************/
	/*     Interrupt handlers     */
	/******************************/

	// RX uses 175 bus cycles to complete = 22 micro seconds
	// TX uses 167 bus cycles to complete = 21 micro seconds
	inline async event bool Interrupt.fastAction()
	{
		// TIME CRITICAL SECTION
		// NO DBG IN HERE
		if (opMode == RX_OPERATION) {
			// Receive mode. Read next byte.
			TOSH_CLR_RADIO_CE_PIN();
			call SPI.fastWriteByte(RX_PKT_RAM|0x80);
			call SPI.fastReadWordSwapped(nextByte);
			call SPI.fastReadWordSwapped(nextByte);
			TOSH_SET_RADIO_CE_PIN();
			nextByte += 2;

			// Filter the received word.
			if (!filterWord(nextByte-2)) {
				// Discard packet.
				restartReceive();
				DBG_STR("Discarded by filter!",3);
				DBG_STR(filterReason,3);
				DBG_DUMP(rxPacket.frame,rxPacket.length,3);
				return FALSE;
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

	async event void Interrupt.ackTimerFired()
	{
		call Timer.stopAckTimer();
		if (ackedOperation) {
			ackedOperation = FALSE;
			abortReceive();
			signal PhyTransmit.txDone(PHY_ACK_FAIL);
		}
	}
	
	async event void Interrupt.eventTimerFired()
	{
		call Timer.stopEventTimer();
	}

	async event void Interrupt.deferTimer1Fired()
	{
		// Activate deferred operation.
		if (defer1OpType == DEFER_TX) {
			if (defer1Data->cca) {
				if (!sendCca(defer1Data,defer1Ack)) {
					signal PhyTransmit.txDone(PHY_CCA_FAIL);
				}
			} else {
				sendNoCca(defer1Data,defer1Ack);
			}
		} else if (defer1OpType == DEFER_RX) {
			rxCommenceTime = defer1RxTime;
			enableReceiver(FALSE);
		} 
		call Timer.stopDeferTimer1();
		defer1SlotFree = TRUE;
	}
	
	async event void Interrupt.deferTimer2Fired()
	{
		// Activate deferred operation.
		if (defer2OpType == DEFER_TX) {
			if (defer2Data->cca) {
				if (!sendCca(defer2Data,defer2Ack)) {
					signal PhyTransmit.txDone(PHY_CCA_FAIL);
				}
			} else {
				sendNoCca(defer2Data,defer2Ack);
			}
			DBG_STR("Starting deferred tx from slot 2",4);
		} else if (defer2OpType == DEFER_RX) {
			rxCommenceTime = defer2RxTime;
			enableReceiver(FALSE);
		} 
		call Timer.stopDeferTimer2();
	}
	
	// Interrupt indicating packet mode tx done.
	async event void Interrupt.txDone()
	{
		if (ackedOperation) {
/*			uint32_t timeout;
			changeState(RX_MODE);
			timeout = call Timer.getEventTime() + ackWaitTime;
			call Timer.startAckTimer(timeout);*/
			uint32_t timeout;
			filterWord = ackFilter;
			opMode = RX_OPERATION;
			
			// Enable stream mode.
			writeRegister(CONTROL_B, STREAM_MODE_ON);
			call Interrupt.enableStreamMode();
			dataTransferMode = STREAM_MODE;
			
			changeState(RX_STRM_MODE);
			// clear interrupt flag to allow rx to finish up.
			__nesc_enable_interrupt();
			nextByte = rxPacket.frame;
			timeout = call Timer.getEventTime() + ackWaitTime;
			call Timer.startAckTimer(timeout);
		} else {
			// We're done!
			signal PhyTransmit.txDone(PHY_SUCCESS);
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
				isReceiving = TRUE;
				return TRUE;
			}
			// Abort and retry here.
			// Packet contained no data. Abort receive.
			restartReceive();
		}
		return FALSE;
	}
	
/*	async event void Interrupt.dataIndication(bool crc)
	{
		// We only packet mode reception for receiving acks!
		if (crc && ackedOperation && readRXPacketLength() && rxPacket.length == 3) {
			readRXPacket(); // Read data from MC13192.
			if (rxPacket.frame[2] == seqNum) {
				ackedOperation = FALSE;
				call Timer.stopAckTimer();
				DBG_STR("Got ack and finishing up operation!",4);
				signal PhyTransmit.txDone(PHY_SUCCESS);
				return;
			} else {
				DBG_STR("Got frame, but not an ack!",1);
			}
		} else {
			readRXPacketLength();
			readRXPacket();
			DBG_DUMP(rxPacket.frame, rxPacket.length,1);
		}
	}*/
	
	// What do we do here?
	async event void Interrupt.lockLost()
	{
		// Handle restart of operations.
/*		if (opMode == RX_OPERATION) {
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
		}*/
	}
	
	async event void Interrupt.ccaDone(bool isClear)
	{
		// Put radio in idle mode.
		TOSH_CLR_RADIO_RXTXEN_PIN();
		if (edOperation) {
			uint16_t energy = readRegister(RX_STATUS);
			signal PhyEnergyDetect.edDone(PHY_SUCCESS, (uint8_t)(energy>>8));
		} else {
			// Only signalled when CCA-CCA-TX fails.
			signal PhyTransmit.txDone(PHY_CCA_FAIL);
		}
	}
	
	// Helper functions below here

	inline void writeTXPacketLength(uint8_t length)
	{
		uint16_t reg = length + 2;
		writeRegister(TX_PKT_CTL, reg);
	}

	inline void writeTXPacket(uint8_t *packet, uint8_t length)
	{
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
	}
	
/*	inline void readRXPacket()
	{
		uint8_t *myNextByte = rxPacket.frame;
		uint8_t *myLastByte = myNextByte + rxPacket.length;
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(RX_PKT_RAM|0x80);
		// Receive register will contain garbage for first read.
		call SPI.fastReadWordSwapped(myNextByte);

		while (myNextByte <= myLastByte) {
			call SPI.fastReadWordSwapped(myNextByte);			
			myNextByte += 2;
		}	
		
		TOSH_SET_RADIO_CE_PIN();	
	}*/
	
/*	inline void getReceiveBuffer()
	{
		// Get new receive buffer.
		nextByte = rxPacket.frame = bufQueue[bufHead];
		bufHead = (bufHead+1)%queueSize;
		bufCount--;
	}*/
	
	inline uint8_t getCCAFinal()
	{
		uint8_t power[2];
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(RX_STATUS|0x80);
		call SPI.fastReadWord(power);
		TOSH_SET_RADIO_CE_PIN();
		return power[0];
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
		rxPacket.linkQuality = status[0];
		rxPacket.length = status[1] & 0x007F;
		
		if (rxPacket.length < 5) {
			// This is not valid.
			return FALSE;
		}
		
		// Get rx timestamp.
		// Subtract the time it takes to receive preamble.
		rxPacket.recvTime = getRxTime()-12;
		rxDuration = 12 + rxPacket.length*2;
		
		// MC13192 reports length with 2 CRC bytes. We don't need them.
		rxPacket.length -= 2;
		lastByte = nextByte + rxPacket.length;
		return TRUE;
	}

	inline void finishStreamOperation()
	{
		// We're done.
		if (opMode == RX_OPERATION) {
			// We need to wait for the radio to go out of idle
			// before we can read the correct CRC result.
			while(TOSH_READ_RADIO_OOI_PIN());
			if (!TOSH_READ_RADIO_CRC_PIN()) {
				restartReceive();
				return;
			}

			// If we are waiting for an ack.
			if (ackedOperation) {
				isReceiving = FALSE;
				if (rxPacket.frame[2] == seqNum) {
					ackedOperation = FALSE;
					call Timer.stopAckTimer();
					DBG_STR("Got ack and finishing up operation!",4);
					signal PhyTransmit.txDone(PHY_SUCCESS);
					return;
				}
				return;
			}
			// Check if we need to ack the received packet.
			if (rxFrameControl->AckRequest) {
				// The ack should commence 12 symbol periods after the time of arrival
				// of the frame.
				uint16_t commenceTime = ((uint16_t)rxPacket.recvTime) + rxDuration + 12;
				if (backoffAligned) {
					// We backoff align the ack, by assuming that the transmission commenced
					// on a backoff boundary. We figure out, how much to add to the commence
					// time, so that the commence time of the ack is a multiple of 20 bigger
					// than the frame recv time.
					commenceTime += 20 - ((rxDuration + 12)%20);
				}
				// Program event timer.
				writeRegister(TC2_PRIME, commenceTime);
				writeRegister(TMR_CMP2_A, 0x0000);
				changeState(TX_STRM_MODE|EVENT_TIMED);

				// We ack the packet.
				writeTXPacketLength(3);
				// Write the two first ack bytes to packet ram.
				writeTXPacket(ackFrame, 2);

				nextByte = lastByte = &rxSeqNum;
				acking = TRUE;
				call Interrupt.disableFastAction();
				opMode = TX_OPERATION;
				// clear interrupt flag to allow tx to finish up.
				ENABLE_IRQ;
				__nesc_enable_interrupt();
			} else {
				isReceiving = FALSE;
				finishRx();
			}

		} else {
			if (ackedOperation) {
				uint32_t timeout;
				filterWord = ackFilter;
				while(TOSH_READ_RADIO_OOI_PIN());
				call Interrupt.disableFastAction();
				opMode = RX_OPERATION;
				changeState(RX_STRM_MODE);
				// clear interrupt flag to allow rx to finish up.
				__nesc_enable_interrupt();
				nextByte = rxPacket.frame;
				//getReceiveBuffer();
				timeout = call Timer.getEventTime() + ackWaitTime;
				call Timer.startAckTimer(timeout);
				return;
			}

			if (acking) {
				// If we were transmitting an ack, just return.
				while(TOSH_READ_RADIO_OOI_PIN());
				acking = FALSE;
				isReceiving = FALSE;
				//opMode = RX_OPERATION;
				finishRx();
				return;
			}
			signal PhyTransmit.txDone(PHY_SUCCESS);
		}
	}
	
	inline void finishRx()
	{
		uint32_t myMcuTime;
		
		// Filter received packet through additional filter if set.
		if (myFilter != NULL) {
			if (!myFilter(rxPacket.frame)) {
				DBG_STR("Packet discarded by custom filter",4);
				restartReceive();
				return;
			}
		}
		
		// Extend the rx timestamp. (Radio time is 24 bits, MCU is 32 bits).
		myMcuTime = call MCUTime.getTime();
		rxPacket.recvTime += (myMcuTime & 0xFF000000);
		if (rxPacket.recvTime > myMcuTime) {
			// MCU timer must have incremented its 8 most significant bits
			// since receive time. Subtract 0x01000000 from packet timestamp.
			rxPacket.recvTime -= 0x01000000;
		}
		
		// Enable interrupts in case we have to process an orphan notification or
		// an association request, which is done in async context (speed).
		ENABLE_IRQ;
		__nesc_enable_interrupt();

		// Get new receive buffer.
		rxPacket.frame = signal PhyReceive.dataReady(&rxPacket);

		// NOTE: How could opMode be other than RX???
		//if (opMode == RX_OPERATION) {
			// The receiver still needs to be on.
			enableReceiver(TRUE);
		//}
	}
	
/*	inline void writeRegister(uint8_t addr, uint16_t content)
	{
		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(addr);
		call SPI.fastWriteWord((uint8_t*)&content);
		TOSH_SET_RADIO_CE_PIN();
	}*/
	
	inline void changeState(uint16_t state)
	{
		TOSH_CLR_RADIO_RXTXEN_PIN();
		writeRegister(CONTROL_A, state);
		TOSH_SET_RADIO_RXTXEN_PIN();
	}

	inline uint32_t getRxTime()
	{
		uint8_t timestamp[4];

		TOSH_CLR_RADIO_CE_PIN();
		call SPI.fastWriteByte(TIMESTAMP_A|0x80);
		call SPI.fastReadWord(timestamp);
		call SPI.fastReadWord(timestamp+2);
		TOSH_SET_RADIO_CE_PIN();

		return *(uint32_t*)timestamp;
	}
	
	inline void restartReceive()
	{
		isReceiving = FALSE;
		call Interrupt.disableFastAction();
		TOSH_CLR_RADIO_RXTXEN_PIN();
		while(TOSH_READ_RADIO_OOI_PIN());
		writeRegister(CONTROL_A, RX_STRM_MODE);
		TOSH_SET_RADIO_RXTXEN_PIN();
		filterWord = defaultFilter;
		nextByte = rxPacket.frame;
	}
	
	inline void abortReceive()
	{
		isReceiving = FALSE;
		call Interrupt.disableFastAction();
		TOSH_CLR_RADIO_RXTXEN_PIN();
	}
}
