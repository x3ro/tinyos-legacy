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

includes crc;

module mc13192TOSRadioM {
	provides {
		interface StdControl;
		interface BareSendMsg as Send;
		interface ReceiveMsg as Recv;
	}
	uses {
		interface mc13192Send as RadioSend;
		interface mc13192Receive as RadioRecv;
		interface mc13192StreamEvents as StreamOp;
		interface mc13192TimerCounter as Time;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 4
	#include "Debug.h"
	
	TOS_MsgPtr rxBufPtr;
	TOS_MsgPtr txBufPtr;
	// 0x23, 0xC8, 0xFE
	uint8_t myTestFrame[19] = {0x23, 0xC8, 0x12, 0xDE, 0xFE, 0x1F, 0x00, 0xFF, 0xFF, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x01, 0x80};
	uint8_t myTestFrameLength = 125;//19;
	
	uint8_t rxBuf[3][126]; // Initial receive buffer.
	norace bool isReceiving = FALSE;
	bool sendPending = FALSE;
	
	// Variables for testing purposes
	#if DBG_LEVEL > 0
		#define BUFLEN 29
		#define TEST_MODE 0
		char txBuf[52] = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz";
		char correct[BUFLEN+5];
		uint8_t expectedLen;
		uint32_t errorCount = 0;
		uint32_t errorLastCount = 0;
		uint32_t recvCount = 0;
	#endif
	
	// Forward declarations
	task void rxOnTask();
	task void receiveDoneTask();
	uint16_t crc16(uint8_t* buf, uint8_t len);
	inline uint8_t invertByte(uint8_t myByte);

	command result_t StdControl.init()
	{
		// Used for testing only.
		#if DBG_LEVEL > 0
			if (TEST_MODE) {
				memcpy(correct, txBuf, BUFLEN);
				expectedLen = BUFLEN;
			} else {
				correct[0] = 0x00;
				correct[1] = 0x01;
				correct[2] = 0x00;
				correct[3] = 0x00;
				correct[4] = BUFLEN;
				memcpy(&(correct[5]), txBuf, BUFLEN);
				expectedLen = BUFLEN+5;
			}
		#endif
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call RadioRecv.initRxQueue(rxBuf[0]);
		call RadioRecv.initRxQueue(rxBuf[1]);
		call RadioRecv.initRxQueue(rxBuf[2]);
		//post rxOnTask();
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	command result_t Send.send(TOS_MsgPtr msg)
	{
		uint32_t startTime, diffTime;
		uint8_t txLength;
		if (isReceiving) {
			txBufPtr = msg;
			sendPending = TRUE;
			DBG_STR("Delaying send!",3);
			return SUCCESS;
		} else {
			// Disable receiver.
			//call RadioRecv.disableReceiver(); 
			isReceiving = FALSE;
			// calculate payload size. We don't send the crc field.
			txLength = msg->length + (MSG_DATA_SIZE - DATA_LENGTH - 2);
			//return call RadioSend.send((uint8_t*)msg, txLength, 0, FALSE);

			call RadioSend.prepareData(myTestFrame, myTestFrameLength, TRUE, STREAM_MODE);

			//call RadioSend.ccaSend(2);
			startTime = call Time.getTimerCounter();
			call RadioSend.send();
			diffTime = call Time.getTimerCounter()-startTime;
			DBG_STRINT("Operation time:",diffTime,4);
			return SUCCESS;
		}
	}
	
	async event void RadioSend.sendDone(uint8_t *packet, result_t status)
	{
		signal Send.sendDone((TOS_MsgPtr)packet, status);
		// Enable receiver.
		
		/*if (FAIL == call RadioRecv.enableReceiver(0)) {
			DBG_STR("Failed to enable receiver",2);
		}*/
	}

	#if DBG_LEVEL > 0
		/** Help function, does string compare */
		uint8_t strcmp(const char * a, const char * b, uint8_t length)
		{
			while (length && *a == *b) { ++a; ++b; --length; };
			return length;
		}
	#endif

	async event uint8_t* RadioRecv.dataReady(uint8_t *packet, uint8_t length, bool crc, uint8_t lqi)
	{
		uint8_t i;
		uint8_t valid;
		isReceiving = FALSE;
		DBG_STR("Packet received!",1);
		DBG_DUMP(packet, length, 4);
		#if DBG_LEVEL > 0

			if (crc) {
				DBG_STR("CRC Good!",1);
			/*	bool errorHandled = FALSE;
				// Adjust packet length in correct packet.
				if (!TEST_MODE) {
					correct[4] = length-5;
				}
				//uint8_t tstPacket[3] = {0x40,0x00,0x56};
				//uint8_t tstPacket[3] = {0x02,0x00,0x6A};
				if (length & 1) {
					uint16_t newCrc = crc16(correct, length);*/
/*					if (((uint8_t*)&(newCrc))[0] != packet[length]) {
						DBG_STR("Error in first CRC byte!",3);
						DBG_INT(newCrc,2);
						DBG_INT(correct[length-1],3);
						DBG_INT(packet[length-1],3);
						DBG_INT(packet[length],3);
					}*/
					/*if (correct[length-1] != packet[length-1]) {
						errorLastCount++;
						DBG_STR("Error in last byte!",3);
						DBG_INT(newCrc,2);
						DBG_INT(correct[length-1],3);
						DBG_INT(packet[length-1],3);
						DBG_INT(packet[length],3);
						errorHandled = TRUE;
					}
				}
				//DBG_INT(packet[16],3);

				recvCount++;
				// Adjust packet length in correct packet.
				if (!TEST_MODE) {
					correct[4] = length-5;
				}
				if ((valid = strcmp(correct,(char*)packet,length)) && !errorHandled) {
					uint8_t errPos = length-valid;
					errorCount++;
					DBG_STR("Corrupted packet in position",3);
					DBG_INT(errPos,3);
					/*DBG_STR("Packet was:",3);
					for (i=0;i<length+1;i++) {
						DBG_INT(packet[i],3);
					}*/
					/*DBG_STR("Bytes:",3);
					DBG_INT(packet[errPos],3);
					DBG_INT(correct[errPos],3);
				}*/ /*else {
					DBG_STR("Packet received correctly!",3);
					DBG_INT(length,3);
				}*/
				/*if (recvCount%500 == 0) {
					DBG_STR("Number of packets received:",3);
					DBG_INT(recvCount,3);
					DBG_STR("Number of packets with errors:",3);
					DBG_INT(errorCount,3);
					DBG_STR("Number of odd length packets with error in last byte:",3);
					DBG_INT(errorLastCount,3);
				}*/
			}/* else {
				DBG_STR("CRC error!",3);
			}*/
		#endif
		//rxBufPtr = (TOS_MsgPtr)packet;
		//rxBufPtr->strength = lqi;
		//rxBufPtr->crc = crc;
		//post receiveDoneTask();
		//return (uint8_t*)signal Recv.receive(rxBufPtr);
		return packet;
		//rxBufPtr = (TOS_MsgPtr)packet;
	}
	
	task void rxOnTask()
	{
		call RadioRecv.enableReceiver();
	}
	
	task void receiveDoneTask()
	{
		if (sendPending) {
			uint8_t txLength;
			sendPending = FALSE;
			DBG_STR("Sending delayed msg!",3);
			// calculate payload size. We don't send the crc field.
			txLength = txBufPtr->length + (MSG_DATA_SIZE - DATA_LENGTH - 2);
			call RadioRecv.disableReceiver();
//			call RadioSend.send((uint8_t*)txBufPtr, txLength);
		}
	}

	uint16_t crc16(uint8_t* buf, uint8_t len)
	{
		uint8_t* tmpBuf = buf;
		uint16_t crc;
		uint8_t invByte;
		uint8_t i;
		uint8_t nextByte;

		for ( crc = 0; len > 0; len-- ) {
			crc = crcByte(crc, invertByte(*tmpBuf));
			tmpBuf++;
		}
		((uint8_t*)&crc)[0] = invertByte(((uint8_t*)&crc)[0]);
		((uint8_t*)&crc)[1] = invertByte(((uint8_t*)&crc)[1]);
		return crc;
	}
	
	inline uint8_t invertByte(uint8_t myByte)
	{
		uint8_t invByte = 0;
		uint8_t i,b1=1,b2=128;
		for (i=0;i<8;i++) {
			if (myByte & b1) {
				invByte |= b2;
			}
			b1 <<= 1;
			b2 >>= 1;
		}
		return invByte;
	}

	async event void StreamOp.rxStart() {}
	async event void StreamOp.rxEnd() {}
	async event void StreamOp.txStart() {}
	async event void StreamOp.txEnd() {}
	async event void StreamOp.opDone() {}

}
