/**
 * Copyright (c) 2003 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */



/* 
 * Authors: Hongwei Zhang, Anish Arora
 */


includes AM; 

includes ReliableCommMsg; 

module ReliableCommM {
  provides {
    interface StdControl;
    interface ReliableSendMsg[uint8_t id];
    interface ReliableReceiveMsg[uint8_t id];
  }

  uses {
    interface BareSendMsg; 
    interface ReceiveMsg; 
    interface StdControl as RadioControl; 

    interface StdControl as TimerControl;
    interface Timer;

    interface Random;

    interface CC1000Control;

    interface Leds; 
  }
}

implementation {

  struct _msgq_entry {
    uint16_t address;
    uint8_t length;
    uint8_t id;
    uint8_t xmit_count;
    TOS_Msg message;

    uint16_t   myAddr;
    uint8_t     myQueuePos; 
    uint16_t   fromAddr; 
    uint8_t     fromQueuePos;
    uint8_t    seq; 
  } msgqueue[SEND_QUEUE_SIZE];

  uint8_t inQueue[MAX_NUM_IMPORTS][1+SEND_QUEUE_SIZE/8];   //bit map 
  uint8_t aggregatedACK[4]; //32 bits of ack bit array

  uint16_t importNgh[MAX_NUM_IMPORTS]; 
  uint8_t numImNghs; 
  //uint8_t importMap[1+MAX_NUM_NODES/8]; 

  uint8_t enqueue_next, dequeue_next;
  bool pending, isWaiting, alreadyDelayed; 
  //bool retransmit; 
  uint16_t retransmitTimer, CurrentRetransmitTimerThreshold; 

  TOS_Msg tpMsg;
  uint16_t   ackMyAddr;
  uint8_t    ackMyQueuePos; 
  uint16_t   ackFromAddr; 
  uint8_t    ackFromQueuePos;

  //for parameter tuning
  uint8_t deFactoTransmissionPower; 
  uint8_t deFactoMaxRetrasmitCount; 
  uint16_t deFactoBaseRetransmitWaiting;
  uint16_t deFactoRandomWaitingRange;
  uint16_t deFactoAdditiveFlowControlWaiting;

  //for self-stabilization
  uint16_t baseAckDeadCount; 
  uint16_t pendingDeadPeriod; 
  uint16_t queueDeadPeriod; 
  //uint16_t nonBaseReliableCommDeadTime; 
  //uint8_t prevDequeuNext;

  //for debug
  uint8_t queueLen, maxRetransmitFailCount, queueOverflowCount, totalSends, otherMaxRetranxitFail; 

  command result_t StdControl.init() {
    int i, j;

    deFactoTransmissionPower = DefaultTransmissionPower;
    deFactoMaxRetrasmitCount = MAX_RETRANSMIT_COUNT;
    deFactoBaseRetransmitWaiting = BaseRetransmit_Timer;
    deFactoRandomWaitingRange = RandomTimerRange;
    deFactoAdditiveFlowControlWaiting = AdditiveFlowControlTimer;

    for (i = 0; i < SEND_QUEUE_SIZE; i++) {
      msgqueue[i].length = 0;
    }

    for (i =0; i < MAX_NUM_IMPORTS; i++)
      for (j=0; j < 1+SEND_QUEUE_SIZE/8; j++)
	//inQueue[i][j] = 0;
	inQueue[i][j] = -1;

    /*
    for (i=0; i < 1+MAX_NUM_NODES/8; i++)
      importMap[i] = 0;
   */

    numImNghs = 0; 

    /*
    if (TOS_LOCAL_ADDRESS == BASE_STATION_ID || deFactoMaxRetrasmitCount < 2)
      retransmit = FALSE;
    else
      retransmit = TRUE;
    */

    pending = FALSE;
    pendingDeadPeriod = 0; 

    isWaiting = FALSE; 
    alreadyDelayed = FALSE;
    enqueue_next = 0;
    dequeue_next = 0;
    queueDeadPeriod = 0;

    baseAckDeadCount = 0;
    //nonBaseReliableCommDeadTime = 0;
    //prevDequeuNext = 0;

    maxRetransmitFailCount = 0; 
    queueOverflowCount = 0; 
    totalSends = 0; 
    otherMaxRetranxitFail = 0;

    return rcombine4(call RadioControl.init(), call TimerControl.init(), call Random.init(), call Leds.init()); 
  }

  command result_t StdControl.start() {
    //call Leds.yellowToggle(); 
    CurrentRetransmitTimerThreshold = deFactoBaseRetransmitWaiting + ((call Random.rand())%deFactoRandomWaitingRange); 
    call CC1000Control.SetRFPower(deFactoTransmissionPower);
    return rcombine3(call RadioControl.start(), call TimerControl.start(), call Timer.start(TIMER_REPEAT, Timer_Interval)); 
  }
  command result_t StdControl.stop() {
    return rcombine(call RadioControl.stop(), call TimerControl.stop()); 
  }

  default event result_t ReliableSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }

  default event TOS_MsgPtr ReliableReceiveMsg.receive[uint8_t id](TOS_MsgPtr m, uint16_t fromAddr, uint8_t   fromQueuePos) {
    return NULL;
  }

/* The queue is a Circular Buffer:
     enqueue_next indexes first empty entry
     buffer full if incrementing enqueue_next would wrap to dequeue
                 empty if dequeue_next == enqueue_next or msgqueue[dequeue_next].length == 0
*/

  command result_t ReliableSendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg, uint16_t fromAddr, uint8_t   fromQueuePos) {

    uint8_t j;
    uint8_t impNum;
    uint8_t  pos1, pos2, bitTest;
    uint8_t aggAckP1, aggAckP2; 
    //uint8_t preEnqueue;

    uint8_t longestQueueLenSoFar;

    dbg(DBG_USR1, "ReliableSend: queue msg enq %d deq %d\n", enqueue_next, dequeue_next);

   /* Fail if queue is full */
    if (msgqueue[((enqueue_next + 1) % SEND_QUEUE_SIZE)].length != 0) { 
       msg->data[length+FromAddrPos] = fromAddr >> 8;
       msg->data[length+FromAddrPos+1] = fromAddr & 0x00ff; 

       signal ReliableSendMsg.sendDone[id](msg, FAIL);
        return FAIL;
    }

    //put in queue to be sent out
    msgqueue[enqueue_next].address = address; 
    msgqueue[enqueue_next].length = length+RELIABLE_COMM_LENGTH; 
    msgqueue[enqueue_next].id = id; 
    
    //copy message
    msgqueue[enqueue_next].message.addr = address; 
    msgqueue[enqueue_next].message.type = id; 
    msgqueue[enqueue_next].message.group = TOS_AM_GROUP;
    msgqueue[enqueue_next].message.length = length+RELIABLE_COMM_LENGTH; 
    for (j=0; j < length; j++) 
      msgqueue[enqueue_next].message.data[j] = msg->data[j];
    msgqueue[enqueue_next].message.crc = msg->crc;
    msgqueue[enqueue_next].message.strength = msg->strength;
    msgqueue[enqueue_next].message.ack = msg->ack;
    msgqueue[enqueue_next].message.time = msg->time;
    //end of copy message

    msgqueue[enqueue_next].xmit_count = 0;
    msgqueue[enqueue_next].message.ack = 0;

    msgqueue[enqueue_next].myAddr = TOS_LOCAL_ADDRESS;
    msgqueue[enqueue_next].myQueuePos = enqueue_next; 
    msgqueue[enqueue_next].fromAddr = fromAddr; 
    if (fromAddr == TOS_LOCAL_ADDRESS) 
      msgqueue[enqueue_next].fromQueuePos = enqueue_next; 
    else {
      msgqueue[enqueue_next].fromQueuePos = fromQueuePos; 
      aggAckP1 = msg->data[length+randomSeq]/8;     // for aggregated ACK
      aggAckP2 = msg->data[length+randomSeq]%8; 
      bitTest = 0x1 << aggAckP2;
      aggregatedACK[aggAckP1] |= bitTest; 
    }
    msgqueue[enqueue_next].seq = (uint8_t) ((call Random.rand()) & 0x1f); 

    msgqueue[enqueue_next].message.type = id;
    msgqueue[enqueue_next].message.data[length+MyAddrPos] = TOS_LOCAL_ADDRESS >> 8; 
    msgqueue[enqueue_next].message.data[length+MyAddrPos+1] = TOS_LOCAL_ADDRESS & 0x00ff;
    msgqueue[enqueue_next].message.data[length+MyQueuePos] = enqueue_next;
    msgqueue[enqueue_next].message.data[length+FromAddrPos] = fromAddr >> 8;
    msgqueue[enqueue_next].message.data[length+FromAddrPos+1] = fromAddr & 0x00ff;
    msgqueue[enqueue_next].message.data[length+FromQueuePos] = msgqueue[enqueue_next].fromQueuePos; 
    msgqueue[enqueue_next].message.data[length+randomSeq] = msgqueue[enqueue_next].seq; 

    enqueue_next++; enqueue_next %= SEND_QUEUE_SIZE;

    dbg(DBG_USR1, "ReliableSend: Successfully queued msg to 0x%x, enq %d, deq %d\n", address, enqueue_next, dequeue_next);
    {
      uint16_t i;
      for (i = dequeue_next; i != enqueue_next; i = (i + 1) % SEND_QUEUE_SIZE)
	dbg(DBG_USR1, "qent %d: addr 0x%x, len %d, amid %d, xmit_cnt %d\n", i, msgqueue[i].address, msgqueue[i].length, msgqueue[i].id, msgqueue[i].xmit_count);
    }

    // Try to send next message (ignore xmit_count)
    if (msgqueue[dequeue_next].length != 0 && !isWaiting && !pending ) {
          dbg(DBG_USR1, "ReliableSend: sending msg (0x%x)\n", dequeue_next);
          pending = TRUE;
          msgqueue[dequeue_next].xmit_count += 1;

          msgqueue[dequeue_next].message.data[length+randomSeqAck] = aggregatedACK[0];   //for aggregated ACK
          msgqueue[dequeue_next].message.data[length+randomSeqAck+1] = aggregatedACK[1]; 
          msgqueue[dequeue_next].message.data[length+randomSeqAck+2] = aggregatedACK[2]; 
          msgqueue[dequeue_next].message.data[length+randomSeqAck+3] = aggregatedACK[3]; 

          if (!(call BareSendMsg.send(&(msgqueue[dequeue_next].message)))) {
	    /* call Timer.start(TIMER_REPEAT, Timer_Interval); */
	    retransmitTimer = 0;
	    isWaiting = TRUE;
	    dbg(DBG_USR1, "ReliableSend: send request failed. stuck in queue\n");
	    pending = FALSE;
	    pendingDeadPeriod = 0;
	    //call Leds.redToggle();
          }

    }

    return SUCCESS;

  }

   event result_t BareSendMsg.sendDone(TOS_MsgPtr msg, result_t success) 
  {
    uint8_t length;
    uint16_t   frAddr; 
    uint8_t    frQueuePos;   
    uint8_t pos1, pos2, bitTest, impNum;

    //the packet does not belong to ReliableComm
    if (msg->type < HANDLER_ID_LOWER_BOUND || msg->type > HANDLER_ID_UPPER_BOUND)
      return SUCCESS;

    pending = FALSE; 
    pendingDeadPeriod = 0; 
    //call Leds.greenToggle();

    length = msg->length-RELIABLE_COMM_LENGTH;
    if (TOS_LOCAL_ADDRESS == BASE_STATION_ID) {   //no need for reliableComm
      dbg(DBG_USR1, "!!!sendDone:no retransmitting \n");
      isWaiting = FALSE; 

      if (msg->addr == BASE_ACK_DEST_ID) {  //is for base-ack-msg 
        frAddr = (uint16_t)msg->data[length+FromAddrPos];
        frAddr = frAddr << 8; 
        frAddr = frAddr | ((uint16_t)msg->data[length+FromAddrPos+1]); 
        frQueuePos = msg->data[length+FromQueuePos];
        signal ReliableReceiveMsg.receive[msg->type](&tpMsg, frAddr, frQueuePos); 
        //call Leds.greenToggle();
        return SUCCESS;
      }

      if (msg->addr != BASE_ACK_DEST_ID) {
	//msg->length -= RELIABLE_COMM_LENGTH;
                signal ReliableSendMsg.sendDone[msg->type](msg, success);
      }

      msgqueue[dequeue_next].length = 0;

      dequeue_next++; dequeue_next %= SEND_QUEUE_SIZE; 
      queueDeadPeriod = 0;

      if (msgqueue[dequeue_next].length != 0) {
      //if ((msgqueue[dequeue_next].length != 0 || dequeue_next != enqueue_next)) { 
         pending = TRUE;
         if (!(call BareSendMsg.send(&(msgqueue[dequeue_next].message)))) {
             dbg(DBG_USR1, "ReliableSend: send request failed. stuck in queue\n"); 
             pending = FALSE; 
             pendingDeadPeriod = 0;
          }
      }
      return SUCCESS; 
    }     //end of "no need for reliableComm 

    /* for non-base-station and retransmit */
    if (TOS_LOCAL_ADDRESS != BASE_STATION_ID && msg->addr != BASE_ACK_DEST_ID) { //retransmit 
       dbg(DBG_USR1, "!!!sendDone:beginging\n");
       isWaiting = TRUE;
       retransmitTimer = 0;
    }

    return SUCCESS; 
 }


   event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr packet)
  {
    uint8_t length;
    uint16_t   frAddr; 
    uint8_t    frQueuePos;    
    uint8_t j;
    uint8_t pos1, pos2, bitTest, impNum;
    uint8_t aggAckP1, aggAckP2; 
    bool ackOnly; 
    ReliableComm_Tuning_Msg * tuningMsgPtr;

    //tuning parameters
    if (packet->crc  && 
         packet->type == ReliableComm_Tuning_Handler && 
         packet->addr == ReliableComm_Tuning_Addr) {

      tuningMsgPtr = (ReliableComm_Tuning_Msg *)(packet->data); 
      if (tuningMsgPtr->transmissionPower > 0 &&
           tuningMsgPtr->transmissionPower < 255 &&
           tuningMsgPtr->maxRetrasmitCount >= 0 &&
           tuningMsgPtr->baseRetransmitWaiting >= 0 &&
           tuningMsgPtr->randomWaitingRange > 0 &&
           tuningMsgPtr->additiveFlowControlWaiting >= 0) {
	call Leds.yellowToggle();
	call Leds.greenToggle();
	call Leds.redToggle();

	call CC1000Control.SetRFPower(tuningMsgPtr->transmissionPower); 
	deFactoMaxRetrasmitCount = tuningMsgPtr->maxRetrasmitCount;
	deFactoBaseRetransmitWaiting = tuningMsgPtr->baseRetransmitWaiting;
	deFactoRandomWaitingRange =  tuningMsgPtr->randomWaitingRange;
	deFactoAdditiveFlowControlWaiting = tuningMsgPtr->additiveFlowControlWaiting;
      }
      else {
	call Leds.redToggle();
	call Leds.greenToggle();
	call Leds.yellowToggle();
      }

      return packet;
    } //end of parameter-tuning

    frAddr = frQueuePos = 0;
    length = packet->length - RELIABLE_COMM_LENGTH; 

    if (//packet->crc == 1 && //uncomment this line to check CRC
         packet->group == TOS_AM_GROUP &&
         packet->type >= HANDLER_ID_LOWER_BOUND && 
         packet->type <= HANDLER_ID_UPPER_BOUND) {

      if (packet->addr == TOS_LOCAL_ADDRESS) {     //receive a new message 
	TOS_MsgPtr tmp;
         
	frAddr = (uint16_t)packet->data[length+MyAddrPos];
	frAddr = frAddr << 8;
	frAddr = frAddr | ((uint16_t)packet->data[length+MyAddrPos+1]);
	frQueuePos = (uint8_t)packet->data[length+MyQueuePos];

	/* remove unnecessary retransmission from sender */
	for (impNum=0; importNgh[impNum] != frAddr && impNum < numImNghs; impNum++)
	  ;
	if (impNum >= numImNghs) {
	  if (numImNghs < MAX_NUM_IMPORTS) {
	    importNgh[numImNghs++] = frAddr;
	    dbg(DBG_USR1, "get a new import neighbor %d; the number of import neighbors is %d\n", importNgh[numImNghs-1], numImNghs);
	  }
	  else {
	    dbg(DBG_USR1, "exceed the limit of max. number of import neighbors\n");
	    return FAIL;
	  }
	}
	else {
	 // dbg(DBG_USR1, "is existing import neighbor %d; the number of import neighbors is %d \n", fromAddr, numImNghs);
	  //call Leds.greenToggle();
	}

	dbg(DBG_USR1, "impNum =%d \n", impNum);

	//if (inQueue[impNum][0] ==  frQueuePos && TOS_LOCAL_ADDRESS != BASE_STATION_ID) { //for DEMO only
	if (inQueue[impNum][0] ==  frQueuePos) {  //is retransmission for a message that has already been received 
	  //call Leds.redToggle();
	  ackOnly = TRUE;
	}
	else {
	  ackOnly = FALSE;
	  inQueue[impNum][0] = frQueuePos; 
	}

         //if (TOS_LOCAL_ADDRESS == BASE_STATION_ID && ackOnly == FALSE){ //for DEMO only
         if (TOS_LOCAL_ADDRESS == BASE_STATION_ID || ackOnly == TRUE) {  //base station acknowledge:BEST EFFORT
           if (!pending && ((ackOnly == FALSE && deFactoMaxRetrasmitCount > 1) || (ackOnly == TRUE && deFactoMaxRetrasmitCount > 2))) {
             //call Leds.greenToggle();
             baseAckDeadCount = 0;
             pending = TRUE;
         
             //copy message
             tpMsg.addr = packet->addr; //packet->addr;
             tpMsg.type = packet->type;
             tpMsg.group = packet->group;
             tpMsg.length = packet->length;
             for (j=0; j < length+RELIABLE_COMM_LENGTH; j++)
               tpMsg.data[j] = packet->data[j];
             tpMsg.crc = packet->crc;
             tpMsg.strength = packet->strength;
             tpMsg.ack = packet->ack;
             tpMsg.time = packet->time;
             //end of copy message

             //prepare base-ack message
             packet->addr = BASE_ACK_DEST_ID;
             packet->data[length+MyAddrPos] = TOS_LOCAL_ADDRESS >> 8; 
             packet->data[length+MyAddrPos+1] = TOS_LOCAL_ADDRESS & 0x00ff;
             packet->data[length+MyQueuePos] = 0; //unimportant
             packet->data[length+FromAddrPos] = frAddr >> 8;
             packet->data[length+FromAddrPos+1] = frAddr & 0x00ff;
             packet->data[length+FromQueuePos] = frQueuePos;

             packet->data[length+randomSeq] = 0xff;    //for aggregated ACK 

             if (!(call BareSendMsg.send(packet))) {
	       dbg(DBG_USR1, "ReliableSend: send request failed. stuck in queue\n");
	       pending = FALSE;
	       pendingDeadPeriod = 0;
	       //call Leds.redToggle();
             }
           }
           else {
	     //baseAck(packet, frAddr, frQueuePos);   
	     if (deFactoMaxRetrasmitCount > 1) {
	       baseAckDeadCount++;
	       if (baseAckDeadCount >= MAX_BASE_ACK_DEAD_COUNT) {
		 pending = FALSE;
		 pendingDeadPeriod = 0;
	       }
	     }
	     //packet->length = length;
	     if (ackOnly == FALSE) 
	       signal ReliableReceiveMsg.receive[packet->type](packet, frAddr, frQueuePos);
	     //call Leds.redToggle();
           }
         }
         else { //that is, TOS_LOCAL_ADDRESS != BASE_STATION_ID 
           //call Leds.redToggle();  
           //packet->length = length;
           signal ReliableReceiveMsg.receive[packet->type](packet, frAddr, frQueuePos); 
        }
      }
      else if (TOS_LOCAL_ADDRESS != BASE_STATION_ID){         //snooping for implicit acknowledgement
         //call Leds.redToggle();
         frAddr = (uint16_t)packet->data[length+FromAddrPos];
         frAddr = frAddr << 8; 
         frAddr = frAddr | ((uint16_t)packet->data[length+FromAddrPos+1]); 
         frQueuePos = (uint8_t)packet->data[length+FromQueuePos]; 

         if (packet->type ==  msgqueue[dequeue_next].id && frAddr == TOS_LOCAL_ADDRESS && frQueuePos == dequeue_next) {
           //call Leds.yellowToggle();

           /* call Timer.stop(); */
           isWaiting = FALSE;
           retransmitTimer = 0;
           //msgqueue[dequeue_next].message.length -= RELIABLE_COMM_LENGTH;
           signal ReliableSendMsg.sendDone[packet->type](&(msgqueue[dequeue_next].message), SUCCESS); 
           msgqueue[dequeue_next].length = 0;

           /*clear bit
           pos1 = msgqueue[dequeue_next].fromQueuePos/8;  //for retransmission containment
           pos2 = msgqueue[dequeue_next].fromQueuePos%8; 
           bitTest = 0xff ^ (0x1 << pos2); 
           for (impNum=0; importNgh[impNum] != msgqueue[dequeue_next].fromAddr && impNum < numImNghs; impNum++) 
                 ;
           inQueue[impNum][pos1] &= bitTest; 
          */

            aggAckP1 = msgqueue[dequeue_next].seq/8;     // CLEAR bit for aggregated ACK 
            aggAckP2 = msgqueue[dequeue_next].seq%8; 
            bitTest = 0xff ^ (0x1 << aggAckP2); 
            aggregatedACK[aggAckP1] &= bitTest;
            alreadyDelayed = FALSE;

            dequeue_next++; dequeue_next %= SEND_QUEUE_SIZE;
            queueDeadPeriod = 0;

           if (msgqueue[dequeue_next].length != 0 && !pending ) {
           //if ((msgqueue[dequeue_next].length != 0 || dequeue_next != enqueue_next) && !pending ) {    // Try to send next message (ignore xmit_count) 
             //call Leds.grenToggle();
             dbg(DBG_USR1, "ReliableSend: sending msg (0x%x)\n", dequeue_next);
             pending = TRUE;
             msgqueue[dequeue_next].xmit_count += 1; 

             msgqueue[dequeue_next].message.data[length+randomSeqAck] = aggregatedACK[0];   //for aggregated ACK 
             msgqueue[dequeue_next].message.data[length+randomSeqAck+1] = aggregatedACK[1]; 
             msgqueue[dequeue_next].message.data[length+randomSeqAck+2] = aggregatedACK[2]; 
             msgqueue[dequeue_next].message.data[length+randomSeqAck+3] = aggregatedACK[3]; 

             if (!(call BareSendMsg.send(&(msgqueue[dequeue_next].message)))) {
                        /* call Timer.start(TIMER_REPEAT, Timer_Interval); */ 
                        retransmitTimer = 0; 
                        isWaiting = TRUE;    
	        dbg(DBG_USR1, "ReliableSend: send request failed. stuck in queue\n"); 
                        pending = FALSE; 
   	        pendingDeadPeriod = 0;
             }
           }
           else if (msgqueue[dequeue_next].length != 0 )  //flow control
               isWaiting = TRUE;
         } //end of perfect ack 
         else {  //check if in aggregated ack 
            aggAckP1 = msgqueue[dequeue_next].seq/8;     // for aggregated ACK 
            aggAckP2 = msgqueue[dequeue_next].seq%8; 
            bitTest = 0x1 << aggAckP2;
            if (packet->data[length+randomSeq] != 0xff && (packet->data[length+randomSeqAck+aggAckP1] & bitTest) != 0 && alreadyDelayed == FALSE) { //delay at most once for the purpose of flow control 
               //call Leds.redToggle();
               retransmitTimer -= flowControlDelay; 
               msgqueue[dequeue_next].xmit_count += flowControlXmitReduction; 
               alreadyDelayed = TRUE; 
            }
         } //end of aggregated ack
      } //end of snooping for implicit ack
    }
    return packet;
  } //end of receive() 


  event result_t Timer.fired() 
  {
    uint8_t length;
    uint8_t pos1, pos2, bitTest, impNum;
    uint8_t aggAckP1, aggAckP2;

     /* Add self-stabilization from got-stuck: for "pending"-variable and "queuing" 
      * 
      * Monitoring the current dequeue_next position, if found not moving forward 
      * for a long time, regards it as "got-stuck" and resets corresponding control  
      * variables. 
      */  
    //1) stabilize "pending"
    if (pending)
      pendingDeadPeriod += Timer_Interval;
    if (pendingDeadPeriod >= NonBaseReliableCommDeadThreshold) {
      //call Leds.redToggle();
      pending = FALSE;
      pendingDeadPeriod = 0; 
    }

    //2) stabilize "queuing"
    //if (msgqueue[dequeue_next].length != 0 || dequeue_next != enqueue_next)
    if (msgqueue[dequeue_next].length != 0) 
      queueDeadPeriod += Timer_Interval;
    else if (enqueue_next != dequeue_next) {
      //call Leds.redToggle(); 
      enqueue_next = dequeue_next;
    }

    if (queueDeadPeriod >= NonBaseReliableCommDeadThreshold) {
      //call Leds.redToggle();
      //call Leds.greenToggle();
      isWaiting = TRUE;
      retransmitTimer = CurrentRetransmitTimerThreshold;
      msgqueue[dequeue_next].xmit_count = deFactoMaxRetrasmitCount+1;
      queueDeadPeriod = 0;
    }
    //end of self-stabilization
    
      if (TOS_LOCAL_ADDRESS == BASE_STATION_ID || !isWaiting) 
         return SUCCESS; 

      retransmitTimer += Timer_Interval;
      //call Leds.yellowToggle();

      if (retransmitTimer >= CurrentRetransmitTimerThreshold) {
        CurrentRetransmitTimerThreshold = deFactoBaseRetransmitWaiting + ((call Random.rand())%deFactoRandomWaitingRange); 

        //call Leds.redToggle();
        /* call Timer.stop();  */
        isWaiting = FALSE; 
        retransmitTimer = 0; 
        if (msgqueue[dequeue_next].xmit_count >= deFactoMaxRetrasmitCount) {
           dbg(DBG_USR1, "# of retransmission exceeds upper limit\n");
           signal ReliableSendMsg.sendDone[msgqueue[dequeue_next].id](&(msgqueue[dequeue_next].message), FAIL);
           msgqueue[dequeue_next].length = 0;
            aggAckP1 = msgqueue[dequeue_next].seq/8;     // CLEAR bit for aggregated ACK 
            aggAckP2 = msgqueue[dequeue_next].seq%8; 
            bitTest = 0xff ^ (0x1 << aggAckP2); 
            aggregatedACK[aggAckP1] &= bitTest; 
            alreadyDelayed = FALSE; 

            dequeue_next++; dequeue_next %= SEND_QUEUE_SIZE; 
            queueDeadPeriod = 0;
        }
        else
          dbg(DBG_USR1, "%d-th retransmit at position %d \n", msgqueue[dequeue_next].xmit_count, dequeue_next);

        length = msgqueue[dequeue_next].message.length-RELIABLE_COMM_LENGTH;
        if (msgqueue[dequeue_next].length != 0 && !pending ) {
          dbg(DBG_USR1, "ReliableSend: sending msg (0x%x)\n", dequeue_next); 
          pending = TRUE;

          msgqueue[dequeue_next].xmit_count += 1;
          if (msgqueue[dequeue_next].xmit_count > 2)
	    CurrentRetransmitTimerThreshold = deFactoBaseRetransmitWaiting + ((call Random.rand())%deFactoRandomWaitingRange) + (msgqueue[dequeue_next].xmit_count-2)*deFactoAdditiveFlowControlWaiting; 

          msgqueue[dequeue_next].message.data[length+randomSeqAck] = aggregatedACK[0];   //for aggregated ACK
          msgqueue[dequeue_next].message.data[length+randomSeqAck+1] = aggregatedACK[1]; 
          msgqueue[dequeue_next].message.data[length+randomSeqAck+2] = aggregatedACK[2]; 
          msgqueue[dequeue_next].message.data[length+randomSeqAck+3] = aggregatedACK[3]; 

          //call Leds.yellowToggle();

          if (TOS_LOCAL_ADDRESS == BASE_STATION_ID) { 
            if (!(call BareSendMsg.send(&(msgqueue[dequeue_next].message)))) {
              dbg(DBG_USR1, "ReliableSend: send request failed. stuck in queue\n"); 
              pending = FALSE; 
              pendingDeadPeriod = 0;
            }
          }
          else if (!(call BareSendMsg.send(&(msgqueue[dequeue_next].message)))) {
                /*call Timer.start(TIMER_REPEAT, Timer_Interval); */
	    retransmitTimer = 0;
	    isWaiting = TRUE;
	    dbg(DBG_USR1, "ReliableSend: send request failed. stuck in queue\n");
	    pending = FALSE;
	    pendingDeadPeriod = 0;
	    //call Leds.yellowToggle();
	    //call Leds.redToggle();
	  }
       }
       else if (msgqueue[dequeue_next].length != 0)
	  isWaiting = TRUE;
      }
     return SUCCESS;
  }  //end of Timer.fired()

}
