/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: VirtualCommM.nc,v 1.10 2003/03/20 10:10:52 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Terence Tong, Alec Woo
 * this component is a resource manager for the shared GenericComm
 * also provide retransmission
 */
/*////////////////////////////////////////////////////////*/

includes VirtualComm;
#include "FifoQueueSize.h"
#include "BitArraySize.h"
#include "fatal.h"

module VirtualCommM {
	provides {
    interface StdControl;
    interface VCSend[uint8_t msgId];
    interface VCExtractHeader;
  }
  uses {
    interface FifoQueue;
    interface BitArray;
    interface Timer as ResendTimer;
    interface SendMsg as CommSendMsg[uint8_t msgId];
    interface Random;
    interface Leds;
    interface Timer as HeartBeat;
    interface StdControl as CommControl;

  }


}
implementation {
  // this is where the store the information if a vitural comm is busy
  // virtual-comm busy bitmap
  uint8_t busyBitmapData[BITARRAY_SIZE(VC_BITMAP_SIZE)]; // could store 256 busy entry
  BitArrayPtr busyBitMap;
  // fifo packet queue

  uint8_t pendingQueueData[FIFOQUEUE_SIZE(VC_QUEUESIZE)];
  QueuePtr pendingQueue;

  // sending flag
  uint8_t timerSet, sending;
  // link seqnum
  int8_t linkSeqnum;

  uint8_t interruptOff() {
    return TOSH_interrupt_disable();
  }
  void interruptOn(uint8_t oldState) {
    if (oldState == 1) {
      TOSH_interrupt_enable();
    }
  }
  event result_t HeartBeat.fired() {
    (sending == 1) ? call Leds.redOn() : call Leds.redOff();
    call Leds.greenToggle();
    //(call FifoQueue.isEmpty(pendingQueue) == 1) ? call Leds.yellowOff() : call Leds.yellowOn();
    return SUCCESS;
  }

  // initialise all the data structure
  command result_t StdControl.init() {
    busyBitMap = call BitArray.initBitArray(busyBitmapData, BITARRAY_SIZE(VC_BITMAP_SIZE));
    pendingQueue = call FifoQueue.initQueue(pendingQueueData, FIFOQUEUE_SIZE(VC_QUEUESIZE));
    call Random.init();
    call CommControl.init();
    timerSet = 0;
    sending = 0;
    linkSeqnum = 1;
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call HeartBeat.start(TIMER_REPEAT, 50);
    call CommControl.start();
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    call CommControl.stop();
    return SUCCESS;
  }

  void setSending(uint8_t value) {
    if (value == 0) {
      sending = 0;
    } else if (value == 1) {
      sending = 1;
    }
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * schedule the timer to fire
   * if someone schedule a timer before, leave it alone. The invariant
   * would be there is only one timer at any moment
   * @author: terence
   * @param: void
   * @return: void
   */

  void startTimer() {
    uint16_t randomizedTime;
    // check if there is more message. if it is, do nothing, just return
    if (call FifoQueue.isEmpty(pendingQueue) == 1) { return; }
    if (timerSet == 1) { return; } // don't set the timer if it is
    timerSet = 1;
    // give me some random time, schedule timer
    // randomizedTime should be more than zero, otherwise timer won't fire
    randomizedTime = VC_MINIMUM_RESEND_TIME;
    randomizedTime += (call Random.rand() & 0xff);
    call ResendTimer.start(TIMER_ONE_SHOT, randomizedTime);
  }

  void printPacket(TOS_MsgPtr msg) {
    int i = 0;
    for(i = 0; i < msg->length; i++) {
      PRINT("%02x ", (uint8_t) msg->data[i]);
    }
    PRINT("\n");
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * this is called to send teh packet, do automatic retranmit
   * if send return fail
   * @author: terence
   * @param: void 
   * @return: void
   */
  void sendPacket() {
    uint8_t typeid;
    result_t sendResult;
    TOS_MsgPtr msgToSend;
    struct VirtualCommHeader *header;
    uint8_t oldState = interruptOff();
    // nothing to send, return
    if (call FifoQueue.isEmpty(pendingQueue) == 1) { interruptOn(oldState); return; }
    // if i am not sending anything right now, send it!
    // if timer is sent, which means we should not try to send anything, because comm is busy
    if (sending == 0 && timerSet == 0) {
      // getfirst of the queue
      msgToSend = (TOS_MsgPtr) call FifoQueue.getFirst(pendingQueue);
      // extract the addr, length, typeid from the msg
      typeid = msgToSend->type;
      // fill in the link seqnum
      header = (struct VirtualCommHeader *) msgToSend->data; 
      header->source = TOS_LOCAL_ADDRESS;
      header->seqnum = linkSeqnum;
      // send message!
      sendResult = call CommSendMsg.send[typeid](msgToSend->addr, msgToSend->length, msgToSend);
      // if send return success, keep the msg there
      // if fail start a timer, do automatic resend
      if (sendResult == FAIL){
        startTimer();
        setSending(0);
      } else {
        setSending(1);
      }
    }
    interruptOn(oldState);
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * Can VirtualComm handle more packet with this message type. This is necessary for 
   * application that do polling. like Neighborhood
   * @author: terence
   * @param: void 
   * @return: void
   */

  uint8_t isBusy(uint8_t msgId) {
    // if bit map says busy, return false
    if (call BitArray.readBitInArray(msgId, busyBitMap) == 1) return 1;
    // check if the queue is full, if so, return false
    if (call FifoQueue.isFull(pendingQueue) == 1) return 1;
    return 0;
  }


  /*////////////////////////////////////////////////////////*/
  /**
   * reset the timer and attemp to send packet
   * @author: terence
   * @param: void
   * @return: void
   */
  event result_t ResendTimer.fired() {
    timerSet = 0;
    sendPacket();
    return SUCCESS;
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * return the portion of the data that is usable. The reason why it takes
   * in a uint8_t pointer is because I just want to make this general. If a layer
   * need to ask lower layer to getUsablePortion, passing msg-pointer will be clumsy
   * by doing this, we just add on to it
   * @author: terence
   * @param: 
   * @return: 
   */
  command uint8_t* VCSend.getUsablePortion[uint8_t msgId](uint8_t *data) {
    // assume this is the first level above GenericComm
    return &data[sizeof(struct VirtualCommHeader)];
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * we just put the incoming pointer in our fifqueue and make an attempt to send
   * The interface is like this just to make it look like GenericComm
   * @author: terence
   * @param: msgId, the real message type
   * @param: length, the data length of the message
   * @param: msg, the msg pointer to be sent
   * @return: fail, if FIFOQueue is full, or own virtual comm is busy
   */

  // basically mark everyting, put it in the queue
  command result_t VCSend.send[uint8_t msgId](uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    struct VirtualCommHeader *header = (struct VirtualCommHeader *) msg->data; 
    uint8_t oldState = interruptOff();

    // if length is too big, stop it, this is some SERIOUS bug!
    if (length + sizeof(VirtualCommHeader) > TOSH_DATA_LENGTH) 
      { interruptOn(oldState); TOSH_SET_PW2_PIN(); FATAL("Size Too Big!"); return FAIL; }
    
    // if Virtual comm can not handle more message, fail
    if (isBusy(msgId)) { interruptOn(oldState); FATAL("VirtualComm, VirtualComm Busy"); return FAIL; }
    // mark busy bit map
    call BitArray.saveBitInArray(msgId, 1, busyBitMap);
    // put in all the stuff to the message
    msg->addr = address;
    msg->length = sizeof(struct VirtualCommHeader) + length;
    msg->type = msgId;
    header->source = TOS_LOCAL_ADDRESS;
    // then put it in our queue
    call FifoQueue.enqueue(pendingQueue, msg);
    interruptOn(oldState);
    // attemp to sent the message
    sendPacket();
    return SUCCESS;

  }
  /*////////////////////////////////////////////////////////*/
  /**
   * @author: terence 
   * @param: data is the payload assuming that the first byte is our header
   * @param: source extract from the payload
   * @param: seqnum is the linkseqnum extracted from the payload
   * @return: void
   */
  command void VCExtractHeader.extractHeader(uint8_t *data, uint16_t *source, int8_t *seqnum) {
    struct VirtualCommHeader *vch = (struct VirtualCommHeader *) data;
    *source = vch->source;
    *seqnum = vch->seqnum;
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * This extract the data out
   * @author: terence
   * @param: TOSMsg_Ptr mgs
   * @return: uint8_t pointer
   */
  command uint8_t* VCExtractHeader.extractData(TOS_MsgPtr msg) {
    return &msg->data[sizeof(struct VirtualCommHeader)];
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * Send done come back from GenericComm Signal Up!
   * @author: terence
   * @param: msg, the sent msg pointer
   * @param: success, the result of the sent
   * @return: always SUCCESS
   */
  // remove the item in the queue if necessary
  event result_t CommSendMsg.sendDone[uint8_t typeid](TOS_MsgPtr msg, result_t success) {
    uint8_t retransmit = 0, empty, wrongPacket, fail;
    uint8_t oldState;
    if (success == SUCCESS && msg->addr != TOS_UART_ADDR) {
      // increment seqnum only if send success and not to uart
      linkSeqnum++;
    }
    // turn off interrupt
    oldState = interruptOff();

    empty = call FifoQueue.isEmpty(pendingQueue);
    // need to check empty before we get first since sig fault may happen
    if (empty == 1) { interruptOn(oldState); return SUCCESS; }
    wrongPacket = call FifoQueue.getFirst(pendingQueue) != msg;
    if (wrongPacket == 1) { interruptOn(oldState); return SUCCESS; }

#if PLATFORM_PC
    if (msg->addr == TOS_UART_ADDR) { success = TRUE; msg->ack = TRUE; }
#endif
    fail = (success == FAIL || msg->ack == FALSE);
    // we consider fail, when it is fail and there is no ack
    if (fail == 1) {
      // ask application if it wants to retransmit
      retransmit = signal VCSend.sendDoneFailException[typeid](msg);
      // it you don't want to retransmit or it is success, i am not going to dequeue it
    } 

    // if fail & retranmsit = 0, delived = 0
    // if success , devlived = 1

    // if not, we are going to reset busymap
    if (retransmit == 0) {
      // then uncheck the busybitmap
      call BitArray.saveBitInArray(typeid, 0, busyBitMap);
      // dequeue message if success
      call FifoQueue.dequeue(pendingQueue);

      setSending(0);
      interruptOn(oldState);
      // if fail == 1 and retransmit == 0, it means, give up, so delivered should be 0
      // if fail == 0 and retransmit == 1, it means, delivered, so delivered should be set to 1
      signal VCSend.moveOnNextPacket[typeid](msg, (fail == 0));
      // send another packet immediatly, don't want queue to pile up!
      sendPacket();
    }
    if (retransmit == 1) {
      // wait a while
      startTimer(); 
      setSending(0);
      interruptOn(oldState);
    }

    // debugging
    if (msg->addr == TOS_UART_ADDR) {
      printPacket(msg);
    }
    return SUCCESS;
  }
  default event void VCSend.moveOnNextPacket[uint8_t msgId](TOS_MsgPtr msg, uint8_t delivered) {
    // don't do anything
  }
  default event result_t VCSend.sendDoneFailException[uint8_t msgId](TOS_MsgPtr msg) {
    // default is retransmit!
    return 1;
  }

}
