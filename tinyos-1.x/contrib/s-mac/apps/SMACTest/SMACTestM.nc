/*									tab:4
 * Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye
 * Date created: 1/21/2003
 *
 * This application tests functionalitis of Sensor-MAC (S-MAC), and shows how
 * to use S-MAC. 
 *
 */

module SMACTestM
{
   provides interface StdControl;
   uses {
      interface StdControl as MACControl;
      interface MACComm;
      interface LinkState;
      interface MACTest;
      interface Leds;
   }
}

implementation
{
#include "SMACConst.h"

#define MAX_NUM_NEIGHB (TST_MAX_NODE_ID - TST_MIN_NODE_ID)

   // test mode
   typedef enum {
      BROADCAST,
      UNICAST,
      STOP
   } TxMode;

   // neighbor list stores the link state info (from a neighbor to me)
   // For unicast, numTxFrags and numRxFrags are the most accurate measure,
   // since they are at the fragment level. Message level reception rate is
   // not very useful due to fragment-level retransmissions. The numLostUMsgs
   // reflects the sequence number jumps on unicast messages. Lost of a unicast
   // message could due to several reasons, and could not very accurately
   // reflect the one-directional link quality.
   typedef struct {
      char state;
      uint16_t nodeId;
      uint8_t syncSeqNo;    // latest SYNC sequence number from this node
      uint8_t numRxSync;    // number of received SYNC packets
      uint8_t numLostSync;  // number of lost SYNC packets
      uint8_t bcastSeqNo;   // latest broadcast seqNo from this node
      uint8_t numRxBcast;   // number of received broadcast packets
      uint8_t numLostBcast; // number of lost broadcast packets
      uint8_t ucastSeqNo;   // latest unicast seqNo from this node
      uint8_t numLostUMsgs; // number of lost unicast messages
      uint8_t numTxFrags;   // number of unicast fragments from the neighbor
      uint8_t numRxFrags;   // number of received unicast fragments
   } NeighbList;

   TxMode txMode;
   uint16_t unicastId;    // where to send my unicast msgs.
   uint8_t numFrags;      // number of remaining fragments
   uint8_t numTxBcast;    // number of broadcast Tx
   uint8_t numTxUcast;    // number of unicast Tx
   uint16_t timeCount;    // when next packet will be generated
   AppPkt dataPkt;        // message to be sent
   char send_pending;     // flag
   
   // for testing LinkState interface
   NeighbList neighbList[MAX_NUM_NEIGHB];
   uint8_t numNeighb;  // number of active neighbors
   uint8_t numTxFrags; // number of transmitted frags for current msg 
   uint8_t numRxFrags; // number of received frags for current msg

   // function prototypes
   uint8_t getNodeIdx(uint16_t nodeAddr);
   
   command result_t StdControl.init()
   {
      uint8_t i;

#ifdef TST_UNICAST_ONLY
      txMode = UNICAST;
#else
      txMode = BROADCAST;
#endif
#ifdef TST_UNICAST_ADDR
      unicastId = TST_UNICAST_ADDR;
#else
      if (TOS_LOCAL_ADDRESS == TST_MAX_NODE_ID) {
         unicastId = TST_MIN_NODE_ID;
      } else {
         unicastId = TOS_LOCAL_ADDRESS + 1;
      }
#endif
      numTxBcast = 0;
      numTxUcast = 0;
      send_pending = 0;
#ifdef TST_RECEIVE_ONLY
      timeCount = 0;
#else
      timeCount = TST_MSG_INTERVAL;
#endif
      
      for (i = 0; i < MAX_NUM_NEIGHB; i++) {
         neighbList[i].state = -1;
      }
      numNeighb = 0;
      numTxFrags = 0;
      numRxFrags = 0;
      
      call MACControl.init();   // initialize MAC and lower layers
      call Leds.init();
      call Leds.yellowOn();
      return SUCCESS;
   }


   task void sendMsg()
   {
      uint8_t i, payloadPos;
      // construct a new message
      dataPkt.hdr.numTxBcast = numTxBcast;
      dataPkt.hdr.numTxUcast = numTxUcast;
      
      // dump the neighbor list to payload
      // need to check if the payload length is enough
      payloadPos = 0;
      for (i = 0; i < MAX_NUM_NEIGHB; i++) {
         if (neighbList[i].state >= 0 && 
            payloadPos + sizeof(NeighbList) <= APP_PAYLOAD_LEN) {
            memcpy(dataPkt.data + payloadPos, &(neighbList[i]), 
                  sizeof(NeighbList));
            payloadPos += sizeof(NeighbList);
         }
      }
      
      if (txMode == BROADCAST) {
         if (call MACComm.broadcastMsg(&dataPkt, sizeof(dataPkt)) == SUCCESS) {
            send_pending = 1;
         }
      } else if (txMode == UNICAST) {
         numFrags= TST_NUM_FRAGS;
         if (call MACComm.unicastMsg(&dataPkt, sizeof(dataPkt), unicastId,
                TST_NUM_FRAGS) == SUCCESS) {
            send_pending = 1;
         } else { // destination node is unknown
            txMode = BROADCAST;
         }
      }
   }


   command result_t StdControl.start()
   {
#ifndef TST_RECEIVE_ONLY
#ifdef TST_MSG_INTERVAL
#if (TST_MSG_INTERVAL == 0)
      post sendMsg();
#endif
#endif
#endif
      return SUCCESS;
   }


   command result_t StdControl.stop()
   {
      return SUCCESS;
   }


   uint8_t getNodeIdx(uint16_t nodeAddr)
   {
      // get the index of a node in the neighbor list
      // return MAX_NUM_NEIGHB if cannot find it
      uint8_t i;
      for (i = 0; i < MAX_NUM_NEIGHB; i++) {
         if (neighbList[i].state >= 0 &&
            neighbList[i].nodeId == nodeAddr) { // a known neighbor
            return i;
         }
      }
      return MAX_NUM_NEIGHB;
   }

   
   event void MACTest.clockFire()
   {
      if (timeCount > 0) {
         timeCount--;
         if (timeCount == 0) {
            if (txMode != STOP) timeCount = TST_MSG_INTERVAL;
            if (send_pending == 0) post sendMsg();
         }
      }
   }


   event void MACTest.MACSleep()
   {
      call Leds.yellowOff();  // turn off yellow led when sleep
   }


   event void MACTest.MACWakeup()
   {
      call Leds.yellowOn();  // turn on yellow led when wake-up
   }


   event result_t MACComm.broadcastDone(void* msg)
   {
      call Leds.redToggle();
      numTxBcast++;
#ifndef TST_BROADCAST_ONLY
      txMode = UNICAST;
#endif
#ifdef TST_NUM_MSGS
      if (numTxBcast + numTxUcast == TST_NUM_MSGS) txMode = STOP;
#endif
      send_pending = 0;
#ifndef TST_RECEIVE_ONLY
#ifdef TST_MSG_INTERVAL
#if (TST_MSG_INTERVAL == 0)
      post sendMsg();
#endif
#endif
#endif
      return SUCCESS;
   }


   event result_t MACComm.txFragDone(void* frag)
   {
      call Leds.redToggle();
      numFrags--;
      if (numFrags > 0) {
         call MACComm.txNextFrag(&dataPkt);
      }
      return SUCCESS;
   }


   event result_t MACComm.unicastDone(void* msg, uint8_t txFragCount)
   {
      numTxUcast++;
      if (txFragCount > 0) {
         call Leds.redToggle();
      }
#ifndef TST_UNICAST_ONLY
      txMode = BROADCAST;
#endif
#ifdef TST_NUM_MSGS
      if (numTxBcast + numTxUcast == TST_NUM_MSGS) txMode = STOP;
#endif
      send_pending = 0;
#ifndef TST_RECEIVE_ONLY
#ifdef TST_MSG_INTERVAL
#if (TST_MSG_INTERVAL == 0)
      post sendMsg();
#endif
#endif
#endif
      return 1;
   }


   event void* MACComm.rxMsgDone(void* msg)
   {
      AppPkt* pkt;
      pkt = (AppPkt*)msg;
      call Leds.greenToggle();
#ifdef TST_RECEIVE_ONLY
#ifdef TST_NUM_MSGS
      if (pkt->hdr.numTxBcast > 0) pkt->hdr.numTxBcast++;
      if (pkt->hdr.numTxUcast > 0) pkt->hdr.numTxUcast++;
      if (pkt->hdr.numTxBcast + pkt->hdr.numTxUcast == TST_NUM_MSGS)
         post sendMsg();
#endif
#endif
      return msg;
   }
   

   // event handlers for LinkState interface

   event void LinkState.nodeJoin(uint16_t nodeAddr)
   {
      // a new node joins, add a new entry in neighbor list
      uint8_t i;
      for (i = 0; i < MAX_NUM_NEIGHB; i++) {
         if (neighbList[i].state < 0) {
            neighbList[i].state = 0;  // mark as valid entry
            neighbList[i].nodeId = nodeAddr;
            // clear link state statistics
            neighbList[i].syncSeqNo = 0;
            neighbList[i].numRxSync = 0;
            neighbList[i].numLostSync = 0;
            neighbList[i].bcastSeqNo = 0;
            neighbList[i].numRxBcast = 0;
            neighbList[i].numLostBcast = 0;
            neighbList[i].ucastSeqNo = 0;
            neighbList[i].numLostUMsgs = 0;
            neighbList[i].numTxFrags = 0;
            neighbList[i].numRxFrags = 0;
            break;
         }
      }
   }
   

   event void LinkState.nodeGone(uint16_t nodeAddr)
   {
      // a neighbor is gone, remove the node entry from neighbor list
      uint8_t i;
      i = getNodeIdx(nodeAddr);
      if (i < MAX_NUM_NEIGHB) {
         neighbList[i].state = -1;
      }
   }
   

   event void LinkState.rxSyncPkt(uint16_t fromAddr, uint8_t seqNo)
   {
      // a sync packet is received, update neighbor statistics
      uint8_t i, increment;
      i = getNodeIdx(fromAddr);
      if (i < MAX_NUM_NEIGHB) {  // node is on my neighbor list
         neighbList[i].numRxSync++;
         // if it is the first received SYNC packet, don't check 
         // packet loss, since we don't have a reference seqNo yet.
         if (neighbList[i].numRxSync != 1) { // not first received SYNC
            if (seqNo < neighbList[i].syncSeqNo) { // seqNo wraps around
               increment = seqNo + (SMAC_MAX_SYNC_SEQ_NO - 
                           neighbList[i].syncSeqNo) + 1;
            } else {
               increment = seqNo - neighbList[i].syncSeqNo;
            }
            if (increment > 1) {  // lost SYNC packet
               neighbList[i].numLostSync += increment - 1;
            }
         }
         neighbList[i].syncSeqNo = seqNo;
      }
   }
   
   
   event void LinkState.rxBcastPkt(uint16_t fromAddr, uint8_t seqNo)
   {
      // a broadcast packet is received, record its sequence number
      uint8_t i, increment;
      i = getNodeIdx(fromAddr);
      if (i < MAX_NUM_NEIGHB) {
         neighbList[i].numRxBcast++;
         // if it is the first received broadcast packet, don't check 
         // packet loss, since we don't have a reference seqNo yet.
         if (neighbList[i].numRxBcast != 1) { // not first packet
            if (seqNo < neighbList[i].bcastSeqNo) { // seqNo wraps around
               increment = seqNo + (SMAC_MAX_BCAST_SEQ_NO - 
                           neighbList[i].bcastSeqNo) + 1;
            } else {
               increment = seqNo - neighbList[i].bcastSeqNo;
            }
            if (increment > 1) {  // lost broadcast packet
               neighbList[i].numLostBcast += increment - 1;
            }
         }
         neighbList[i].bcastSeqNo = seqNo;
      }
   }


   event void LinkState.rxUcastPkt(uint16_t fromAddr, uint8_t seqNo,
                                  uint8_t numTx, uint8_t numRx)
   {
      // a unicast packet is received, record its sequence number
      uint8_t i, increment;
      i = getNodeIdx(fromAddr);
      if (i < MAX_NUM_NEIGHB) {
         neighbList[i].numTxFrags += numTx;
         neighbList[i].numRxFrags += numRx;
         if (neighbList[i].numRxFrags == numRx) {
            // likely to be the first received unicast packet/fragment
            // Don't check packet loss, since we don't have a reference seqNo.
            // There may be an error on the number of lost packets when 
            // numRxFrags wraps around, but it should be negligible over time.
            neighbList[i].ucastSeqNo = seqNo;
            return;
         }
         if (seqNo == neighbList[i].ucastSeqNo) { // duplicate reception
            // since numTx and numRx include previous duplicates, need adjust
            neighbList[i].numTxFrags -= numTxFrags;
            neighbList[i].numRxFrags -= numRxFrags;
            numTxFrags = numTx; // for current msg
            numRxFrags = numRx; // for current msg
         } else { // new msg
            if (seqNo < neighbList[i].ucastSeqNo) { // seqNo wraps around
               increment = seqNo + (SMAC_MAX_UCAST_SEQ_NO - 
                           neighbList[i].ucastSeqNo) + 1;
            } else {
               increment = seqNo - neighbList[i].ucastSeqNo;
            }
            if (increment > 1) {  // lost unicast packet
               neighbList[i].numLostUMsgs += increment - 1;
            }
            neighbList[i].ucastSeqNo = seqNo;
            numTxFrags = 0;
            numRxFrags = 0;
         }
      }
   }

}  // end of implementation

