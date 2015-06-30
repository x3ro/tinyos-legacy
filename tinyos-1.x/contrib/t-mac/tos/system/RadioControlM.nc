/*
 * Copyright (c) 2002-2004 the University of Southern California
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye (S-MAC version), Tom Parker (T-MAC modifications)
 *
 * This module implements the radio control functions:
 *   1) Put radio into different states:
 *   	a) idle; b) sleep; c) receive; d) transmit
 *   2) Physical carrier sense
 *   3) Tx and Rx of packets, and the handling of bytes in/out to/from the platform
 *      specific-layer
 */

/**
 * @author Wei Ye
 * @author Tom Parker
 */

module RadioControlM
{
	provides
	{
		interface StdControl as PhyControl;
		interface RadioState as PhyState;
		interface PhyComm;
		interface CarrierSense;
	}
	uses
	{
		interface UARTDebug as Debug;
		interface RadioSPI;
	}
}

implementation
{

#include "TMACEvents.h"

// for carrier sense
#define BUSY_THRES 2

#define STARTSYM 0xCF0C

	// preamble and start symbol before each packet
	static unsigned char start[4] = {0x55, 0xcf, 0x0c, 0xF0};
	
	//char start[5] __attribute((C)) = {0xcf, 0x0c, 0xcf, 0x0c, 0xcc};
	//static char start[9] = {0xf0, 0xff, 0x00, 0xf0, 0xf0, 0xff, 0x00, 0xf0, 0xf0};

	// radio states. INIT is a temporary state only at start up
	typedef enum
	{ RC_SLEEP=1, RC_IDLE, RC_RECEIVE, RC_TRANSMIT, RC_END_TX, RC_INIT, RC_END_RX }
	radio_states;

	radio_states radioState;			// radio state
	uint16_t search;			// for searching start symbol
	uint16_t carrSenTime;		// carrier sense time
	uint8_t numOnes;			// carrier sense counter
	uint8_t nextByte;				// tx buffer
	uint8_t txCount;			// for start symbol tx
	bool stored_data;
	uint8_t offset;				// offset for incoming data

	uint32_t rssi; // cumulative rssi total. divide by recvCount to get average rssi

	result_t PhyByte_txByteReady();
	result_t PhyByte_startSymDetected();
	result_t PhyByte_rxByteDone(uint8_t data);

	result_t reallyIdle()
	{
		//call Debug.txStatus(_MM_RADIO_OLD_STATE,radioState);
		atomic 
		{
			radioState = RC_IDLE;
			search = 0;
			carrSenTime = 0;		// don't start carrier sense by default
			offset = 0;
		}
		call Debug.txStatus(_MM_RADIO_STATE,radioState);

		return call RadioSPI.idle();
	}

	// set radio into idle state. Automatically detect start symbol
	result_t RadioState_idle()
	{
		if (radioState == RC_IDLE || radioState == RC_END_RX)
			return SUCCESS;
		//call Debug.txStatus(_MM_RADIO_OLD_STATE,radioState);
		if (radioState == RC_RECEIVE)
		{
			atomic radioState = RC_END_RX;
			call Debug.txStatus(_MM_RADIO_STATE,radioState);
			return SUCCESS;
		}
		else
			return reallyIdle();
	}

	// set radio into sleep mode: can't Tx or Rx
	result_t RadioState_sleep()
	{
		result_t ret=SUCCESS;
		if (radioState!=RC_IDLE)
			return FAIL;
		radioState = RC_SLEEP;
		//call Debug.txStatus(_MM_RADIO_STATE,radioState);
#ifndef DONT_REALLY_SLEEP		
		ret = call RadioSPI.sleep();
#endif
		return ret;
	}


	// start sending a new packet. Automatically send start symbol first
	result_t RadioByte_startTx()
	{
		dbg(DBG_USR1, "RADIO: Start send....\n");
		//call Debug.txStatus(_MM_RADIO_OLD_STATE,radioState);
		radioState = RC_TRANSMIT;
		//call Debug.txStatus(_MM_RADIO_STATE,radioState);
		nextByte = start[1];	// buffer second byte of start symbol
		txCount = 2;
		stored_data = TRUE;
		dbg(DBG_USR1, "RADIO: Byte '%02X' going out (init)\n",(unsigned char) start[0]);
		call RadioSPI.idle();
		call RadioSPI.send(start[0]);
		return SUCCESS;
	}


	// send next byte


	// start carrier sense
	command result_t CarrierSense.start(uint16_t numBits)
	{
		if (radioState == RC_SLEEP)
			RadioState_idle();
		if (radioState != RC_IDLE)
			return FAIL;
		numOnes = 0;
		carrSenTime = numBits;
		call Debug.tx16status(__CARRSENSE_START,numBits);
		return SUCCESS;
	}


	// default do-nothing handler for carrier sense
	default event result_t CarrierSense.channelIdle()
	{
		return SUCCESS;
	}


	default event result_t CarrierSense.channelBusy()
	{
		return SUCCESS;
	}

	PhyPktBuf *sendPtr;

	task void packet_sent()
	{
		#if defined(PLATFORM_PC) && !defined(NDEBUG)
		int i;
		dbg(DBG_AM,"Packet data out: ");
		for (i=0;i<sendPtr->length;i++)
		{
			//call Debug.txStatus(_PKT_DATA,((uint8_t*)sendPtr)[i]);
			dbg_clear(DBG_AM, "%02hhx ", ((uint8_t*)sendPtr)[i]);
		}
		dbg_clear(DBG_AM, "\n");
		#endif
		signal PhyComm.txPktDone(sendPtr);
	}

	event result_t RadioSPI.xmitReady()
	{
		switch (radioState)
		{
			case RC_TRANSMIT:
				dbg(DBG_USR1, "RADIO: Byte '%02X' going out (%d)\n",
					(unsigned char) nextByte,txCount);
				if (stored_data == FALSE)
					radioState = RC_END_TX;
				/*atomic {
					call Debug.txStatus(_RADIO_TX, nextByte);
					call Debug.txStatus(_STORED_DATA, abs(stored_data));	
				}*/
				stored_data=FALSE;
				call RadioSPI.send(nextByte);
				nextByte = 0;

				if (txCount < sizeof(start))
				{
					nextByte = start[txCount];
					stored_data=TRUE;
				}
				else
					PhyByte_txByteReady();	// ask a byte from upper layer
				txCount++;
				break;

			case RC_RECEIVE:
				PhyByte_rxByteDone(-1);
				break;
			case RC_END_TX:
				if (!post packet_sent())
				{					// try to post task first
					signal PhyComm.txPktDone(sendPtr);	// signal directly if can't post
				}
				RadioState_idle();
				break;
			default:
			break;
		}
		return SUCCESS;
	}
	
	event result_t RadioSPI.dataReady(uint8_t data, bool valid)
	{
		/* this can take too long! reduce debug! */
		static uint16_t lastData = 0;
		uint8_t temp = data;
		data = (data>>offset) | (lastData<<(8-offset));
		lastData = temp;
		
		if (radioState == RC_RECEIVE || radioState == RC_END_RX)
		{
			//call Debug.tx16status(__RADIO_TEST_RECV,(data<<8)|valid);
			PhyByte_rxByteDone(data);
			if (radioState == RC_END_RX)
			{
				call Debug.txStatus(_RADIO_RECV,data);
				reallyIdle();
			}
		}
#ifdef DONT_REALLY_SLEEP
		else // catch packets even when asleep
#else
		else if (radioState == RC_IDLE)
#endif
		{
			uint16_t u_search = (search >> 8)&0xFF; // search's upper 8 bits
			uint8_t i;
			//call Debug.tx16status(__RADIO_TEST_RECV,(data<<8)|valid);
			if (!valid)
				data = 0;
			//uartDebug_txByte(u_search);
			search = (search << 8) | data;
			//uartDebug_txByte(search &0xFF);
			//if (search!=0)
			{
				//dbg(DBG_USR1, "search = %08X, u_search = %02X\n",search,u_search);
				//call Debug.tx32status(____STARTSYM_CHECK, search);
			}
			//uartDebug_txByte((search & (STARTSYM & MASK))&0xFF);
			if (search !=0)
			{
				for (i=0;i<8;i++)
				{
					uint16_t check;			// for searching start symbol
					if (i!=0)
						check = (search>>i) | (u_search <<(16-i));
					else
						check = search;
						
					if (check == STARTSYM)
					{					// start symbol detected
						dbg(DBG_USR1, "RADIO: Start symbol spotted (offset=%d)\n",i);
						call Debug.txStatus(_START_SYMBOL_DETECTED,i);
						radioState = RC_RECEIVE;
						//call Debug.txStatus(_MM_RADIO_STATE,radioState);
						// signal upper layer to prepare for reception
						if (carrSenTime > 0)
						{				// MAC is in Carrier Sense state
							carrSenTime = 0;	// stop carrier sense
							signal CarrierSense.channelBusy();
						}
						if(PhyByte_startSymDetected() == FAIL)
						{
							RadioState_idle();
						}
						offset = i;
						break;
					}
				}
			}
			else // search ==0
				i = 8;
			if (i==8)
			{
				if (carrSenTime > 0)
				{				// carrier sense started
					//uint16_t rssi;
					dbg(DBG_USR1,"No start bit, so decrement carrsentime(%d)!\n",carrSenTime);
					//call Debug.txStatus(_LISTENBITS, carrSenTime);
					//rssi = call RadioSPI.getRSSI();
					/*call Debug.txStatus(_RADIO_RSSI,rssi>>8);
					call Debug.txStatus(_RADIO_RSSI,rssi&0xFF);*/

					while (data!=0)
					{
						numOnes += (data & 0x1u);
						data >>= 1;
					}

					if (numOnes > BUSY_THRES)
					{
						// channel busy is detected
						dbg(DBG_USR1, "channel busy detected\n");
						call Debug.tx16status(__CHANNEL_BUSY_DETECTED,carrSenTime);
						carrSenTime = 0;	// stop carrier sense
						signal CarrierSense.channelBusy();
					}
					else
					{
						if (carrSenTime <= 8)
						{
							// channel idle is detected
							dbg(DBG_USR1, "channel idle detected (numOnes=%d)\n",numOnes);
							call Debug.txState(CHANNEL_IDLE_DETECTED);
							signal CarrierSense.channelIdle();
							carrSenTime = 0;
						}
						else
							carrSenTime -= 8;
					}
				}
			}
		}
		return SUCCESS;
	}

#include "PhyRadioMsg.h"
#include "TMACEvents.h"

	// Physical layer states
	typedef enum
	{
		PHY_IDLE=1,
		RECEIVING,
		RECEIVING_LAST,
		TRANSMITTING,
		TRANSMITTING_LAST,
		TRANSMITTING_DONE
	} PhyEnum;

	// buffer states
	typedef enum { BUF_FREE, BUF_BUSY } BufferState;

	PhyEnum phyState;
	uint8_t pktLength;			// pkt length including my header and trailer
	PhyPktBuf buffer1;			// 2 buffers for receiving and processing
	PhyPktBuf buffer2;
	BufferState recvBufState;			// receiving buffer state
	BufferState procBufState;			// processing buffer state
	PhyPktBuf *procBufPtr;
	PhyPktBuf *recvPtr;
	PhyPktBuf *procPtr;
	uint8_t bufCur;
	uint8_t recvCount;
	uint16_t crcRx;				// CRC of received pkt
	uint16_t crcTx;				// CRC of transmitted pkt

	uint16_t update_crc(uint8_t data, uint16_t crc)
	{
		crc  = (uint8_t)(crc >> 8) | (crc << 8);
		crc ^= data;
		crc ^= (uint8_t)(crc & 0xff) >> 4;
		crc ^= (crc << 8) << 4;
		crc ^= ((crc & 0xff) << 4) << 1;
		dbg(DBG_CRC,"Updated crc to %04X using %02X\n",crc,data);
		return crc;
	}
	
	task void packet_received()
	{
		PhyPktBuf *tmp;
		uint16_t error;
		uint8_t len;
		uint8_t i;
		uint16_t testCRC;

		len = procPtr->length;
		call Debug.tx16status(__CRC,crcRx);
		memcpy(&testCRC,((uint8_t*)procPtr) + len - 2,2);
		if (crcRx != testCRC)
			error = testCRC;
		else
			error = 0;

		call Debug.txStatus(_PKT_LENGTH,len);
		dbg(DBG_AM,"Packet data in: ");
		for (i=0;i<len;i++)
		{
			call Debug.txStatus(_PKT_DATA,((uint8_t*)procPtr)[i]);
			dbg_clear(DBG_AM, "%02hhx ", ((uint8_t*)procPtr)[i]);
		}
		dbg_clear(DBG_AM, "\n");
		if (error != 0)
		{
			dbg(DBG_PACKET,"Bad packet! (we got %04X as CRC) not %04X\n",crcRx,testCRC);
		}

		tmp = signal PhyComm.rxPktDone(procPtr, error, (rssi*1.0)/len); // note that rssi is a total, and we should send up an average
		if (tmp)
		{
			atomic 
			{
				if (recvBufState == BUF_BUSY)
				{					// waiting for a free buffer
					procPtr = recvPtr;
					recvPtr = tmp;
					recvBufState = BUF_FREE;	// can start receive now
				}
				else
				{
					procPtr = NULL;
					procBufPtr = tmp;
					procBufState = BUF_FREE;
				}
			}

			if (procPtr)
			{					// have a buffered packet to signal
				if (!post packet_received())
				{				// task queue is full
					atomic
					{
						procBufPtr = procPtr;	//drop packet
						procBufState = BUF_FREE;
					}
					signal PhyComm.rxPktDone(NULL, 2,0);	// signal in case MAC is waiting
				}
			}
		}
	}




	command result_t PhyControl.init()
	{
		//phyState = IDLE;
		//call Debug.txStatus(_PHY_STATE,phyState);
		atomic 
		{
			recvPtr = &buffer1;
			procBufPtr = &buffer2;
			recvBufState = BUF_FREE;
			procBufState = BUF_FREE;
			radioState = RC_INIT;			// just for changing to idle state
			stored_data = FALSE;
			offset = 0;
		}
		dbg(DBG_USR1, "BOOT: phycontrol\n");

		/* Radcontrol.init */
		//call Debug.txStatus(_MM_RADIO_STATE,radioState);
		return rcombine(call RadioSPI.init(),call PhyState.idle());
	}

	command result_t PhyControl.start()
	{
		dbg(DBG_USR1, "Phycontrol : start\n");
		return RadioState_idle();
	}


	command result_t PhyControl.stop()
	{
		dbg(DBG_USR1, "Phycontrol : stop\n");
		return SUCCESS;
	}


	command result_t PhyState.idle()
	{
		result_t ret = SUCCESS;
		if (phyState == RECEIVING)
			atomic phyState = RECEIVING_LAST;
		else
		{
			dbg(DBG_USR1, "Phycontrol : idle\n");
			atomic phyState = PHY_IDLE;
			ret = RadioState_idle();
		}
		//call Debug.txStatus(_PHY_STATE,phyState);
		return ret;
	}


	command result_t PhyState.sleep()
	{
		dbg(DBG_USR1, "Phycontrol : sleep\n");
		atomic phyState = PHY_IDLE;
		//call Debug.txStatus(_PHY_STATE,phyState);
		return RadioState_sleep();
	}


	command result_t PhyComm.txPkt(PhyPktBuf *packet, uint8_t length)
	{
		dbg(DBG_USR1, "RADIO: start send (len=%d, phyState=%d)\n", length,phyState);
		call Debug.txStatus(_PHY_PKT_SIZE,length);
		if (length > PHY_MAX_PKT_LEN || length < PHY_MIN_PKT_LEN)
		{
			call Debug.txState(PHY_BAD_SIZE);
			return FAIL;
		}
		if (phyState != PHY_IDLE && phyState != RECEIVING)
		{
			call Debug.txStatus(_PHY_BAD_STATE,phyState);
			return FAIL;
		}
		atomic phyState = TRANSMITTING;
		//call Debug.txStatus(_PHY_STATE,TRANSMITTING);
		RadioByte_startTx();	// tell radio to start sending
		sendPtr = packet;
		sendPtr->length = length;	// fill my header field
		atomic pktLength = length;
		
			
		// encode first byte of the packet
		atomic bufCur = 0;
		crcTx = 0;//update_crc(((uint8_t*)sendPtr)[0], 0);
		//phyState = TRANSMITTING_DONE;
		return SUCCESS;
	}


	// default do-nothing event handler for PhyComm interface
	default event result_t PhyComm.txPktDone(PhyPktBuf *packet)
	{
		return SUCCESS;
	}


	default event result_t PhyComm.startSymDetected(PhyPktBuf *packet)
	{
		dbg(DBG_USR1, "Phycomm: startsym\n");
		return SUCCESS;
	}


	default event PhyPktBuf* PhyComm.rxPktDone(PhyPktBuf *packet, uint16_t error, uint16_t rssi_in)
	{
		return packet;
	}


	result_t decodeDone(uint8_t data)
	{
		dbg(DBG_RADIO, "incoming data = %02X\n", (unsigned char) data);
		// one byte is decoded
		//call Debug.txStatus(_PHY_RADIO_RECV,data);
		if (recvCount == 0)
		{	
			// first proper byte is packet length
			if (data > PHY_MAX_PKT_LEN || data < PHY_MIN_PKT_LEN)
			{
				call PhyState.idle();
				dbg(DBG_ERROR,"Dodgy packet :%d\n",data);
				// signal received an erroneous packet with NULL buffer
				// unknown length (0)
				signal PhyComm.rxPktDone(NULL, data==0?0xF1:data,0);
				return FAIL;
			}
			pktLength = (uint8_t) data;
			crcRx = 0;
			call Debug.txStatus(_PHY_PKT_SIZE,pktLength);
			dbg(DBG_PACKET, "Packet size = %d\n", pktLength);
		}
		((uint8_t*)recvPtr)[recvCount] = data;
		recvCount++;

		if (recvCount < pktLength - 1)
		{
			crcRx = update_crc(data, crcRx);
		}
		else if (recvCount == pktLength)
		{						// Rx packet done
			if (procBufState == BUF_FREE)
			{					// have a free buffer, use it now
				procPtr = recvPtr;
				recvPtr = procBufPtr;
				recvBufState = BUF_FREE;
				if (post packet_received())
				{				// signal upper layer
					procBufState = BUF_BUSY;
				}
				else
				{				// task queue is full
					procBufPtr = procPtr;	//drop packet
					signal PhyComm.rxPktDone(NULL, 2,0);	// signal in case MAC is waiting
				}
			}
			else
			{					// no buffer to use for Rx
				recvBufState = BUF_BUSY;
			}
			call PhyState.idle();
			dbg(DBG_PACKET, "Packet finished\n");
		}
		return SUCCESS;
	}


	result_t PhyByte_txByteReady()
	{
		//dbg(DBG_ERROR, "Warning! txByteReady() got called!\n");
		// radio asks a byte to transmit
		if (phyState == TRANSMITTING)
		{
			atomic
			{
				nextByte = ((uint8_t*)sendPtr)[bufCur];
				stored_data = TRUE;
				bufCur++;
				crcTx = update_crc(nextByte, crcTx);
			}
			//now check if that was the last byte
			if (bufCur == pktLength - 2)
			{
				dbg(DBG_CRC,"Recording CRC as %04X\n",crcTx);
				/*sendPtr[pktLength-2] = (crcTx & 0xFF00) >> 8;
				sendPtr[pktLength-1] = (crcTx & 0xFF);*/
				memcpy(((uint8_t*)sendPtr) + pktLength - 2,&crcTx,2);
				call Debug.tx16status(__CRC,*(uint16_t*)(((uint8_t*)sendPtr)+pktLength-2));
			}
			else if (bufCur == pktLength)
			{
				// tx is done
				phyState = TRANSMITTING_LAST;
				//call Debug.txStatus(_PHY_STATE,phyState);
			}
		}
		else if (phyState == TRANSMITTING_LAST)
		{
			dbg(DBG_USR1,"Moving to transmit done phyState\n");
			phyState = TRANSMITTING_DONE;
			call Debug.txStatus(_PHY_STATE,phyState);
		}
		else if (phyState == TRANSMITTING_DONE)
		{
			atomic phyState = PHY_IDLE;
//GPH			call PhyState.idle();
			// signal upper layer Tx done
/*GPH			if (!post packet_sent())
			{					// try to post task first
				signal PhyComm.txPktDone(sendPtr);	// signal directly if can't post
			}*/
			dbg(DBG_PACKET, "Packet sent\n");
		}

		return SUCCESS;
	}


	inline result_t PhyByte_startSymDetected()
	{
		// Phy must be in IDLE state, otherwise there is a bug
		if (phyState == PHY_IDLE && recvBufState == BUF_FREE)
		{
			phyState = RECEIVING;
			//call Debug.txStatus(_PHY_STATE,RECEIVING);
			recvCount = 0;
			// signal MAC w/ receiving buffer so that it can put in timestamp
			return signal PhyComm.startSymDetected(recvPtr);
		}
		return FAIL;
	}


	result_t PhyByte_rxByteDone(uint8_t data)
	{
		if (phyState == RECEIVING || phyState == RECEIVING_LAST)
		{
			dbg(DBG_RADIO, "incoming data (not decoded) = %02X\n", (unsigned char) data);
			//call Debug.txStatus(_PHY_RECV_UNDECODE,data);
			if (recvCount == 0)
			{
				if (data == 0xF0)	// 1 (or 2 depending on how fast we were) bytes at beginning are 0xF0. Discard them! 
				{
					//call Debug.txStatus(_PHY_RECV_UNDECODE,data);
					return SUCCESS;
				}
				rssi = 0; // cumulative count over all bytes
			}
			if (phyState == RECEIVING)
				rssi += call RadioSPI.getRSSI();
			decodeDone(data);
			if (phyState == RECEIVING_LAST)
				call PhyState.idle();
			return SUCCESS;
		}
		return FAIL;
	}

}
// end of implementation
