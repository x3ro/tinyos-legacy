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
 * Original S-MAC authors: Jerry Zhao, Wei Ye
 * T-MAC modifications: Tom Parker
 * 
 * This is a Wrapper for T-MAC to provide standard tinyos Send/Receive
 *   interface, so that AMStandard can run over T-MAC.
 *
 * This component is to provide compatibilty to Berkeley's comm stack and 
 *   enable applications developed on Berkeley's stack to run over T-MAC 
 *   without modification. 
 */

/**
 * @author Jerry Zhao
 * @author Wei Ye
 * @author Tom Parker
 */

includes PhyRadioMsg;

module TMACWrapper
{
	provides
	{
		interface StdControl as Control;
		interface ReceiveMsg as Receive;
		interface BareSendMsg as Send;
		interface PeekReceive;
		interface MessageNow[uint8_t id];
		interface RoutingHelpers;
	}
	uses
	{
		interface StdControl as MACControl;
		interface MACComm;
		interface RoutingHelpers as MyHelpers;
	}
}

implementation
{

#include "TMACWrapperMsg.h"
#include "TMACMsg.h"
#include "PhyConst.h"

	WrapMsg txBuf;
	TOS_MsgPtr txMsgPtr;
	bool txBusy;
	TOS_Msg rxBuf;
	TOS_MsgPtr rxMsgPtr;
	bool rxBusy;

	PhyPktBuf nowIn;
	
	command result_t Control.init()
	{
		memset(&nowIn,0,sizeof(PhyPktBuf));
		rxMsgPtr = &rxBuf;
		txBusy = FALSE;
		rxBusy = FALSE;
		return call MACControl.init();
	}


	command result_t Control.start()
	{
		return call MACControl.start();
	}


	command result_t Control.stop()
	{
		return call MACControl.stop();
	}

	void dbgPacket(WrapMsg* data, int msgLen)
	{
		uint8_t i;

		for (i = 0; i < msgLen; i++)
		{
			dbg_clear(DBG_AM, "%02hhx ", ((uint8_t *) data)[i]);
		}
		dbg_clear(DBG_AM, "\n");
		dbg(DBG_AM, "length = %d\n", msgLen);
	}

	command result_t Send.send(TOS_MsgPtr msg)
	{
		result_t ok;
		uint8_t msgLen, txLen;
		msgLen = msg->length + MSG_DATA_SIZE - DATA_LENGTH - 2;
		txLen = msgLen + 2;
		signal PeekReceive.PeekSend(msg);
		if (txBusy || txLen > PHY_MAX_PKT_LEN)
			return FAIL;
		txBusy = TRUE;
		memcpy(&(txBuf.tosMsg), msg, msgLen);
		if (msg->addr == TOS_BCAST_ADDR)
		{
			ok = call MACComm.broadcastMsg(&txBuf, txLen);
		}
		else
		{
			//Each unicast TOS_MSG is sent in one fragment.
			ok = call MACComm.unicastMsg(&txBuf, txLen, msg->addr); //, 1);
		}
		//dbgPacket(&txBuf,txLen);
		if (ok)
		{
			txMsgPtr = msg;
			return SUCCESS;
		}
		else
		{
			txBusy = FALSE;
			if (msg->addr == TOS_BCAST_ADDR) // standard TinyOS stack returns Ok for bcast, even when 0 neighbours
				return signal Send.sendDone(msg, SUCCESS);
			else
				return FAIL;
		}
	}

	event result_t MACComm.broadcastDone(void *msg)
	{
		txBusy = FALSE;
		return signal Send.sendDone(txMsgPtr, SUCCESS);
	}


	event result_t MACComm.unicastDone(void *msg, result_t success)//, uint8_t txFragCount)
	{
		txBusy = FALSE;
		return signal Send.sendDone(txMsgPtr, success);// (txFragCount == 1));
	}

	event void *MACComm.rxMsgDone(void *msg, uint16_t rssi)
	{
		uint8_t msgLen;
		TOS_MsgPtr tmp = &(((WrapMsg *) msg)->tosMsg);
		if (rxBusy || tmp->length > DATA_LENGTH)
			return msg;
		rxBusy = TRUE;
		msgLen = tmp->length + MSG_DATA_SIZE - DATA_LENGTH - 2;
		memcpy(rxMsgPtr, tmp, msgLen);
		//CRC is passed in TMAC so 
		rxMsgPtr->crc = 1;
		rxMsgPtr->time = 0;
		rxMsgPtr->strength = rssi;
		signal PeekReceive.PeekReceive(rxMsgPtr);
		tmp = signal Receive.receive(rxMsgPtr);
		if (tmp)
			rxMsgPtr = tmp;
		rxBusy = FALSE;
		return msg;
	}

	default event void PeekReceive.PeekReceive(TOS_MsgPtr ptr) {}
	default event void PeekReceive.PeekSend(TOS_MsgPtr ptr) {}

	command result_t MessageNow.send[uint8_t id](struct TOS_Msg* pkt, uint8_t length)
	{
		pkt->length = length;
		length += OFFSET(struct TOS_Msg,data);
		nowIn.data[0] = LAST_PKT_TYPE+1+id;
		dbg(DBG_ERROR,"Weird packet going out on port %d (conv as %d)\n",id,nowIn.data[0]);
		memcpy(&nowIn.data[1],pkt,length); /* copy in all fields including used data */
		return call MACComm.txRaw((uint8_t*)&nowIn, length+1+2); // plus type on the front, and crc on the back
	}

	command uint8_t MessageNow.sendTime[uint8_t id](uint8_t length)
	{
		return (PRE_PKT_BYTES + (length+OFFSET(struct TOS_Msg,data)+1+2) * ENCODE_RATIO) * 8 / BANDWIDTH;
	}

	event result_t MACComm.txRawDone(uint8_t* packet)
	{	
		uint8_t id;
		if (packet!=(uint8_t*)&nowIn)
		{
			dbg(DBG_ERROR,"MACcomm: not the now packet\n");
			return FAIL;
		}
		id = /**(packet+offsetof(struct TOS_Msg,data))*/nowIn.data[0]-LAST_PKT_TYPE-1;
		return signal MessageNow.sendDone[id]((TOS_MsgPtr)nowIn.data,SUCCESS);
	}

	event void* MACComm.rxWeirdDone(void* packet, uint16_t rssi)
	{
		PhyPktBuf *pktIn = (PhyPktBuf*)packet;
		uint8_t id = pktIn->data[0]-LAST_PKT_TYPE-1;
		TOS_MsgPtr in = (TOS_MsgPtr)&pktIn->data[1];
		dbg(DBG_ERROR,"Weird packet going to port %d\n",id);
		call MyHelpers.forceNoSleep(signal MessageNow.receive[id](in),TRUE);
		return packet;
	}

	inline command uint8_t RoutingHelpers.sendTime(uint8_t length){return call MyHelpers.sendTime(length);}
	inline command uint16_t* RoutingHelpers.getNeighbours() {return call MyHelpers.getNeighbours();}
	inline command result_t RoutingHelpers.forceNoSleep(uint16_t msec, bool forReply) {return call MyHelpers.forceNoSleep(msec,forReply);}
	inline command result_t RoutingHelpers.endForce() {return call MyHelpers.endForce();}

	inline event void MyHelpers.newNeighbour(uint16_t neigh){signal RoutingHelpers.newNeighbour(neigh);}
	inline event void MyHelpers.noSleepDone(result_t success) {signal RoutingHelpers.noSleepDone(success);}
	inline event void MyHelpers.forceComplete(){signal RoutingHelpers.forceComplete();}

	inline default event void RoutingHelpers.newNeighbour(uint16_t neigh){}
	inline default event void RoutingHelpers.noSleepDone(result_t res){}
	inline default event void RoutingHelpers.forceComplete(){}
	

	default event uint8_t MessageNow.receive[uint8_t id](TOS_MsgPtr msg) {return 0;}
	default event result_t MessageNow.sendDone[uint8_t id](TOS_MsgPtr m, result_t success) {return success;}
	default event result_t Send.sendDone(TOS_MsgPtr m, result_t success) {return success;}
	default event TOS_MsgPtr Receive.receive(TOS_MsgPtr m) {return m;}


	/*event result_t MACComm.txFragDone(void *frag)
	{
		//Each unicast TOS_MSG is sent in one fragment.
		//This event should never be called
		return SUCCESS;
	}*/
}
