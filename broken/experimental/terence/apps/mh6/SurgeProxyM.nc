/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: SurgeProxyM.nc,v 1.7 2003/03/13 07:57:29 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * This thing act as a proxy to translate packet. it is a fast hack
 * it shouldn't be here in the beginning !!! This is solely for the 
 * purpose of surge demo
 * Author: Terence Tong
 */
/*////////////////////////////////////////////////////////*/

includes Statistic;
includes Routing;

module SurgeProxyM {
  provides {
    interface SendMsg as IncomingMsg[uint8_t id];
  }
  uses {
    interface SendMsg as OutgoingMsg[uint8_t id];
  }
	
} 
implementation {
  TOS_Msg surgeMsg;
  TOS_MsgPtr oldPointer;

  typedef struct SurgeMsg {
    uint8_t type;
    uint16_t sourceaddr;
    uint16_t originaddr;
    uint16_t parentaddr;
    uint8_t seqno;
    uint8_t hopcount;
    uint16_t reading;
    uint8_t parent_link_quality;
    uint8_t nbrs[4];
    uint8_t q[4];
    uint32_t debug_code;
  } SurgeMsg;
  /*
    typedef struct MultiHopStatMsg {
    uint8_t source; 0
    int8_t seqnum; 1
    uint8_t mhsenderType; 2
    uint8_t dataSeqnum; 3
    uint8_t realSource; 4
    uint16_t dataGenerated; 5
    uint16_t forwardPacket; 7
    uint16_t totalRetransmission; 9
    uint8_t numTrans; 11
    uint8_t parent; 12
    uint16_t cost; 13
    uint8_t hop; 15
    uint8_t id[5]; 16
    uint8_t quality[5]; 21
    uint16_t reading; 26
    } MultiHopStatMsg;
  */	
  void translateToSurge(TOS_MsgPtr fromMsg, TOS_MsgPtr toMsg) {
    TOS_MsgPtr mhsm = fromMsg;
    SurgeMsg *sm = (SurgeMsg *) toMsg->data;

    uint16_t sourceaddr = mhsm->data[0];
    uint16_t originaddr = mhsm->data[4];
    uint16_t parentaddr = mhsm->data[12];
    uint8_t seqno = mhsm->data[5];
    uint16_t reading;

    uint8_t hopcount = mhsm->data[15];

    uint8_t parent_link_quality = mhsm->data[21];
    uint8_t i, nbrs[4], quality[4];
    uint32_t estimate;

    reading = (uint16_t) mhsm->data[26];
    reading += ((uint16_t) mhsm->data[27]) << 8;
    if (originaddr == BASE_STATION) {
      parent_link_quality = 100;
      reading = 0;
    } else {
      estimate = ((uint32_t) parent_link_quality * (uint32_t) 100) / (uint32_t) 255;
      parent_link_quality = estimate;
    }
    for (i = 0; i < 4; i++) {
      nbrs[i] = mhsm->data[17 + i];
      quality[i] = (nbrs[i] == (uint8_t) -1) ? 0 : mhsm->data[22 + i];
    }
    sm->type = 0;
    sm->sourceaddr = sourceaddr;
    sm->originaddr = originaddr;
    sm->parentaddr = parentaddr;
    sm->seqno = seqno;
    sm->hopcount = hopcount;
    sm->reading = 0; // WARNING reading;
    sm->parent_link_quality = parent_link_quality;
    for (i = 0; i < 4; i ++) {
      sm->nbrs[i] = nbrs[i];
      sm->q[i] = quality[i];
    }

		
  }

  command result_t IncomingMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    if (TOS_LOCAL_ADDRESS == BASE_STATION && msg->addr == TOS_UART_ADDR 
        && msg->type == RS_DATA_TYPE) {
      oldPointer = msg;
      translateToSurge(msg, &surgeMsg);
      return call OutgoingMsg.send[0x11](address, sizeof(SurgeMsg), &surgeMsg);
    } else {
      oldPointer = msg;
      msg->type = id;
      return call OutgoingMsg.send[id](address, length, msg);
    }
  }
  event result_t OutgoingMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    oldPointer->ack = msg->ack;
    //    oldPointer->ack = (msg->ack == 0 || success == FAIL) ? 0 : 1;
    return signal IncomingMsg.sendDone[oldPointer->type](oldPointer, success);
  }


}
