/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: MHSenderM.nc,v 1.6 2003/03/07 07:14:32 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * This component decides when, what to send, retransmit
 * Author: Terence Tong, Alec Woo
 */
/*////////////////////////////////////////////////////////*/

#include "FifoQueueSize.h"
#include "fatal.h"
includes Routing;
includes MHSender;
includes VirtualComm;
includes RoutingStackShared;

module MHSenderM {
  provides {
    interface BareSendMsg as OriginatedMsg[uint8_t msgId];
    interface StdControl;
  }
  uses {
    interface ReceiveMsg as ForwardReceive;
    interface MHSend2Comm;
    interface FifoQueue;
    interface Leds;
  }
}

implementation {

  uint8_t sending;
  // storage for data packet
  uint8_t pendingOriginatedData[FIFOQUEUE_SIZE(MHSENDER_DATA_QUEUE_SIZE)];
  QueuePtr pendingOriginated;

  // da forward queue
  uint8_t forwardQueueData[FIFOQUEUE_SIZE(MHSENDER_FORWARD_QUEUE_SIZE)];
  QueuePtr forwardQueue;

  // buffer for da comm layer, so it would not recycle the wrong stuff
  TOS_Msg freeListSpace[MHSENDER_FORWARD_QUEUE_SIZE];
  uint8_t freeListData[FIFOQUEUE_SIZE(MHSENDER_FORWARD_QUEUE_SIZE)];
  QueuePtr freeList;

  // message pointer to know what we just send, so that we could know we are sending data packet or forward packet
  uint8_t trialCounter;
  uint8_t dice;

  int8_t dataSeqnum;

  typedef struct PacketHistory {
    uint8_t realSource;
    uint8_t dataSeqnum;
  } PacketHistory;
  PacketHistory packetHistory[MHSENDER_PACKET_HISTORY_SIZE];
  uint8_t packetHistoryIndex;

  // data = 0, forward 1, none 2
  // alternate

#define DECISION_DATA 0
#define DECISION_FORWARD 1
#define DECISION_NOTSENDING 2

#define MHSENDER_HEADER_OFFSET (sizeof(VirtualCommHeader) + sizeof(RoutingHeader))

  uint8_t interruptOff() {
    return TOSH_interrupt_disable();
  }
  void interruptOn(uint8_t oldState) {
    if (oldState == 1) {
      TOSH_interrupt_enable();
    }
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * This put the packet to the packet history so we can read from it later
   * @author: terence
   * @param: msg, the packet that we are going to save
   * @return: void
   */

  void recordPacketToHistory(TOS_MsgPtr msg) {
    MHSenderHeader *mhsenderHeader = (MHSenderHeader *) &msg->data[MHSENDER_HEADER_OFFSET];
    packetHistory[packetHistoryIndex].realSource = mhsenderHeader->realSource;
    packetHistory[packetHistoryIndex].dataSeqnum = mhsenderHeader->dataSeqnum;
    packetHistoryIndex = (packetHistoryIndex + 1) % MHSENDER_PACKET_HISTORY_SIZE;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * Is this packet a duplicate packet, It just compare the incoming packet with the packet 
   * history
   * @author: terence
   * @param: msg, the packet that you want to check it is duplicate
   * @return: 1, if yes, 0 if no
   */

  uint8_t isDuplicatePacket(TOS_MsgPtr msg) {
    uint8_t i;
    MHSenderHeader *mhsenderHeader = (MHSenderHeader *) &msg->data[MHSENDER_HEADER_OFFSET];
    for (i = 0; i < MHSENDER_PACKET_HISTORY_SIZE; i++) {
      if (packetHistory[i].realSource == mhsenderHeader->realSource
          && packetHistory[i].dataSeqnum == mhsenderHeader->dataSeqnum) {
        return 1;
      }
    }
    return 0;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * Assume Data interval is very big. so most of the data is mostly forward
   * we want to give data priority whenever data comes
   * @author: terence
   * @param: decision, a pointer passed from the calling funciton,
   *          the result will be passed this value
   * @param: forward, 1 if there is data in forward queue
   * @param: data, 1 if there is originated data
   * @return: void
   */

  void makeDecisionData(uint8_t *decision, uint8_t forward, uint8_t data) {
    *decision = DECISION_NOTSENDING;
    if (data == 1) {
      *decision = DECISION_DATA;
      return;
    }
    if (forward == 1) {
      *decision = DECISION_FORWARD;
      return;
    }
  }


  /*////////////////////////////////////////////////////////*/
  /**
   * We called this function when we want to send something out if possible
   * It use control the knob between the Data queue and forward queue
   * passed the data to really send it
   * @author: terence
   * @param: void
   * @return: void
   */

  void trySendMsg() {
    TOS_MsgPtr msgToSend;
    uint8_t isOriginated, decision, forward, data;
    result_t sendResult;
    uint8_t oldState = interruptOff();

    // if it is already sending, forget it!
    if (sending == 1) { interruptOn(oldState); return; }
    // detect if we have forward data and originated data
    forward = !call FifoQueue.isEmpty(forwardQueue);
    data = !call FifoQueue.isEmpty(pendingOriginated);

    // if we have none, forget it!
    if (forward == 0 && data == 0) { interruptOn(oldState); return; }
    // usee the decision alternate algorithm
    makeDecisionData(&decision, forward, data);
    // decide to forward data
    if (decision == DECISION_FORWARD) {
      //dequeue and send 
      isOriginated = 0;
      sending = 1;
      msgToSend = call FifoQueue.getFirst(forwardQueue);
      interruptOn(oldState);
      sendResult = call MHSend2Comm.send(msgToSend, isOriginated);
      // decide to send originated data
    } else if (decision == DECISION_DATA) {
      isOriginated = 1;
      sending = 1;
      msgToSend = call FifoQueue.getFirst(pendingOriginated);
      interruptOn(oldState);
      // copy pointer and send
      sendResult = call MHSend2Comm.send(msgToSend, isOriginated);
      // if fail, let people overwrite the data, set send data comm as not busy
    } else {
      interruptOn(oldState);
      return;
    }
    // send next message
    if (sendResult == FAIL) { signal MHSend2Comm.moveOnNextPacket(msgToSend); } 

  }

  /*////////////////////////////////////////////////////////*/
  /**
   * Initialise MHSender
   * @author: terence
   * @param: void
   * @return: SUCCESS
   */


  command result_t StdControl.init() {
    return SUCCESS;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * Initlise all the queues, counter, sending status
   * @author: terence
   * @param: void
   * @return: SUCCESS
   */

  command result_t StdControl.start() {
    int i;
    trialCounter = 0;
    sending = 0;
    // initialise the queues
    forwardQueue = 
      call FifoQueue.initQueue(forwardQueueData, FIFOQUEUE_SIZE(MHSENDER_FORWARD_QUEUE_SIZE));
    pendingOriginated = 
      call FifoQueue.initQueue(pendingOriginatedData, FIFOQUEUE_SIZE(MHSENDER_DATA_QUEUE_SIZE));
    freeList = 
      call FifoQueue.initQueue(freeListData, FIFOQUEUE_SIZE(MHSENDER_FORWARD_QUEUE_SIZE));
    // initialise the free list
    for (i = 0; i < MHSENDER_FORWARD_QUEUE_SIZE; i++) {
      call FifoQueue.enqueue(freeList, &freeListSpace[i]);
    }
    for (i = 0; i < MHSENDER_PACKET_HISTORY_SIZE; i++) {
      packetHistory[i].realSource = 0xff;
      packetHistory[i].dataSeqnum = 0xff;
    }
    packetHistoryIndex = 0;
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }


  /*////////////////////////////////////////////////////////*/
  /**
   * CollectData send message
   * @author: terence
   * @param: msg, pointer from multi-hop application to send
   * @return: always success
   */

  command result_t OriginatedMsg.send[uint8_t msgId](TOS_MsgPtr msg) {
    MHSenderHeader *mh = (MHSenderHeader *) &msg->data[MHSENDER_HEADER_OFFSET];
    uint8_t oldState = interruptOff();
    if (call FifoQueue.isFull(pendingOriginated)) { interruptOn(oldState); return FAIL; }
    // put the type in
    mh->mhsenderType = msgId;
    mh->dataSeqnum = dataSeqnum++;
    mh->realSource = TOS_LOCAL_ADDRESS;
    // enqueue it
    call FifoQueue.enqueue(pendingOriginated, msg);
    interruptOn(oldState);
    // try sending it
    trySendMsg();
    return SUCCESS;
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * A packet come and we need to forward it
   * we enqueue the message to the forward queue
   * take a packet from our free list, passed it back to the comm
   * @author: terence
   * @param: msg, pointer to be forwarded
   * @return: recycle packet
   */

  event TOS_MsgPtr ForwardReceive.receive(TOS_MsgPtr msg) {
    TOS_MsgPtr recycleMsg;
    uint8_t bufferOverflow, duplicate;
    uint8_t oldState = interruptOff();
    bufferOverflow = (call FifoQueue.isFull(forwardQueue) == 1) 
      || (call FifoQueue.isEmpty(freeList) == 1);
    duplicate = isDuplicatePacket(msg);
    // if queue overflow, discard! let comm recycle incoming msg
    if (bufferOverflow || duplicate) {
      interruptOn(oldState); return msg;
    }
    // put it in our forward queue, extract one from freelist
    call FifoQueue.enqueue(forwardQueue, msg);
    recycleMsg = call FifoQueue.dequeue(freeList);
    recordPacketToHistory(msg);
    interruptOn(oldState);
    // try send our message out if possible
    trySendMsg();
    // give back recycle packet
    return recycleMsg;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * Regardless the msg was successful, we are going to move on!
   * if the msg was a data packet, we signal up to multi-hop application
   * if not we recycle the send pointer
   * @author: terence
   * @param: msg, sent pointer
   * @return: void
   */

  event void MHSend2Comm.moveOnNextPacket(TOS_MsgPtr msg) {
    uint8_t mhsenderType;
    TOS_MsgPtr originatedMsg, forwardMsg;
    MHSenderHeader *mhsenderHeader;
    uint8_t dataQueueEmpty;
    uint8_t forwardQueueEmpty;
    uint8_t oldState = interruptOff();
    dataQueueEmpty = call FifoQueue.isEmpty(pendingOriginated);
    forwardQueueEmpty = call FifoQueue.isEmpty(forwardQueue);

    originatedMsg = dataQueueEmpty ? 0 : call FifoQueue.getFirst(pendingOriginated);
    forwardMsg = forwardQueueEmpty ? 0 : call FifoQueue.getFirst(forwardQueue);
    if (msg != originatedMsg && msg != forwardMsg) { interruptOn(oldState); return; }
    // we are not sending anymore
    trialCounter = 0;
    sending = 0;
    if (msg == originatedMsg) {
      // dequeue the data queue
      call FifoQueue.dequeue(pendingOriginated);
      mhsenderHeader = (MHSenderHeader *) &msg->data[MHSENDER_HEADER_OFFSET];
      mhsenderType = mhsenderHeader->mhsenderType;
      interruptOn(oldState);
      // signal the right multihop application
      signal OriginatedMsg.sendDone[mhsenderType](msg, SUCCESS);
    } else if (msg == forwardMsg) {
      call FifoQueue.dequeue(forwardQueue);
      // if forward packet, we recycle the packet
      call FifoQueue.enqueue(freeList, msg);
      interruptOn(oldState);
    } else {
      interruptOn(oldState);
    }
    trySendMsg();

  }
  /*////////////////////////////////////////////////////////*/
  /**
   * virtual comm tell us if we should resend, we make our retransmision
   * here
   * @author: terence
   * @param: msg, the msg pointer that failed transmission
   * @return: decision
   */

  event uint8_t MHSend2Comm.sendDoneFailException(TOS_MsgPtr msg) {
    uint8_t decision;
    uint8_t oldState = interruptOff();
    //if it is broadcast message, don't retransmit!
    if (msg->addr == TOS_BCAST_ADDR) {
      interruptOn(oldState); return 0;
    }
    //    PRINT("addr:%d Retransmitting\n", TOS_LOCAL_ADDRESS);
    // if it equal to our maxium number of retransmision
    if (trialCounter >= MHSENDER_RETRANSMIT_TRIAL) {
      // we don't retrnamsit!
      trialCounter = 0;
      decision = 0;
      //      PRINT("addr:%d giving up\n", TOS_LOCAL_ADDRESS);
    } else {
      // we increment the counter, and retransmsite
      trialCounter++;
      decision = 1;
    }
    interruptOn(oldState);
    return decision;
  }



}
