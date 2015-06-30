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
 * 
 * This MODULE implements protocol RBC (for Reliable Bursty Convergecast). 
 * 
 */

includes AM; 

#ifndef TOSSIM_SYSTIME
//includes Time;
includes OTime;
#endif

includes ReliableComm; 

module ReliableCommM {
  provides {
    interface StdControl;
    interface ReliableSendMsg[uint8_t id];
    interface ReliableReceiveMsg[uint8_t id];
    interface ReliableCommControl;
#ifdef LOG_STATE
    event result_t matchboxReady();
#endif
  }

  uses {
    interface StdControl as RadioControl;
    interface StdControl as UARTControl;
    interface StdControl as TimerControl;
#ifndef TOSSIM_SYSTIME
    interface CC1000Control;
    interface StdControl as TsyncControl; 
    interface OTime as Time;
#else 
    interface SysTime;
#endif
#ifdef USE_MacControl
    interface MacControl;
    interface MacBackoff;
#endif
    interface BareSendMsg as RadioBareSend;
    interface ReceiveMsg; 

    //interface BareSendMsg as UARTBareSend;
    interface SendMsg as UARTSend;

    interface Timer;
    interface Leds; 

#ifdef LOG_STATE
    //interface DataLogger;
    interface StdControl as MatchboxControl;
    interface FileRead;
    interface FileWrite;
#endif
  }
}

implementation {

   /* Queue data structure
       1) circular buffers with differentiated priorities;
       2) buffer becomes full when VQ[deFactoMaxTransmitCount] = 0
   */
  struct _msgq_entry {
    TOS_Msg message;
    uint8_t seq; 
    uint8_t trxt;
#ifndef EXPLICIT_ACK
    uint32_t resend; //time for next retransmission
#endif

    uint8_t prev;
    uint8_t next;
  } Q[SEND_QUEUE_SIZE];
  bool pending; //for radio
  bool uartPending; //for UART
  uint8_t uartWritePtr, uartReadPtr;

  //#ifdef EXPLICIT_ACK
  uint8_t lastSendCvq, lastSendPtr;
  //#endif

  struct _virtualq_entry {
    uint8_t size;
    uint8_t head;
    uint8_t tail;
  } VQ[MAX_TRANSMIT_COUNT+1]; 
  uint8_t cvq;

  struct _errorcontrol_entry {
    uint16_t node_id;
    uint8_t lastSeq[SEND_QUEUE_SIZE]; //NULL8 is \perp
#ifndef EXPLICIT_ACK
    uint8_t ackLeft;
    uint8_t lastPos;
    uint8_t  expect0;
    uint8_t expect1;
#endif
  } children[MAX_NUM_CHILDREN]; 
  uint8_t numImNghs; 
#ifndef EXPLICIT_ACK
  uint8_t ackLeft;
#endif

  uint16_t lastDest;

#ifndef EXPLICIT_ACK
  bool acceptBaseAck;
#endif

  uint8_t pToSend, pToSendDev;
  uint32_t pMtte, pMtts;

  uint8_t parentSpace, lastParentSpace;
  uint16_t pCongestWait, parentSpaceDeadPeriod;

  bool toWD;
  uint16_t contentionWait;
  uint16_t highestRankedNode;
  /*
  struct _highest_ranked_node {
    uint16_t node_id;
    uint8_t emptyLen;
    uint8_t cvq;
    uint8_t size;
    uint16_t contentionWait;
  } highestRanked;
  struct _second_highest_ranked_node {
    uint16_t node_id;
    uint8_t emptyLen;
    uint8_t cvq;
    uint8_t size;
    uint16_t contMonitorW;
  } secondHighest;
  */

  bool toSnoop, isBase, isBaseChild; //default: FALSE

#ifndef EXPLICIT_ACK
  uint8_t nAck;
  uint32_t lastReceive;
  uint8_t sendAckPtr, storeAckPtr;
#endif

  uint32_t mtte, mtts, mtte0, mtts0, mtteDev, mttsDev;
  //  uint16_t retransmitTimer, CurrentRetransmitTimerThreshold; 

  //for parameter tuning
  uint8_t deFactoTransmissionPower; 
  uint8_t deFactoMaxTransmitCount; 
  uint16_t uartPendingDeadPeriod; 

  //for self-stabilization
  uint16_t baseAckDeadCount; 
  uint16_t pendingDeadPeriod; 

#ifdef CALCULATE_LOG
  //Note: to save space, use Q[0] and Q[1] as buffers to communicate to UART when need be
  //for state Logging
  uint8_t  log[LOG_RECORD_SIZE];
  //uint8_t  logCopy[LOG_RECORD_SIZE];
  ReliableComm_Reflector * logPtr;
  //bool stateLogged, isWritingLog;
  //uint32_t sinceLastLogging;
  //uint8_t  writingLogDeadCount;
#endif
#ifdef INTEGRITY_CHECKING
  uint32_t overFlows;
  uint32_t reTranxits;
#endif

  ///**********************************************************
  //* local function definitions
  //**********************************************************/

    /* Convert timeSync jiffies to units of milliseconds
     * 
     * currently, 1 jiffy = 250 milliseconds ~= pow(2, 8) milliseconds
     */
    uint32_t jiffiesToMilliseconds(timeSyncPtr t) {
      uint32_t ms;
      uint32_t highBits;

      //get the lower (32-8) bits
      ms = (t->ClockL) >> 8;
      //get the higher 8 bits
      highBits = (t->ClockH);
      highBits <<= (32-8);
      //combine into a 32-bit value
      ms |= highBits;

      return ms;
    } 

  /* allocate the tail of VQ[deFactoMaxTransmitCount], or a least ranked non-empty VQ (when no free queue position),
   * and append it to VQ[0]; copy the message. 
   */
  bool enqueue(uint16_t address, uint8_t length, TOS_MsgPtr msg, uint8_t id)
  {
    uint8_t k, j; 
    //uint8_t freeVQ;
    ReliableComm_ProtocolMsg * RBCPtr;

    /* to consider
    //try to find a free spot to hold the packet
    if (VQ[deFactoMaxTransmitCount].size > 0 && VQ[deFactoMaxTransmitCount].size <= SEND_QUEUE_SIZE) //exists free queue pos
      atomic freeVQ = deFactoMaxTransmitCount;
    else if (VQ[deFactoMaxTransmitCount].size == 0) {//no free queue pos; to preempt least ranked so far
#ifdef CALCULATE_LOG
      //Log: calculate queueOverflowCount 
      atomic {
	++(logPtr->queueOverflowCount);
	if ((uint8_t)msg->data[length] == 0xff && (uint8_t)msg->data[length+1] == 0xff) //packets are locally generated
	  logPtr->otherQueueOverflowCount++;
      }
#endif
#ifdef INTEGRITY_CHECKING
      overFlows++;
      dbg(DBG_SWITCH3, "%d queue overflows\n", overFlows);
#endif
      atomic freeVQ = deFactoMaxTransmitCount - 1;
      while (freeVQ > 0 && (VQ[freeVQ].size == 0 || (VQ[freeVQ].size == 1 && VQ[freeVQ].head == ackLeft)))
	atomic freeVQ--;
      if (freeVQ == 0) //no one to be preempted
	return FAIL;
      else if (VQ[freeVQ].tail == ackLeft) {//find one to preempt, but need to adjust due to ackLeft
	atomic {
	  k = Q[ackLeft].prev;
	  if (VQ[freeVQ].size == 2) {
	    VQ[freeVQ].head = ackLeft;
	    VQ[freeVQ].tail = k;
	    Q[ackLeft].prev = ackLeft;
	    Q[ackLeft].next = k;
	    Q[k].prev = ackLeft;
	    Q[k].next = k;
	  }
	  else {
	    VQ[freeVQ].tail = k;
	    Q[ackLeft].prev = Q[k].prev;
	    Q[ackLeft].next = k;
	    Q[k].prev = ackLeft;
	    Q[k].next = k;
	  }
	}//atomic
      }
    }
    else  //for stabilization
      return FAIL; 

    atomic {
      //update VQ[freeVQ]
      k = VQ[freeVQ].tail;
      (VQ[freeVQ].size)--;
      if (VQ[freeVQ].size == 0)
	VQ[freeVQ].head = VQ[freeVQ].tail = NULL8;
      else {
	VQ[freeVQ].tail = Q[k].prev;
	Q[Q[k].prev].next = Q[k].prev;
      }
    */

    atomic {
      //update VQ[deFactoMaxTransmitCount]
      k = VQ[deFactoMaxTransmitCount].tail;
      (VQ[deFactoMaxTransmitCount].size)--;
      if (VQ[deFactoMaxTransmitCount].size == 0)
	VQ[deFactoMaxTransmitCount].head = VQ[deFactoMaxTransmitCount].tail = NULL8;
      else {
	VQ[deFactoMaxTransmitCount].tail = Q[k].prev;
	Q[Q[k].prev].next = Q[k].prev;
      }

      //update VQ[0]
      cvq = 0;
      (VQ[0].size)++;
      if (VQ[0].size == 1)
	VQ[0].head = Q[k].prev = k;
      else {
	Q[VQ[0].tail].next = k;
	Q[k].prev = VQ[0].tail;
      }
      VQ[0].tail = Q[k].next = k;

      //update queue element 
      /* changed to be done in move(...) when freed
      Q[k].seq = (Q[k].seq+1)%NULL8;
      */
      
      Q[k].trxt = 1;
#ifndef EXPLICIT_ACK
      Q[k].resend = 0; 
#endif

      //copy msg
      Q[k].message.addr = address;
      Q[k].message.type = id;
      Q[k].message.length = length+sizeof(ReliableComm_ProtocolMsg);
      Q[k].message.group = TOS_AM_GROUP;
      for (j=0; j < length+sizeof(ReliableComm_ProtocolMsg) && j < TOSH_DATA_LENGTH; j++)
	Q[k].message.data[j] = msg->data[j];
      Q[k].message.crc = msg->crc;
      Q[k].message.strength = msg->strength;
      Q[k].message.ack = msg->ack;
      Q[k].message.time = msg->time;

      //add/update information related to ReliableComm control
      RBCPtr = (ReliableComm_ProtocolMsg *)(length + Q[k].message.data);
      RBCPtr->myAddr = TOS_LOCAL_ADDRESS;
      RBCPtr->myPos = k;
      RBCPtr->mySeq = Q[k].seq; 
    }//atomic
    return SUCCESS;
  } //end of enqueue(..., ...)

  /* decide whether it is time for a node to send out the packet 
   * at the head of its highest ranked virtual queue.
   */
  bool toSend()
  {
    bool ok;
    uint8_t k; 

#ifndef TOSSIM_SYSTIME
    timeSync_t currentTime;
#endif
    uint32_t clockReading;

    //if (pending || TOS_LOCAL_ADDRESS == BASE_STATION_ID || cvq == NULL8) {
    if (pending || isBase || cvq == NULL8) { //echelon
#ifdef INTEGRITY_CHECKING
      /*
      if (pending)
	dbg(DBG_SWITCH2, "unable to send: PENDING = TRUE\n");
      if (cvq == NULL8)
	dbg(DBG_SWITCH2, "unable to send: cvq == NULL8\n");
      */
#endif
      return FALSE;
    }
    if (cvq  >= deFactoMaxTransmitCount) { //stabilization
#ifdef INTEGRITY_CHECKING
      //dbg(DBG_SWITCH2, "unable to send: cvq >= deFactoMaxTransmitCount\n");
#endif
      atomic cvq = NULL8;
      return FALSE;
    }

#ifndef TOSSIM_SYSTIME
    call Time.getLocalTime(&currentTime);
    atomic clockReading = jiffiesToMilliseconds(&currentTime);
#else
    clockReading = (call SysTime.getTime32());
#endif
    atomic {
      k = VQ[cvq].head;
      ok =  ((pCongestWait <= clockReading && (parentSpace == NULL8 || parentSpace > 0))
                   && contentionWait <= clockReading
	 /*
                 && (highestRanked.contentionWait <= clockReading || 
                          (secondHighest.node_id == TOS_LOCAL_ADDRESS &&
                            secondHighest.contMonitorW != 0 && secondHighest.contMonitorW <= clockReading
                          )
                        ) 
 	*/ 
#ifndef EXPLICIT_ACK
                 && ((k != ackLeft && (Q[k].trxt == 1 || Q[k].resend <= clockReading)) ||
                           (k == ackLeft && (Q[Q[k].next].trxt == 1 || Q[Q[k].next].resend <= clockReading)) ||
	       (lastReceive != 0 && clockReading > lastReceive && (clockReading-lastReceive) >= (mtts*channelUtilizationGuard)))
#endif
             );
#ifdef INTEGRITY_CHECKING
      /*
      if (ok)
	dbg(DBG_SWITCH3, "TO SEND\n");
      else {
	if (pCongestWait > clockReading)
	  dbg(DBG_SWITCH3, "unable to send: pCongestWait > clockReading\n");
	if (parentSpace <= 0)
	  dbg(DBG_SWITCH2, "unable to send: parentSpace <= 0\n");
	if (contentionWait > clockReading)
	  dbg(DBG_SWITCH3, "unable to send: contentionWait > clockReading\n");
	if (k != ackLeft && Q[k].resend > clockReading)
	  dbg(DBG_SWITCH2, "unable to send: %d != ackLeft && Q[%d].resend > clockReading\n", k, k);
	if (k == ackLeft && Q[Q[k].next].resend > clockReading)
	  dbg(DBG_SWITCH2, "unable to send: %d == ackLeft && Q[Q[%d].next].resend > clockReading\n", k);
      }
      */
#endif
    }
    return ok;
  } //end of toSend(...)

   /* move elements in one virtual queue to another;
    * also update cvq and //signal sendDone if need be
    */
   void move(uint8_t q1, uint8_t k1, uint8_t k22, uint8_t to)
   {
     uint8_t k, k2, num;
#ifndef TOSSIM_SYSTIME
     timeSync_t currentTime;
#endif
     uint32_t clockReading;

     if (q1 >= deFactoMaxTransmitCount || k1 >= SEND_QUEUE_SIZE || k22 >= SEND_QUEUE_SIZE || to > deFactoMaxTransmitCount) //for stabilization
       return;

     atomic{
       k2 = k22;
       num = 1;
       k = k1;
       if (to == deFactoMaxTransmitCount) //when the queue position is freed
	 Q[k].seq = (Q[k].seq+1)%NULL8;
     }
     while (k != k2)
       if (Q[k].next != k && Q[k].next < SEND_QUEUE_SIZE) { //for stabilization
	 atomic{
	   k = Q[k].next;
	   if (to == deFactoMaxTransmitCount) //when the queue position is freed
	     Q[k].seq = (Q[k].seq+1)%NULL8;
	   num++;
	 }
       }
       else {//conservative stabilize this virtual queue
	 atomic{
	   VQ[q1].tail = Q[k].next = k;
	   num = 1;
	   while (k != Q[k].prev && Q[k].prev < SEND_QUEUE_SIZE) {
	     k = Q[k].prev;
	     num++;
	   }
	   VQ[q1].size = num;
	   VQ[q1].head = Q[k].prev = k;
	 }//atomic
	 return;
       }

     atomic{
       //update VQ[q1]
       VQ[q1].size -= num;
       if (VQ[q1].size == 0)
	 VQ[q1].head = VQ[q1].tail = NULL8;
       else {
	 if (Q[k1].prev == k1) {
	   VQ[q1].head = Q[k2].next;
	   Q[Q[k2].next].prev = Q[k2].next;
	 }
	 else if (Q[k2].next == k2) {
	   VQ[q1].tail = Q[k1].prev;
	   Q[Q[k1].prev].next = Q[k1].prev;
	 }
	 else {
	   Q[Q[k1].prev].next = Q[k2].next;
	   Q[Q[k2].next].prev = Q[k1].prev;
	 }
       }

       //update VQ[to]
       if (VQ[to].size == 0) {
	 VQ[to].head = k1;
	 VQ[to].tail = k2;
	 Q[k1].prev = k1;
	 Q[k2].next = k2;
       }
       else if (to != deFactoMaxTransmitCount) {
	 Q[VQ[to].tail].next = k1;
	 Q[k1].prev = VQ[to].tail;
	 VQ[to].tail = Q[k2].next = k2;
       }
       else { //to == deFactoMaxTransmitCount
	 Q[VQ[to].head].prev = k2;
	 Q[k2].next = VQ[to].head;
	 VQ[to].head = Q[k1].prev = k1;
       }
       VQ[to].size += num;

       //update cvq if need be
       if (cvq > to)
	 cvq = to;
       else if (VQ[cvq].size == 0 
#ifndef EXPLICIT_ACK
                      || (VQ[cvq].size == 1 && VQ[cvq].head == ackLeft)
#endif
                   ) {
	 while (cvq < deFactoMaxTransmitCount 
                                  && (VQ[cvq].size == 0 
#ifndef EXPLICIT_ACK
                                             || (VQ[cvq].size == 1 && VQ[cvq].head == ackLeft)
#endif
                                          )
                                )
	   cvq++;
	 if (cvq == deFactoMaxTransmitCount) {
	   cvq = NULL8;
	   parentSpaceDeadPeriod = 0;
	   mtte0 = mtts0 = 0;
	   /* Hongwei new
	   mtte = mtte - (mtte>>compPastW) + (MTTE>>compPastW);
	   mtts = mtts - (mtts>>compPastW) + (MTTS>>compPastW);
	   mtteDev = mtteDev - (mtteDev>>compPastW) + (MTTE_DEV>>compPastW);
	   mttsDev = mttsDev - (mttsDev>>compPastW) + (MTTS_DEV>>compPastW);
	   */
	 }
       }
     }//atomic

     /*
     //signal sendDone if need be
     if (to == deFactoMaxTransmitCount) {
       atomic k = k1;
       while (k != k2 && Q[k].next != k) { //to be stabilized
	 signal ReliableSendMsg.sendDone[Q[k].message.type](&(Q[k].message), SUCCESS);
	 atomic k = Q[k].next;
       }
       signal ReliableSendMsg.sendDone[Q[k].message.type](&(Q[k].message), SUCCESS);
     }
     */

     //update mtte, if need be
     if (to == deFactoMaxTransmitCount) {
#ifndef TOSSIM_SYSTIME
       call Time.getLocalTime(&currentTime);
       atomic clockReading = jiffiesToMilliseconds(&currentTime);
#else
       clockReading = (call SysTime.getTime32());
#endif

       atomic{
	 if (mtte0 != 0){
	   mtte0 = (clockReading - mtte0) / num;
	   //mtteDev estimation
	   if (mtte0 >= mtte)
	     mtteDev = mtteDev - (mtteDev>>compDevPastW) + ((mtte0-mtte)>>compDevPastW);
	   else 
	     mtteDev = mtteDev - (mtteDev>>compDevPastW) + ((mtte-mtte0)>>compDevPastW);
	   //mtte estimation
	   mtte = mtte - (mtte>>compPastW) + (mtte0>>compPastW);
#ifndef TOSSIM_SYSTIME
	   if (mtte > (MAX_MTTE_THRESHOLD<<compJIFFIES_PER_MILLISECOND))
	     mtte = mtte>>2;
#else
	   if (mtte > (MAX_MTTE_THRESHOLD<<compSYSTIME_UNITS_PER_MILLISECOND))
	     mtte = mtte>>2;
#endif
#ifndef TOSSIM_SYSTIME
	   if (mtte < (MIN_MTTE<<compJIFFIES_PER_MILLISECOND))
	     mtte = MIN_MTTE<<compJIFFIES_PER_MILLISECOND;
#else
	   if (mtte < (MIN_MTTE<<compSYSTIME_UNITS_PER_MILLISECOND))
	     mtte = MIN_MTTE<<compSYSTIME_UNITS_PER_MILLISECOND;
#endif
	 }
	 mtte0 = clockReading;
       }//atomic
     }
   } //end of move(...)

   //#ifndef EXPLICIT_ACK
   /* find the virtual queue an element belongs to */
   uint8_t findVQ(uint8_t k, uint8_t seq)
   {
     uint8_t q, k2, num;
     bool done;

     dbg(DBG_SWITCH, "entering findVQ(...)\n");

     if (k >= SEND_QUEUE_SIZE) //for stabilization
       return  deFactoMaxTransmitCount;

     if (seq != Q[k].seq && seq != NULL8)
       return deFactoMaxTransmitCount;
     else {
       atomic{
	 q = 0;
	 done = FALSE;
	 while (q < deFactoMaxTransmitCount && !done) {
	   if (VQ[q].size > 0) {
	     k2 = VQ[q].head;
	     while (k2 != k && Q[k2].next != k2 && Q[k2].next < SEND_QUEUE_SIZE)
	       k2 = Q[k2].next;
	     if (k2 == k || Q[k2].next > SEND_QUEUE_SIZE)
	       done = TRUE;
	     if (Q[k2].next > SEND_QUEUE_SIZE){//for stabilization
	       VQ[q].tail = Q[k2].next = k2;
	       num = 1;
	       while (k2 != Q[k2].prev && Q[k2].prev < SEND_QUEUE_SIZE) {
		 num++;
		 k2 = Q[k2].prev;
	       }
	       VQ[q].size = num;
	       VQ[q].head = Q[k2].prev = k2;
	       q = deFactoMaxTransmitCount;
	     }
	   }
	   if (!done)
	     q++;
	 }
       } //atomic
     }
     dbg(DBG_SWITCH, "exiting findVQ(...)\n");
     return q;     
   } //end of findVQ(...)
   //#endif //explicit ack

  /*send a packet at the head of the current virtual queue 
   */
  task void sendPacket()
  {
    uint8_t k, np0, cvq2, emptyElements2, cvqSize2;
#ifndef EXPLICIT_ACK
    uint8_t np1;
#endif
    ReliableComm_ProtocolMsg * RBCPtr;
#ifdef CALCULATE_LOG
    uint8_t j;
#endif
#ifndef TOSSIM_SYSTIME
    timeSync_t currentTime;
#else
    uint8_t i; //for tossim only
#endif
    uint32_t clockReading; 

#ifndef TOSSIM_SYSTIME
      call Time.getLocalTime(&currentTime);
      atomic clockReading = jiffiesToMilliseconds(&currentTime);
#else
      clockReading = (call SysTime.getTime32());
#endif

    atomic k = VQ[cvq].head;

#ifndef EXPLICIT_ACK
    //deal with ackLeft if need be
    if (k == ackLeft) {
      if (cvq < deFactoMaxTransmitCount-1) {
	move(cvq, k, k, cvq+1);
	k = VQ[cvq].head;
      }
      else 
	k = Q[k].next;
    }
#endif

    if (cvq >= deFactoMaxTransmitCount || k >= SEND_QUEUE_SIZE) //for stabilization
      return;

    atomic{
      //find to-be np0, cvq, cvqsize
      cvq2 = cvq;
#ifndef EXPLICIT_ACK
      if (Q[k].next == ackLeft) {
	if (Q[ackLeft].next == ackLeft) {//k2 is the last element of VQ[cvq]
	  cvq2++;
	  while (cvq2 < deFactoMaxTransmitCount && (VQ[cvq2].size == 0 || (VQ[cvq2].size == 1 && VQ[cvq2].head == ackLeft)))
	    cvq2++;
	  if (cvq2 >= deFactoMaxTransmitCount)
	    np0 = cvq2 = cvqSize2 = NULL8;
	  else {
	    np0 = VQ[cvq2].head;
	    cvqSize2 = VQ[cvq2].size;
	  }
	}
	else {//still other element in VQ[cvq]
	  np0 = Q[ackLeft].next;
	  cvqSize2 = VQ[cvq].size -2;
	}
      }
      else 
#endif //explicit_ack
	if (Q[k].next == k) {
	  cvq2++;
	  while (cvq2 < deFactoMaxTransmitCount 
		 && (VQ[cvq2].size == 0 
#ifndef EXPLICIT_ACK
                                                    || (VQ[cvq2].size == 1 && VQ[cvq2].head == ackLeft)
#endif
                                                 )
                                 )
	    cvq2++;
	  if (cvq2 >= deFactoMaxTransmitCount)
	    np0 = cvq2 = cvqSize2 = NULL8;
#ifndef EXPLICIT_ACK
	  else if (VQ[cvq2].head == ackLeft) {
	    np0 = Q[VQ[cvq2].head].next;
	    cvqSize2 = VQ[cvq2].size - 1;
	  }
#endif
	  else {
	    np0 = VQ[cvq2].head;
	    cvqSize2 = VQ[cvq2].size;
	  }
	}
	else {
	  np0 = Q[k].next;
	  cvqSize2 = VQ[cvq2].size - 1;
	}

#ifndef EXPLICIT_ACK
      //whether to set toWD depending on Q[np0].resend
      if (np0 != NULL8 && np0 < SEND_QUEUE_SIZE && !toWD
           && Q[np0].trxt > 1 
           && Q[np0].resend > (clockReading + ((mtts+ mttsDev<<compDevWeight) * channelUtilizationGuard)))
	toWD = TRUE;
      //set lastReceive for .resend protection
      if (np0 != NULL8)
	lastReceive = clockReading;
      else 
	lastReceive = 0;

      //to-be np1
      if (np0 != NULL8 && Q[k].message.addr != Q[np0].message.addr)
	np0 = np1 = NULL8;
      else {
	np1 = VQ[deFactoMaxTransmitCount].tail;
	if (lastDest == NULL16 || lastDest != Q[k].message.addr) {
	  if (np0 != NULL8)
	    np0 += SEND_QUEUE_SIZE;
	  if (np1 != NULL8)
	    np1 += SEND_QUEUE_SIZE;
	}
      }
#endif //explicit_ack

      //find the "to-be" emptyElements//, cvq, & cvqSize
      emptyElements2 = VQ[deFactoMaxTransmitCount].size;
      if (Q[k].trxt == deFactoMaxTransmitCount)
	emptyElements2 += 1;

      //to encode whether to withdraw from being the highest-ranked node
      if (cvq2 != NULL8 && toWD)
	cvqSize2 += (SEND_QUEUE_SIZE + 1);

      //attach the additional ReliableComm control information: congestion & contention
      RBCPtr = (ReliableComm_ProtocolMsg *)(Q[k].message.length - sizeof(ReliableComm_ProtocolMsg) + Q[k].message.data);
#ifndef EXPLICIT_ACK
      RBCPtr->np0 = np0;
      RBCPtr->np1 = np1;
      if (Q[k].trxt > 1)
	RBCPtr->cumulLeft = RBCPtr->cumulRight = SEND_QUEUE_SIZE;
#endif
      RBCPtr->emptyElements = emptyElements2; 
      RBCPtr->cvq = cvq2; 
      RBCPtr->cvqSize = cvqSize2;
      RBCPtr->mtte = (mtte + mtteDev<<compDevWeight)>>
#ifndef TOSSIM_SYSTIME
                                                compJIFFIES_PER_MILLISECOND;
#else
                                                compSYSTIME_UNITS_PER_MILLISECOND;
#endif
      RBCPtr->mtts = (mtts + mttsDev<<compDevWeight)>>
#ifndef TOSSIM_SYSTIME
                                                compJIFFIES_PER_MILLISECOND;
#else
                                                compSYSTIME_UNITS_PER_MILLISECOND;
#endif
       //if (Q[k].message.addr == BASE_STATION_ID)
       if (isBaseChild) //echelon
	parentSpace = NULL8;
      else if (Q[k].message.addr != lastDest)
	parentSpace = INIT_PARENT_SPACE;
      lastDest = Q[k].message.addr;
#ifndef EXPLICIT_ACK
      //if (lastDest == BASE_STATION_ID && (!acceptBaseAck || pToSend != aggregatedACK)) {
      if (isBaseChild && (!acceptBaseAck || pToSend != aggregatedACK)) { //echelon
	acceptBaseAck = TRUE;
	pToSend = aggregatedACK;
      }
#endif
    } //atomic

    //#ifdef EXPLICIT_ACK
    atomic {
      lastSendCvq = cvq;
      lastSendPtr = k;
    }
    //#endif

    //send Q[k].message
    if (!(call RadioBareSend.send(&(Q[k].message)))) { //failed send
      dbg(DBG_SWITCH, "ReliableSend: send request failed for Q[%d]\n", k);
      atomic pending = FALSE;
    }
    else { //successful send
      //check whether to re-calculate mtts
      atomic{
	if (Q[k].trxt > 1)
	  mtts0 = 0;
      }

#ifdef INTEGRITY_CHECKING
      if (Q[k].trxt > 1) {
	reTranxits++;
	dbg(DBG_SWITCH3, "%d retransmissions \n", reTranxits);
      }
#endif

      atomic{
	//if (lastDest != BASE_STATION_ID && parentSpace > 0)
	if (! isBaseChild && parentSpace > 0) //echelon
	  parentSpace--;
	pCongestWait = 0;
	toWD = FALSE;
	contentionWait = 0;
	highestRankedNode = NULL16;
	/*
	highestRanked.node_id = NULL16;
	highestRanked.emptyLen = highestRanked.cvq = highestRanked.size = NULL8;
	highestRanked.contentionWait = 0;
	secondHighest.node_id = NULL16;
	secondHighest.emptyLen = secondHighest.cvq = secondHighest.size = NULL8;
	secondHighest.contMonitorW = 0;
	*/
      }//atomic

#ifdef TOSSIM_SYSTIME
      dbg(DBG_SWITCH, "A new packet is sent: \naddr = %d, type = %d, group = %d, length = %d,   data[] =\n", Q[k].message.addr, Q[k].message.type, Q[k].message.group, Q[k].message.length);
      //for (i = 0; i < Q[k].message.length; i++)
      //	dbg(DBG_SWITCH, "%X \n", (uint8_t)Q[k].message.data[i]);
#endif
#ifdef CALCULATE_LOG 
      atomic{
	//packets sent
	logPtr->totalPacketsSent++;
	j = 0;
	while (j < MAX_NUM_PARENTS && 
                              logPtr->linkSending[j].node_id != NULL8 && 
   	            logPtr->linkSending[j].node_id != Q[k].message.addr)
	  j++;
	if (j < MAX_NUM_PARENTS && logPtr->linkSending[j].node_id == NULL8)
	  logPtr->linkSending[j].node_id = Q[k].message.addr;
	if (j < MAX_NUM_PARENTS)
	  (logPtr->linkSending[j].totalPacketsSent)++;
	//Log: twice Tried
	if (Q[k].trxt == 2)
	  logPtr->twiceTried++;
	else if (Q[k].trxt == 3) 
	  logPtr->tripleTried++; 
	/*
	//Log: calculate maxRetransmitFailCount 
	logPtr->maxRetransmitFailureCount++;
	//Log: maxRetranxitFailcount for packets from other motes 
	if (Q[(dequeue_next-1)%SEND_QUEUE_SIZE].fromAddr != TOS_LOCAL_ADDRESS)
	  logPtr->otherMaxRetransmitFailureCount++;
	*/
      }//atomic
#endif
    } //end of successful send
 
  } //end of sendPacket()


  /* A base station enqueues a packet to be sent to UART
   */
  bool enqueueBase(uint16_t address, uint8_t length, TOS_MsgPtr msg, uint8_t id)
  {
    uint8_t j; 

    //copy msg
    atomic{
      Q[uartWritePtr].message.addr = address;
      Q[uartWritePtr].message.type = id;
      Q[uartWritePtr].message.length = length;
      Q[uartWritePtr].message.group = TOS_AM_GROUP;
      for (j=0; j < length && j < TOSH_DATA_LENGTH; j++)
	Q[uartWritePtr].message.data[j] = msg->data[j];
      Q[uartWritePtr].message.crc = msg->crc;
      Q[uartWritePtr].message.strength = msg->strength;
      Q[uartWritePtr].message.ack = msg->ack;
      Q[uartWritePtr].message.time = msg->time;

      //update uartWritePtr
      uartWritePtr++;
      if (uartWritePtr == SEND_QUEUE_SIZE)
	uartWritePtr = NUM_BASE_ACK_BUFFERS;
    }//atomic
    return SUCCESS;
  } //end of enqueueBase(..., ...)

  /* decide whether need to dequeue packets to UART
   */
  bool toUart()
  {
    //if (uartPending || uartReadPtr == uartWritePtr || TOS_LOCAL_ADDRESS != BASE_STATION_ID)
    if (uartPending || uartReadPtr == uartWritePtr || ! isBase) //echelon
      return FALSE;
    else
      return TRUE;
  } //end of toUart()


  /*send a packet pointed by uartReadPtr to UART
   */
  task void sendUart()
  {
    //send Q[uartReadPtr].message
    //if (!(call UARTBareSend.send(&(Q[uartReadPtr].message)))) //failed send
    if (!(call UARTSend.send(TOS_UART_ADDR,  Q[uartReadPtr].message.length, &(Q[uartReadPtr].message)))) //failed send
      atomic uartPending = FALSE; 
  } //end of sendUart()


  /* Process the uartSendDone event */
  task void uartSendDoneProcessing()
  {
    //update uartReadPtr
    atomic {
      uartReadPtr++;
      if (uartReadPtr == SEND_QUEUE_SIZE)
	uartReadPtr = NUM_BASE_ACK_BUFFERS;
    }
  }//end of uartSendDoneProcessing 


#ifndef EXPLICIT_ACK
  /* base stations decide whether to send out an acknowledgement packet or not */
  bool toAck()
  {
#ifndef TOSSIM_SYSTIME
    timeSync_t currentTime;
#endif
    uint32_t clockReading;

    /*debug
    if (isBase)
      call Leds.greenToggle();
    */

    //if (TOS_LOCAL_ADDRESS != BASE_STATION_ID || deFactoMaxTransmitCount <= 1)
    if (! isBase || deFactoMaxTransmitCount <= 1) //echelon
      return FALSE;

    if (sendAckPtr != storeAckPtr)
      return TRUE;

    if (lastReceive == 0)
      return FALSE;

#ifndef TOSSIM_SYSTIME
    call Time.getLocalTime(&currentTime);
    atomic clockReading = jiffiesToMilliseconds(&currentTime);
#else
    clockReading = (call SysTime.getTime32());
#endif

    if ((clockReading - lastReceive) > baseAckWait * mtts) {
      if (!pending) 
	return TRUE;
      else {
	baseAckDeadCount++;
	if (baseAckDeadCount >= MAX_BASE_ACK_DEAD_COUNT) {
	  atomic{
	    pending = FALSE;
	    baseAckDeadCount = 0;
	  }
	  return TRUE;
	}
      }
    }
    return FALSE;
  } //end of toAck() 

  task void baseAck()
  {
    if (!(call RadioBareSend.send(&(Q[sendAckPtr].message)))) {
      dbg(DBG_SWITCH, "Base ack failed: fails to send ack packet out\n");
      atomic{
	pending = FALSE;
	baseAckDeadCount = 0;
      }
    }
#ifdef CALCULATE_LOG
    //Log
    atomic logPtr->totalPacketsSent++;
#endif

  } //end of baseAck()
#endif //explicit ack


  /* Process the sendDone event */
  task void sendDoneProcessing()
  {
#ifndef TOSSIM_SYSTIME
    timeSync_t currentTime;
#endif
    uint32_t clockReading;

    //dbg(DBG_SWITCH, "Process sendDone:beginging\n");
    //if (TOS_LOCAL_ADDRESS == BASE_STATION_ID) { //is the base station
    if (isBase) { //is the base station: echelon
      atomic pending = FALSE;
#ifndef EXPLICIT_ACK
      //sendDone for baseAck():
      //parameters related to baseAck
      atomic{
	lastReceive = 0;
	if (sendAckPtr != storeAckPtr)
	  sendAckPtr = (sendAckPtr+1)%NUM_BASE_ACK_BUFFERS;
	else if (nAck == aggregatedACK)
	  nAck = 0;
      }
      if (toAck()) {   //needs to ack
	atomic{
	  pending = TRUE;
	  pendingDeadPeriod = baseAckDeadCount = 0;
	}
	post baseAck();
      }
#endif
      return;
    } //is base

    //is a non-base node
#ifndef TOSSIM_SYSTIME
      call Time.getLocalTime(&currentTime);
      atomic clockReading = jiffiesToMilliseconds(&currentTime);
#else
      clockReading = (call SysTime.getTime32());
#endif

    //move lastSendPtr to the end of an immediately lower-ranked virtual queue
    //Ver-1.1 
      if (lastSendPtr != VQ[lastSendCvq].head) //for stabilization
	  lastSendCvq = findVQ(lastSendPtr, Q[lastSendPtr].seq);  
      if (Q[lastSendPtr].trxt >= deFactoMaxTransmitCount
#ifdef EXPLICIT_ACK
         || Q[lastSendPtr].message.ack != 0
#endif
          )
	move(lastSendCvq, lastSendPtr, lastSendPtr, deFactoMaxTransmitCount);
      else
	move(lastSendCvq, lastSendPtr, lastSendPtr, lastSendCvq+1);
      if (Q[lastSendPtr].trxt < deFactoMaxTransmitCount) {
	(Q[lastSendPtr].trxt)++;
#ifndef EXPLICIT_ACK
	//if (lastDest != BASE_STATION_ID)
	if (! isBaseChild) //echelon
	  //Q[lastSendPtr].resend = clockReading + (((pToSend == 0? pToSendDev : pToSend) * pMtts)<<compConsrvFactor); 
	  Q[lastSendPtr].resend = clockReading +(((pToSend + 3 + pToSendDev) * pMtts)<<compConsrvFactor);
	else 
                      Q[lastSendPtr].resend = clockReading + ((pToSend + 2) * (mtts 
						      // + (mttsDev<<compDevWeight)
                                                                                                  ) <<compConsrvFactor);
#endif
      }

      atomic pending = FALSE;
      //update mtts
      atomic{
	if (mtts0 != 0 && 
	    (Q[lastSendPtr].trxt == 1 || Q[lastSendPtr].trxt == 2)
                        ) {
	  mtts0 = clockReading - mtts0; //double role for mtts0
	  //mttsDev estimation
	  if (mtts0 >= mtts)
	     mttsDev = mttsDev - (mttsDev>>compDevPastW) + ((mtts0-mtts)>>compDevPastW);
	   else 
	     mttsDev = mttsDev - (mttsDev>>compDevPastW) + ((mtts-mtts0)>>compDevPastW);
	   //mtts estimation
	  mtts = mtts - (mtts>>compPastW) + (mtts0>>compPastW);
#ifndef TOSSIM_SYSTIME
	  if (mtts > (MAX_MTTS_THRESHOLD<<compJIFFIES_PER_MILLISECOND))
	    mtts = mtts>>2;
#else
	  if (mtts > (MAX_MTTS_THRESHOLD<<compSYSTIME_UNITS_PER_MILLISECOND))
	    mtts = mtts>>2;
#endif
#ifndef TOSSIM_SYSTIME
	  if (mtts < (MIN_MTTS<<compJIFFIES_PER_MILLISECOND))
	    mtts = MIN_MTTS<<compJIFFIES_PER_MILLISECOND;
#else
	  if (mtts < (MIN_MTTS<<compSYSTIME_UNITS_PER_MILLISECOND))
	    mtts = MIN_MTTS<<compSYSTIME_UNITS_PER_MILLISECOND;
#endif
	}
	mtts0 = clockReading;
      }

      if (toSend()) { //to send another packet
	atomic{
	  pending = TRUE;
	  pendingDeadPeriod = 0;
	}
	post sendPacket();
      }
  }//end of sendDoneProcessing 


   /* move elements in one virtual queue to another;
    * //also signal sendDone (not any more), 
    * but does not change cvq (which is diff. from move(...)), neither
    * change mtte, mtts, mtte0, mtts0, etc.
    * Only for ParameterTuning 
    */
   void parMove(uint8_t q1, uint8_t k1, uint8_t k22, uint8_t to)
   {
     uint8_t k, k2, num;

     if (k1 >= SEND_QUEUE_SIZE || k22 >= SEND_QUEUE_SIZE) //for stabilization
       return;

     atomic{
       k2 = k22;
       num = 1;
       k = k1;
       Q[k].seq = (Q[k].seq+1)%NULL8;//queue postion is freed
     }
     while (k != k2)
       if (Q[k].next != k && Q[k].next < SEND_QUEUE_SIZE) { //for stabilization
	 atomic{
	   k = Q[k].next;
	   Q[k].seq = (Q[k].seq+1)%NULL8;//queue postion is freed
	   num++;
	 }
       }
       else {//conservative stabilize this virtual queue
	 atomic{
	   VQ[q1].tail = Q[k].next = k;
	   num = 1;
	   while (k != Q[k].prev && Q[k].prev < SEND_QUEUE_SIZE) {
	     k = Q[k].prev;
	     num++;
	   }
	   VQ[q1].size = num;
	   VQ[q1].head = Q[k].prev = k;
	 }//atomic
	 return;
       }

     atomic{
       //update VQ[q1]
       VQ[q1].size -= num;
       if (VQ[q1].size == 0)
	 VQ[q1].head = VQ[q1].tail = NULL8;
       else {
	 if (Q[k1].prev == k1) {
	   VQ[q1].head = Q[k2].next;
	   Q[Q[k2].next].prev = Q[k2].next;
	 }
	 else if (Q[k2].next == k2) {
	   VQ[q1].tail = Q[k1].prev;
	   Q[Q[k1].prev].next = Q[k1].prev;
	 }
	 else {
	   Q[Q[k1].prev].next = Q[k2].next;
	   Q[Q[k2].next].prev = Q[k1].prev;
	 }
       }

       //update VQ[to]
       if (VQ[to].size == 0) {
	 VQ[to].head = k1;
	 VQ[to].tail = k2;
	 Q[k1].prev = k1;
	 Q[k2].next = k2;
       }
       else if (to != deFactoMaxTransmitCount) {
	 Q[VQ[to].tail].next = k1;
	 Q[k1].prev = VQ[to].tail;
	 VQ[to].tail = Q[k2].next = k2;
       }
       else { //to == deFactoMaxTransmitCount
	 Q[VQ[to].head].prev = k2;
	 Q[k2].next = VQ[to].head;
	 VQ[to].head = Q[k1].prev = k1;
       }
       VQ[to].size += num;
     }//atomic
   } //end of parMove(...)

   /* tune parameters of ReliableComm */
   void parameterTuningImpl(ReliableComm_Tuning_Msg * tuningMsgPtr)
   {
     uint8_t k, transmitPower, maxTransmitCount;

     //integrity checking
     if (tuningMsgPtr->maxTransmitCount > MAX_TRANSMIT_COUNT)
       return;

     atomic{
       transmitPower = tuningMsgPtr->transmissionPower;
       maxTransmitCount = tuningMsgPtr->maxTransmitCount;
     }

#ifndef TOSSIM_SYSTIME
     call CC1000Control.SetRFPower(transmitPower);
#endif

     if (maxTransmitCount != deFactoMaxTransmitCount) {
       atomic k = deFactoMaxTransmitCount;
       if (k < maxTransmitCount)
	 while (k < maxTransmitCount) {
	   if (VQ[k].size != 0)
	     parMove(k, VQ[k].head, VQ[k].tail, maxTransmitCount);
	   atomic k++;
	 }
       else {
	 while (k > maxTransmitCount) {
	   if (VQ[k].size != 0)
	     parMove(k, VQ[k].head, VQ[k].tail, maxTransmitCount);
	   atomic k--;
	 }
	 atomic{
	   if (cvq >= maxTransmitCount) {
	     cvq = NULL8;
	     parentSpaceDeadPeriod = 0;
	     mtte0 = mtts0 = 0;
	     /* Hongwei
	     mtte = mtte - (mtte>>compPastW) + (MTTE>>compPastW);
	     mtts = mtts - (mtts>>compPastW) + (MTTS>>compPastW);
	     mtteDev = mtteDev - (mtteDev>>compPastW) + (MTTE_DEV>>compPastW);
	     mttsDev = mttsDev - (mttsDev>>compPastW) + (MTTS_DEV>>compPastW);
	     */
	   }
	 }
       }

       atomic deFactoMaxTransmitCount = maxTransmitCount;
     }
   } //end of parameterTuningImpl(...) 


   /* process a packet destined to a node itself */
   void accept(TOS_MsgPtr packet)
   {
     uint8_t length;
     uint16_t frAddr;
     uint8_t frPos, frSeq;
     uint8_t childPtr;
     ReliableComm_ProtocolMsg * RBCPtr;
#ifndef EXPLICIT_ACK
     Base_Ack_Msg * baseAckPtr;
#ifndef TOSSIM_SYSTIME
     timeSync_t currentTime;
#endif
     uint32_t clockReading;
#endif
     //uint8_t i;      //debug
     //bool done; //debug
     //ReliableComm_ProtocolMsg * RBCPtr2; //debug

     atomic{
       length = packet->length - sizeof(ReliableComm_ProtocolMsg);
       RBCPtr = (ReliableComm_ProtocolMsg *)(length + packet->data); 

       frAddr = RBCPtr->myAddr;
       frPos = RBCPtr->myPos;
       frSeq = RBCPtr->mySeq;

       for (childPtr=0; childPtr < numImNghs && children[childPtr].node_id != frAddr; childPtr++)
	 ;
     }//atomic

     if (childPtr == numImNghs) {
       if (numImNghs < MAX_NUM_CHILDREN) {
	 atomic children[numImNghs].node_id = frAddr;
	 numImNghs++;
	 dbg(DBG_SWITCH, "get a new import neighbor %d; the number of import neighbors is %d\n", children[numImNghs-1].node_id, numImNghs);
       }
       else {
	 dbg(DBG_SWITCH, "exceed the limit of max. number of import neighbors\n");
	 return;
       }
     }

     //dbg(DBG_SWITCH, "childPtr =%d \n", childPtr);

#ifdef CALCULATE_LOG
     atomic{
       //Log:log link quality (reception)
       if (childPtr < MAX_NUM_CHILDREN){
	 logPtr->linkReception[childPtr].node_id = (uint8_t)(children[childPtr].node_id & 0x00ff);
	 (logPtr->linkReception[childPtr].totalPacketsReceived)++;
       }
       /* obsolete
       if (childPtr == 0) {
	 logPtr->child1ID = (uint8_t)(children[childPtr].node_id & 0x00ff);
	 logPtr->totalPacketsFromChild1++;
       }
       else if (childPtr == 1) {
	 logPtr->child2ID = (uint8_t)(children[childPtr].node_id & 0x00ff);
	 logPtr->totalPacketsFromChild2++;
       }
       else if (childPtr == 2) {
	 logPtr->child3ID = (uint8_t)(children[childPtr].node_id & 0x00ff);
	 logPtr->totalPacketsFromChild3++;
       }
       else if (childPtr == 3) {
	 logPtr->child4ID = (uint8_t)(children[childPtr].node_id & 0x00ff);
	 logPtr->totalPacketsFromChild4++;
       }
       */
     }//atomic
#endif

     //check if it is a duplicate 
     if (children[childPtr].lastSeq[frPos] ==  frSeq 
#ifndef EXPLICIT_ACK
           && !((RBCPtr->myAddr == RBCPtr->frAddr && RBCPtr->cumulLeft == NULL8) ||
                      (RBCPtr->myAddr != RBCPtr->frAddr && RBCPtr->cumulLeft != SEND_QUEUE_SIZE)
                    )
#endif
         ) { //is a duplicate (could be due to ack-loss or too-early-retransmission)
       //debug
       //call Leds.redToggle();
       /*debug: this debug code could make a mote dead under extreme conditions. Strange?!
       if (VQ[0].size > 0 && VQ[0].size <= SEND_QUEUE_SIZE) {
	 atomic{
	   i = VQ[0].head;
	   done = FALSE;
	 }
	 while (Q[i].next != i) {
	   atomic RBCPtr2 = (ReliableComm_ProtocolMsg *)(length + Q[i].message.data);
	   if (RBCPtr2->frAddr == frAddr && RBCPtr2->frPos == frPos) {
	     atomic done = TRUE;
	     call Leds.redToggle();
	   }
	   else 
	     atomic i = Q[i].next;
	 }
	 if (Q[i].next == i && !done) {
	   atomic RBCPtr2 = (ReliableComm_ProtocolMsg *)(length + Q[i].message.data);
	   if (RBCPtr2->frAddr == frAddr && RBCPtr2->frPos == frPos) {
	     atomic done = TRUE;
	     call Leds.redToggle();
	   }
	   else 
	     call Leds.greenToggle();
	 }
       }
       else 
	 call Leds.greenToggle();
       */
#ifdef CALCULATE_LOG
       //Log: received duplicates 
       atomic{
	 (logPtr->receivedDuplicates)++;
	 if (childPtr < MAX_NUM_CHILDREN)
	   (logPtr->linkReception[childPtr].receivedDuplicates)++;
	 /*
	 if (childPtr == 0)
	   logPtr->duplicatesFromChild1++;
	 else if (childPtr == 1)
	   logPtr->duplicatesFromChild2++;
	 else if (childPtr == 2)
	   logPtr->duplicatesFromChild3++;
	 else if (childPtr == 3)
	   logPtr->duplicatesFromChild4++;
	 */
       }//atomic
#endif

       return;
     }

     //is a fresh packet
     atomic children[childPtr].lastSeq[frPos] = frSeq;

#ifndef EXPLICIT_ACK
     atomic{
       RBCPtr->frAddr = frAddr;
       RBCPtr->frPos = frPos;
       RBCPtr->frSeq = frSeq;

       if (children[childPtr].expect0 == NULL8 && children[childPtr].expect1 == NULL8) { //not to consider ACK/NACK
	 if (RBCPtr->np0 != NULL8 || RBCPtr->np1 != NULL8 ) {
	   children[childPtr].ackLeft = 	RBCPtr->cumulLeft = RBCPtr->cumulRight = frPos;
	   if (RBCPtr->np0 != NULL8 && RBCPtr->np0 >= SEND_QUEUE_SIZE)
	     RBCPtr->np0 -= SEND_QUEUE_SIZE;
	   if (RBCPtr->np1 != NULL8 && RBCPtr->np1 >= SEND_QUEUE_SIZE)
	     RBCPtr->np1 -= SEND_QUEUE_SIZE;
	 }
	 else 
	   children[childPtr].ackLeft = RBCPtr->cumulLeft = RBCPtr->cumulRight = NULL8;
	 children[childPtr].expect0 = RBCPtr->np0;
	 children[childPtr].expect1 = RBCPtr->np1;
       }
       else { //to consider ACK/NACK
	 if (children[childPtr].expect0 == frPos || children[childPtr].expect1 == frPos) { //perfect ACK
	   RBCPtr->cumulLeft = children[childPtr].ackLeft;
	   RBCPtr->cumulRight = frPos;
	   if (RBCPtr->np0 == NULL8 && RBCPtr->np1 == NULL8)
	     children[childPtr].ackLeft = NULL8;
	   if (RBCPtr->np0 != NULL8 && RBCPtr->np0 >= SEND_QUEUE_SIZE)
	     RBCPtr->np0 -= SEND_QUEUE_SIZE;
	   if (RBCPtr->np1 != NULL8 && RBCPtr->np1 >= SEND_QUEUE_SIZE)
	     RBCPtr->np1 -= SEND_QUEUE_SIZE;
	   children[childPtr].expect0 = RBCPtr->np0;
	   children[childPtr].expect1 = RBCPtr->np1;
	 }
	 else { //imperfect/interrupted ACK & NACK
	   if ((RBCPtr->np0 != NULL8 && RBCPtr->np0 >= SEND_QUEUE_SIZE) ||
 	        (RBCPtr->np1 != NULL8 && RBCPtr->np1 >= SEND_QUEUE_SIZE)) {//interrupted ACK
	     RBCPtr->cumulLeft = children[childPtr].ackLeft;
	     RBCPtr->cumulRight = children[childPtr].lastPos;
	     children[childPtr].ackLeft = frPos;
	     if (RBCPtr->np0 != NULL8)
	       children[childPtr].expect0 = RBCPtr->np0 - SEND_QUEUE_SIZE;
	     else
	       children[childPtr].expect0 = NULL8;
	     if (RBCPtr->np1 != NULL8)
	       children[childPtr].expect1 = RBCPtr->np1 - SEND_QUEUE_SIZE;
	     else
	       children[childPtr].expect1 = NULL8;
	   }
	   else { //NACK
	     /*debug
	     //if (TOS_LOCAL_ADDRESS == BASE_STATION_ID)
	     if (isBase) //echelon
	       call Leds.yellowToggle();
	     */
	     RBCPtr->cumulLeft = children[childPtr].lastPos + SEND_QUEUE_SIZE + 1;
	     RBCPtr->cumulRight = frPos + SEND_QUEUE_SIZE + 1;
	     if (RBCPtr->np0 != NULL8 || RBCPtr->np1 != NULL8 )
	       children[childPtr].ackLeft = frPos;
	     else 
	       children[childPtr].ackLeft = NULL8; 
	     children[childPtr].expect0 = RBCPtr->np0;
	     children[childPtr].expect1 = RBCPtr->np1;
	   } //end of NACK
	 } //end of "imperfect ack or nack"
       }//end of "to consider ack/nack"
       children[childPtr].lastPos = frPos;
     } //end of atomic{

     //store for aggregated ack at the base station
     //if (TOS_LOCAL_ADDRESS == BASE_STATION_ID && deFactoMaxTransmitCount > 1) {
     if (isBase && deFactoMaxTransmitCount > 1) { //echelon
       //prepare additional info. for the base-ack message
       if (nAck == aggregatedACK){
	 nAck = 0;
	 if (((storeAckPtr+1)%NUM_BASE_ACK_BUFFERS) != sendAckPtr)
	   storeAckPtr = (storeAckPtr+1)%NUM_BASE_ACK_BUFFERS;
       }
#ifndef TOSSIM_SYSTIME
       call Time.getLocalTime(&currentTime);
       atomic clockReading = jiffiesToMilliseconds(&currentTime);
#else
       clockReading = (call SysTime.getTime32());
#endif
       atomic lastReceive = clockReading;

       if (nAck == 0) 
	 atomic Q[storeAckPtr].message.type = packet->type;

       atomic{
	 baseAckPtr = (Base_Ack_Msg *)(sizeof(Base_Ack_Msg) * nAck + Q[storeAckPtr].message.data);
	 baseAckPtr->frAddr = RBCPtr->frAddr;
	 baseAckPtr->frPos = RBCPtr->frPos;
	 baseAckPtr->frSeq = RBCPtr->frSeq;
	 baseAckPtr->cumulLeft = RBCPtr->cumulLeft;
	 baseAckPtr->cumulRight = RBCPtr->cumulRight;
	 nAck++;
                     mtts = mtts - (mtts>>compPastW) + (((RBCPtr->mtts)<<
#ifndef TOSSIM_SYSTIME
   				                      compJIFFIES_PER_MILLISECOND) >> compPastW);
#else
					  (compSYSTIME_UNITS_PER_MILLISECOND - compPastW));
#endif
#ifndef TOSSIM_SYSTIME
	  if (mtts > (MAX_MTTS_THRESHOLD<<compJIFFIES_PER_MILLISECOND))
	    mtts = mtts>>2;
#else
	  if (mtts > (MAX_MTTS_THRESHOLD<<compSYSTIME_UNITS_PER_MILLISECOND))
	    mtts = mtts>>2;
#endif
#ifndef TOSSIM_SYSTIME
	  if (mtts < (MIN_MTTS<<compJIFFIES_PER_MILLISECOND))
	    mtts = MIN_MTTS<<compJIFFIES_PER_MILLISECOND;
#else
	  if (mtts < (MIN_MTTS<<compSYSTIME_UNITS_PER_MILLISECOND))
	    mtts = MIN_MTTS<<compSYSTIME_UNITS_PER_MILLISECOND;
#endif
       }//atomic

       //Check whether to send ack
       if (toAck())
         post baseAck();
     } //end of "store for aggregated ack at the base station" 
#endif //explicit ack

     //signal the reception event
     atomic packet->length = packet->length - sizeof(ReliableComm_ProtocolMsg);
     signal ReliableReceiveMsg.receive[packet->type](packet);

#ifdef CALCULATE_LOG
     //Log
     atomic logPtr->totalPacketsReceived++;
#endif
   } //end of accept(...) 

#ifndef EXPLICIT_ACK
    /* move nacked packets to be retransmitted quickly */
   void nack(uint16_t dest, uint8_t q, uint8_t start, uint8_t end2)
   {
     uint8_t k1, k2, end;

     if (q ==0 || start >= SEND_QUEUE_SIZE || end2 >= SEND_QUEUE_SIZE) //for stabilization
       return;

     atomic{
       end = end2;
       k1 = start;
       k2 = Q[k1].next;
       if (k1 == end)
	 k2 = k1;
     } //atomic

     while (k2 != end)
       if (Q[k2].message.addr == dest)
	 atomic {
	 if (Q[k2].next < SEND_QUEUE_SIZE && Q[k2].next != k2)
	   k2 = Q[k2].next;
	 else
	   end = k2; //for stabilization
       }
       else {
	 move(q, k1, Q[k2].prev, q-1);
	 atomic {
	   k1 = k2;
	   while (k2 != end && Q[k2].message.addr != dest)
	     if (Q[k2].next < SEND_QUEUE_SIZE && Q[k2].next != k2)
	       k1 = k2 = Q[k2].next;
	     else 
	       end = k2; //for stabilization
	   if (k2 != end) {
	     if (Q[k2].next < SEND_QUEUE_SIZE && Q[k2].next != k2)
	       k2 = Q[k2].next;
	     else 
	       end = k2; //for stabilization
	   }
	 }//atomic
       }
     if (Q[k1].message.addr == dest)
       move(q, k1, k2, q-1);
   } //end of nack(...)


   /* process acks/nacks */
   void ANaCK(uint8_t frPos1, uint8_t frSeq1, uint8_t cumulLeft1, uint8_t cumulRight1)
   {
     uint8_t q, q1, q2, frPos, frSeq, cumulLeft, cumulRight, i;
     bool ack;
     uint16_t dest;

     dbg(DBG_SWITCH, "entering ANaCK: frPos =%d, frSeq = %d, cumulLeft = %d, cumulRight = %d\n", frPos1, frSeq1, cumulLeft1, cumulRight1);

     //for stabilization
     if (frPos1 >= SEND_QUEUE_SIZE || cumulLeft1 >= SEND_QUEUE_SIZE || cumulRight1 >= SEND_QUEUE_SIZE)
       return;

     atomic{
       frPos = frPos1;
       frSeq = frSeq1;
       cumulLeft = cumulLeft1;
       cumulRight = cumulRight1;
     }

     q = findVQ(frPos, frSeq); 

#ifdef CALCULATE_LOG
     //Log
     if (cumulLeft != SEND_QUEUE_SIZE && (q != deFactoMaxTransmitCount && Q[frPos].trxt > 2))
       atomic logPtr->delayedACK++;
#endif
     /*debug
     if (cumulLeft != SEND_QUEUE_SIZE && (q != deFactoMaxTransmitCount && Q[frPos].trxt > 2))
       call Leds.yellowToggle();
     */

     //when this queue position has already been freed/acked
     if (q == deFactoMaxTransmitCount)
       return;

     //when this queue position has NOT been freed/acked
     if ((cumulLeft == SEND_QUEUE_SIZE || cumulRight == SEND_QUEUE_SIZE) && frPos != ackLeft) //is individual ack via retransmitted packets from parent
       move(q, frPos, frPos, deFactoMaxTransmitCount); 
     else if (cumulLeft == NULL8 && cumulRight == NULL8){
       atomic {
	 if (frPos == ackLeft)
	   ackLeft = NULL8;
       }
       move(q, frPos, frPos, deFactoMaxTransmitCount); 
     }
     else if (cumulLeft != NULL8 && cumulLeft != SEND_QUEUE_SIZE && cumulRight != NULL8 && cumulRight != SEND_QUEUE_SIZE) { // is ack or nack
       atomic{
	 if (cumulLeft < SEND_QUEUE_SIZE)
	   ack = TRUE;
	 else {
	   ack = FALSE;
	   cumulLeft -= (SEND_QUEUE_SIZE+1);
	   cumulRight -= (SEND_QUEUE_SIZE+1);
	 }
       }
       //find and update, if necessary, the positions of the acked/nacked packets
       //cumulRight
       q1 = findVQ(cumulLeft, NULL8);
       q2 = findVQ(cumulRight, NULL8);
       if (q1 < q2) { //for stabilization
	 if (frPos != ackLeft) 
	   move(q, frPos, frPos, deFactoMaxTransmitCount);
	 return;
       }
       atomic{
	 if (q2 != 0 && q2 != deFactoMaxTransmitCount & cumulLeft != frPos && cumulRight == frPos){
	   if (Q[frPos].prev != frPos)
	     cumulRight = Q[frPos].prev;
	   else {
	     q2++;
	     while (q2 < deFactoMaxTransmitCount && VQ[q2].size == 0)
	       q2++;
	     if (q2 < deFactoMaxTransmitCount && VQ[q2].size > 0)
	       cumulRight = VQ[q2].tail; 
	   }
	 }
       }//atomic

       //check whether to free frPos
       if (ack && cumulLeft != frPos)
	 move(q, frPos, frPos, deFactoMaxTransmitCount);

       //related to ackLeft
       if (ack) {
	 if (ackLeft != NULL8 && ackLeft != cumulLeft)
	   move (findVQ(ackLeft, NULL8), ackLeft, ackLeft, deFactoMaxTransmitCount);
	 atomic ackLeft = cumulLeft;
       }
       else { //nack
	 if (ackLeft != NULL8 && ackLeft != frPos)
	   move (findVQ(ackLeft, NULL8), ackLeft, ackLeft, deFactoMaxTransmitCount);
	 atomic ackLeft = frPos;
       }

       //find and update, if necessary, the positions of the acked/nacked packets
       //cumulLeft
       atomic{
	 if (q1 == 0 || cumulLeft == frPos)
	   q1 = q2 = deFactoMaxTransmitCount; //stop ack/nack processing
	 else if (Q[cumulLeft].next != cumulLeft)
	   cumulLeft = Q[cumulLeft].next;
	 else {
	   q1--;
	   while (q1 > 0 && VQ[q1].size == 0)
	     q1--;
	   if (q1 > 0 && VQ[q1].size > 0)
	     cumulLeft = VQ[q1].head;
	 }
       }//atomic

       //process the acked/nacked packets according to q1, q2
       if (q1 != 0 && q2 != 0 && q2 != deFactoMaxTransmitCount) 
	 if (q1 == q2 && VQ[q1].size > 0) { //when cumulLeft and cumulRight point to packets in the same VQ
	   if (ack) //ack
	     move(q1, cumulLeft, cumulRight, deFactoMaxTransmitCount);
	   else //nack
	     nack(Q[cumulLeft].message.addr, q1, cumulLeft, cumulRight);
	 }
	 else if (q1 > q2) {//when some leading elements between cumulLeft and cumulRight have been retransmitted already
	   if (ack) { //ack
	     if (q1 != deFactoMaxTransmitCount && VQ[q1].size > 0)
	       move(q1, cumulLeft, VQ[q1].tail, deFactoMaxTransmitCount);
	     if (q1 > q2 + 1)
	       for (i = q1-1; i > q2; i--)
		 if (VQ[i].size > 0)
		   move(i, VQ[i].head, VQ[i].tail, deFactoMaxTransmitCount);
	     if (VQ[q2].size > 0)
	       move(q2, VQ[q2].head, cumulRight, deFactoMaxTransmitCount);
	   }
	   else { //nack
	     atomic dest = Q[cumulLeft].message.addr;
	     //process the leading elements in q2
	     if (VQ[q2].size > 0)
	       nack(dest, q, VQ[q2].head, cumulRight);
	     //process non-empty virtual queues between q2 and q1
	     if (q1 > q2 + 1)
	       for (i = q2+1; i < q1; i++)
		 if (VQ[i].size > 0)
		   nack(dest, i, VQ[i].head, VQ[i].tail);
	     //process the concluding elements in q1 
	     if (q1 != deFactoMaxTransmitCount && VQ[q1].size > 0) 
	       nack(dest, q1, cumulLeft, VQ[q1].tail);
	   }
	 }//end of q1 > q2
     } // end of "is ack or nack" 
     else if (frPos != ackLeft) //for stabilization
       move(q, frPos, frPos, deFactoMaxTransmitCount);

     dbg(DBG_SWITCH, "exiting ANaCK: \n");
   }//end of ANaCK(...)

   /* process explicit ack from base staions */
   void eANaCK(TOS_MsgPtr packet)
   {
     //uint8_t left;
     uint8_t k;
     Base_Ack_Msg * ackPtr;

     dbg(DBG_SWITCH, "begining of eANaCK \n");

     //atomic left = NULL8;
     for(k=aggregatedACK; k > 0; k--) {
       atomic ackPtr = (Base_Ack_Msg *)((k-1) * sizeof(Base_Ack_Msg) + packet->data);
       if (ackPtr->frAddr == TOS_LOCAL_ADDRESS
            //&& left != ackPtr->cumulLeft
           ) {
	 //dbg(DBG_SWITCH, "process %d th ack in the BASE-ACK\n", k);
	 //atomic left = ackPtr->cumulLeft;
	 ANaCK(ackPtr->frPos, ackPtr->frSeq, ackPtr->cumulLeft, ackPtr->cumulRight); 
       }
     } 

     dbg(DBG_SWITCH, "end of eANaCK \n");

   } //end of eANaCK(...) 
#endif //explicit ack

  /* for contention control */
  uint32_t rankAndWeight(uint8_t emptyElements1, uint8_t cvq1, uint8_t size1, uint16_t id1, uint8_t emptyElements2, uint8_t cvq2, uint8_t size2, uint16_t id2) 
  {
      if (cvq1 == NULL8 || size1 > SEND_QUEUE_SIZE)  //no packet to send or is to withdraw
	return 0;
      else if (emptyElements1 <= L1 && cvq1 == 0 && emptyElements2 > L1)
	return channelUtilizationGuard;
      else if (emptyElements2 <= L1 && cvq2 == 0 && emptyElements1 > L1)
	return 0;
      else if (cvq1 != NULL8 && cvq1 < cvq2) {
	if (channelUtilizationGuard > 1)
	  return (channelUtilizationGuard-1);
	else
	  return 1;
      }
      else if (cvq1 == NULL8 || cvq1 > cvq2)
	return 0;
      else if (size1 > size2) {
	if (channelUtilizationGuard > 2)
	  return (channelUtilizationGuard-2);
	else
	  return 1;
      }
      else if (size1 < size2)
	return 0;
      else if (id1 < id2) 
	return 1;
    /*
    bool rankHigher;
    uint32_t w1, w2;

    atomic{
      rankHigher = FALSE;
      if (cvq1 == NULL8 || size1 > SEND_QUEUE_SIZE)  //no packet to send or is to withdraw
	rankHigher = FALSE;
      else if (emptyElements1 <= L1 && cvq1 == 0 && emptyElements2 > L1)
	rankHigher = TRUE;
      else if (emptyElements2 <= L1 && cvq2 == 0 && emptyElements1 > L1)
	rankHigher = FALSE;
      else if (cvq1 != NULL8 && cvq1 < cvq2)
	rankHigher = TRUE;
      else if (cvq1 == NULL8 || cvq1 > cvq2)
	rankHigher = FALSE;
      else if (size1 > size2)
	rankHigher = TRUE;
      else if (size1 < size2)
	rankHigher = FALSE;
      else if (id1 < id2) 
	rankHigher = TRUE;
    } 
    if (rankHigher) {
      w1 = w2 = 0;
      //w1
      if (emptyElements1 < L2)
	w1 += ((L2-emptyElements1)<<(deFactoMaxTransmitCount+2));
      if (emptyElements1 < L1)
	w1 += ((L1-emptyElements1)<<(deFactoMaxTransmitCount+1));
      if (cvq1 != NULL8 && size1 != NULL8)
	w1 += (size1<<(deFactoMaxTransmitCount-cvq1));
      w1 = (1<<(deFactoMaxTransmitCount+CONTENTION_TOTAL_WEITGHT_part)) - w1;

      //w2
      if (emptyElements2 < L2)
	w2 += ((L2-emptyElements2)<<(deFactoMaxTransmitCount+2));
      if (emptyElements2 < L1)
	w2 += ((L1-emptyElements2)<<(deFactoMaxTransmitCount+1));
      if (cvq2 != NULL8 && size2 != NULL8) 
	w2 += (size2<<(deFactoMaxTransmitCount-cvq2));

      return (w1+w2);
    }
    else 
      return 0;
    */
  } //end of rankAndWeight(...) 

#ifndef EXPLICIT_ACK
  /* used in flowControl() */
  //Ver-1.1: reset ".resend" to 0 for corresponding packets with destination being the current parent 
  void resetQResend() 
  {
    uint8_t i, j;
    atomic {
      if ( cvq == 0)
	i = 1;
      else 
	i = cvq;
      while (i < deFactoMaxTransmitCount) {
	if (VQ[i].size == 0) {
	  i++;
	  continue;
	}

	j = VQ[i].head;
	while (Q[j].next != j && j < SEND_QUEUE_SIZE) {
	  if (Q[j].message.addr == lastDest)
	    Q[j].resend = 0;
	  j = Q[j].next;
	}
	if (Q[j].message.addr == lastDest && j < SEND_QUEUE_SIZE)
	  Q[j].resend = 0;

	i++;
      } //while
    }//atomic
  }//end of resetQResend() 
#endif //explicit ack

     /* flow control at non-base nodes */
   void flowControl(TOS_MsgPtr m)
   {

     uint8_t length;//, morePackets;
     uint8_t lastParentToSend;
     uint32_t weight, newContentionWait;
     ReliableComm_ProtocolMsg * RBCPtr;
#ifndef TOSSIM_SYSTIME
     timeSync_t currentTime;
#endif
     uint32_t clockReading;

#ifndef TOSSIM_SYSTIME
     call Time.getLocalTime(&currentTime);
     atomic clockReading = jiffiesToMilliseconds(&currentTime);
#else
     clockReading = (call SysTime.getTime32());
#endif
#ifndef EXPLICIT_ACK
     atomic lastReceive = clockReading;
#endif

     //never yeild to children, if self is congested
     if (m->addr == TOS_LOCAL_ADDRESS 
	 && VQ[deFactoMaxTransmitCount].size <= L1 //Ver-1.1
         )
       return;

#ifndef EXPLICIT_ACK
     //m is from the base parent: RETRANSMISSION control
     //if (m->addr == BASE_ACK_DEST_ID && lastDest == BASE_STATION_ID) {
     if (m->addr == BASE_ACK_DEST_ID && isBaseChild) { //echelon
       /*
       atomic{
	 pMtts = mtts;
	 //pToSend = aggregatedACK; //already done in sendPacket(...)
       }
       */
       return;
     }
#endif

     atomic{
       length = m->length - sizeof(ReliableComm_ProtocolMsg);
       RBCPtr = (ReliableComm_ProtocolMsg *)(length + m->data);
     }

     //m is from the non-base parent: RETRANSMISSION & CONGESTION control
     if (m->addr != BASE_ACK_DEST_ID && RBCPtr->myAddr == lastDest) {
       atomic{
	   //retransmission timer control
  	   pMtte = (RBCPtr->mtte)<<
#ifndef TOSSIM_SYSTIME
                                                                    compJIFFIES_PER_MILLISECOND
#else
                                                                     compSYSTIME_UNITS_PER_MILLISECOND
#endif
	     ;
	   pMtts = (RBCPtr->mtts)<<
#ifndef TOSSIM_SYSTIME
                                                                    compJIFFIES_PER_MILLISECOND
#else
                                                                     compSYSTIME_UNITS_PER_MILLISECOND
#endif
	     ;
	   lastParentToSend = pToSend;
       }
       if (RBCPtr->cvq != 0) {
	 atomic pToSend = 0;
#ifndef EXPLICIT_ACK
	 //Ver-1.1
	 if (cvq != NULL8)
	   resetQResend();
#endif
       }
       else if (RBCPtr->cvqSize <= SEND_QUEUE_SIZE)
	 atomic pToSend = RBCPtr->cvqSize;
       else 
	 atomic pToSend = RBCPtr->cvqSize - SEND_QUEUE_SIZE - 1;
	   
       atomic{
	   //pToSendDev estimation
	   if (pToSend >= lastParentToSend) 
	     pToSendDev = pToSendDev - (pToSendDev>>compDevPastW) + ((pToSend-lastParentToSend)>>compDevPastW); 
	   else  
	     pToSendDev = pToSendDev - (pToSendDev>>compDevPastW) + ((lastParentToSend-pToSend)>>compDevPastW); 
	   //pToSend estimation 
	   //pToSend = lastParentToSend - (lastParentToSend>>compPastW) + (pToSend>>compPastW); 
	   

	   //congestion control
	   if (RBCPtr->emptyElements <= SEND_QUEUE_SIZE) { //free space
	     lastParentSpace = parentSpace = RBCPtr->emptyElements;
	     parentSpaceDeadPeriod = ((SEND_QUEUE_SIZE - parentSpace)/2) *
#ifndef TOSSIM_SYSTIME
   	                                                                            (mtts>>compJIFFIES_PER_MILLISECOND);
#else
	                                                                            (mtts>>compSYSTIME_UNITS_PER_MILLISECOND);
#endif
	   }
	   if (RBCPtr->emptyElements <= L1 && RBCPtr->emptyElements > L2 && RBCPtr->cvq == 0) {//parent is congested
	     if (L1 - RBCPtr->emptyElements + 1 < RBCPtr->cvqSize)
	       pCongestWait = clockReading + ((RBCPtr->mtte)<<
#ifndef TOSSIM_SYSTIME
                                                                                                                     compJIFFIES_PER_MILLISECOND
#else
                                                                                                                     compSYSTIME_UNITS_PER_MILLISECOND
#endif
                                                                                  ) * (L1 - RBCPtr->emptyElements + 1);
	     else 
	       pCongestWait = clockReading + ((RBCPtr->mtte)<<
#ifndef TOSSIM_SYSTIME
                                                                                                                     compJIFFIES_PER_MILLISECOND
#else
                                                                                                                     compSYSTIME_UNITS_PER_MILLISECOND
#endif
				           ) * RBCPtr->cvqSize;
	   }

	   if (RBCPtr->emptyElements <= L2) { //parent is super-congested
	     pCongestWait = clockReading + ((RBCPtr->mtte)<<
#ifndef TOSSIM_SYSTIME
                                                                                                                     compJIFFIES_PER_MILLISECOND
#else
                                                                                                                     compSYSTIME_UNITS_PER_MILLISECOND
#endif
				          ) * (L1 - RBCPtr->emptyElements + 1);
	   }

	   if (pCongestWait != 0 && !(RBCPtr->emptyElements <= L1 && RBCPtr->cvq == 0) && RBCPtr->emptyElements > L2) //congestion relieved
	     pCongestWait = 0;
       }//atomic
     } //end of "retransmission and congestion control"

     //m is not a base-ack and I am not a non-base node: CONTENTION control
     //if (m->addr != BASE_ACK_DEST_ID && TOS_LOCAL_ADDRESS != BASE_STATION_ID) {
     if (m->addr != BASE_ACK_DEST_ID && ! isBase) { //echelon
	 if (RBCPtr->cvqSize > SEND_QUEUE_SIZE) { //is to WD
	   if (RBCPtr->myAddr == highestRankedNode) {
	     atomic {
	       contentionWait = 0;
	       highestRankedNode = NULL16;
	     }
	   }
	   return;
	 }
	 weight = rankAndWeight(RBCPtr->emptyElements, RBCPtr->cvq, RBCPtr->cvqSize, RBCPtr->myAddr, VQ[deFactoMaxTransmitCount].size, cvq, cvq > deFactoMaxTransmitCount ? 0 : VQ[cvq].size, TOS_LOCAL_ADDRESS);
	 if (weight == 0) {
	   //Ver-1.0: bug fix
	   atomic {
	     if (contentionWait > 0 && RBCPtr->myAddr == highestRankedNode) {
	       contentionWait = 0;
	       highestRankedNode = NULL16;
	     }
	   }  //atomic
	   return;
	 }
	 else {
	   atomic newContentionWait = clockReading + weight * ((RBCPtr->mtts)<<(
#ifndef TOSSIM_SYSTIME
                                                                                                         compJIFFIES_PER_MILLISECOND)
#else
                                                                                                         compSYSTIME_UNITS_PER_MILLISECOND)
#endif
 	                                                                                                       );
                      if (newContentionWait > contentionWait) {
			contentionWait = newContentionWait;
			highestRankedNode = RBCPtr->myAddr;
	    }
	 }
       }
       /*old
      {
       atomic{
	 //reset highestRanked when there is no contentionWaiting anymore
	 if (highestRanked.node_id != NULL16 && highestRanked.contentionWait <= clockReading) {
	   highestRanked.node_id = NULL16;
	   highestRanked.emptyLen = 	highestRanked.cvq = highestRanked.size = NULL8;
	   highestRanked.contentionWait = 0;
	 }

	 if (RBCPtr->myAddr == highestRanked.node_id 
                        && RBCPtr->cvqSize <= SEND_QUEUE_SIZE 
                        && secondHighest.node_id == TOS_LOCAL_ADDRESS) {//self is second-higest ranked
	   secondHighest.contMonitorW = clockReading + ((RBCPtr->mtts)<<(
#ifndef TOSSIM_SYSTIME
                                                                                                                                                 compJIFFIES_PER_MILLISECOND));
#else
                                                                                                                                                 compSYSTIME_UNITS_PER_MILLISECOND));
#endif
	 }
       }//atomic
     
       //if the sending node is going to WD
       if (RBCPtr->cvqSize > SEND_QUEUE_SIZE) {
	 atomic{
	   if (RBCPtr->myAddr == highestRanked.node_id) { //the node is the highest ranked
	     if (secondHighest.node_id == TOS_LOCAL_ADDRESS || secondHighest.contMonitorW <= clockReading ) {
	       highestRanked.node_id = secondHighest.node_id = NULL16;
	       highestRanked.contentionWait = secondHighest.contMonitorW = 0;
	       highestRanked.emptyLen = highestRanked.cvq = highestRanked.size = NULL8;
	       secondHighest.emptyLen = secondHighest.cvq = secondHighest.size = NULL8;
	     }
	     else { //self is not second-highest, and the second-highest is still alive
	       highestRanked.node_id = secondHighest.node_id;
	       highestRanked.emptyLen = secondHighest.emptyLen;
	       highestRanked.cvq = secondHighest.cvq;
	       highestRanked.size = secondHighest.size;
	       highestRanked.contentionWait = secondHighest.contMonitorW;
	       secondHighest.node_id = TOS_LOCAL_ADDRESS;
	       secondHighest.emptyLen = VQ[deFactoMaxTransmitCount].size;
	       secondHighest.cvq = cvq;
	       secondHighest.size = (cvq > deFactoMaxTransmitCount ? 0 : VQ[cvq].size);
	       secondHighest.contMonitorW = clockReading + mtts;
	     }
	   }
	   else if (RBCPtr->myAddr == secondHighest.node_id) { //the node is the second highest ranked
	     secondHighest.node_id = TOS_LOCAL_ADDRESS;
	       secondHighest.emptyLen = VQ[deFactoMaxTransmitCount].size;
	       secondHighest.cvq = cvq;
	       secondHighest.size = (cvq > deFactoMaxTransmitCount ? 0 : VQ[cvq].size);
	     secondHighest.contMonitorW = clockReading + mtts;
	   }
	 }
	 
	 return;
       } //the sending node is to WD

       //consider this node as a contender and act upon it
       if (rankHigher(RBCPtr->emptyElements, RBCPtr->cvq, RBCPtr->cvqSize, RBCPtr->myAddr, VQ[deFactoMaxTransmitCount].size, cvq, cvq > deFactoMaxTransmitCount ? 0 : VQ[cvq].size, TOS_LOCAL_ADDRESS)) {
	 morePackets = pktsMore(RBCPtr->emptyElements, RBCPtr->cvq, RBCPtr->cvqSize, VQ[deFactoMaxTransmitCount].size, cvq, cvq > deFactoMaxTransmitCount ? 0 : VQ[cvq].size);

	 atomic{
	   if (toWD)
	     toWD = FALSE;

	   //the sending node is the highest ranked
	   if (highestRanked.node_id == NULL16 || highestRanked.node_id == RBCPtr->myAddr) {
	     if (highestRanked.node_id == NULL16) {
	       highestRanked.node_id = RBCPtr->myAddr;
	       highestRanked.emptyLen = RBCPtr->emptyElements;
	       highestRanked.cvq = RBCPtr->cvq;
	       highestRanked.size = RBCPtr->cvqSize;
	       secondHighest.node_id = TOS_LOCAL_ADDRESS;
	       secondHighest.emptyLen = VQ[deFactoMaxTransmitCount].size;
	       secondHighest.cvq = cvq;
	       secondHighest.size = (cvq > deFactoMaxTransmitCount ? 0 : VQ[cvq].size);
	       secondHighest.contMonitorW = clockReading + ((RBCPtr->mtts)<<
#ifndef TOSSIM_SYSTIME
						         compJIFFIES_PER_MILLISECOND);
#else
                                                                                                                     compSYSTIME_UNITS_PER_MILLISECOND);
#endif
	     }
   	     highestRanked.contentionWait = clockReading + (morePackets * ((RBCPtr->mtts)<<
#ifndef TOSSIM_SYSTIME
							                compJIFFIES_PER_MILLISECOND));
#else
	                                                                                                                            compSYSTIME_UNITS_PER_MILLISECOND));
#endif
	   }
                     //the sending node is to be the highest ranked, i.e., ranks higher than highestRanked.node_id
	   else if (rankHigher(RBCPtr->emptyElements, RBCPtr->cvq, RBCPtr->cvqSize, RBCPtr->myAddr, highestRanked.emptyLen, highestRanked.cvq, highestRanked.size, highestRanked.node_id)){
                       secondHighest.node_id = highestRanked.node_id;
                       secondHighest.emptyLen = highestRanked.emptyLen;
                       secondHighest.cvq = highestRanked.cvq;
                       secondHighest.size = highestRanked.size;
	     secondHighest.contMonitorW = highestRanked.contentionWait;
	     highestRanked.node_id = RBCPtr->myAddr;
	     highestRanked.emptyLen = RBCPtr->emptyElements;
	     highestRanked.cvq = RBCPtr->cvq;
	     highestRanked.size = RBCPtr->cvqSize;
  	     highestRanked.contentionWait = clockReading + (morePackets * ((RBCPtr->mtts)<<
#ifndef TOSSIM_SYSTIME
	                                                                                                                             compJIFFIES_PER_MILLISECOND));
#else
                                                                                                                                               compSYSTIME_UNITS_PER_MILLISECOND));
#endif
	 }
                    // is the second highest ranked
                    else if (secondHighest.node_id == NULL16 || secondHighest.node_id == RBCPtr->myAddr 
                                  || secondHighest.contMonitorW <= clockReading){
                       if (secondHighest.node_id == NULL16) {
 	        secondHighest.node_id = RBCPtr->myAddr;
	        secondHighest.emptyLen = RBCPtr->emptyElements;
	        secondHighest.cvq = RBCPtr->cvq;
	        secondHighest.size = RBCPtr->cvqSize;
                       }
	     secondHighest.contMonitorW = clockReading + (morePackets * ((RBCPtr->mtts)<<
#ifndef TOSSIM_SYSTIME
						         compJIFFIES_PER_MILLISECOND));
#else
                                                                                                                     compSYSTIME_UNITS_PER_MILLISECOND));
#endif
	 }
                   //is to be the second highest ranked
                   else if (rankHigher(RBCPtr->emptyElements, RBCPtr->cvq, RBCPtr->cvqSize, RBCPtr->myAddr, highestRanked.emptyLen, highestRanked.cvq, highestRanked.size, highestRanked.node_id)){
                      secondHighest.node_id = RBCPtr->myAddr;
                      secondHighest.emptyLen = RBCPtr->emptyElements;
	    secondHighest.cvq = RBCPtr->cvq;
	    secondHighest.size = RBCPtr->cvqSize;
	    secondHighest.contMonitorW = clockReading + (morePackets * ((RBCPtr->mtts)<<
#ifndef TOSSIM_SYSTIME
						         compJIFFIES_PER_MILLISECOND));
#else
                                                                                                                     compSYSTIME_UNITS_PER_MILLISECOND));
#endif
                   }
              }//atomic
       }//rankHigher
       else if (cvq != NULL8 && highestRanked.node_id == NULL8 && highestRanked.contentionWait <= clockReading) //check to see if need to withdraw next slot
	 if (pktsMore(VQ[deFactoMaxTransmitCount].size, cvq, cvq > deFactoMaxTransmitCount ? 0 : VQ[cvq].size, RBCPtr->emptyElements, RBCPtr->cvq, RBCPtr->cvqSize) <= 1)
	   atomic toWD = TRUE;
	 else if (toWD)
	   atomic toWD = FALSE;
     }//end of contention control 
       */
   } //end of flowControl(...) 

#ifdef INTEGRITY_CHECKING
   void queueChecking()
   {
      uint8_t aliveElements, i, p, count;
 
      dbg(DBG_SWITCH2, "to check queue\n");

     //check total # of elements still accessible by VQ
     aliveElements = 0;
     for (i=0; i <= deFactoMaxTransmitCount; i++)
       aliveElements += VQ[i].size;
     if (aliveElements == SEND_QUEUE_SIZE)
       dbg(DBG_SWITCH2, "aliveElements: OK\n");
     else if (aliveElements < SEND_QUEUE_SIZE)
       dbg(DBG_SWITCH2, "aliveElements: corrupted --> LOST ???\n");
     else 
       dbg(DBG_SWITCH2, "aliveElements: corrupted -- >EXCEEDING !!!\n");

     //check the integrity of each VQ
     for (i=0; i <= deFactoMaxTransmitCount; i++) 
       if (VQ[i].size == 0 && (VQ[i].head != NULL8 || VQ[i].tail != NULL8))
	 dbg(DBG_SWITCH2, "VQ[%d]: corrupted --> .head and .tail are NOT NULL8 when .size = 0\n", i);
       else if (VQ[i].size == 0)
	 dbg(DBG_SWITCH2, "VQ[%d]: OK\n", i);
       else {
	 p = VQ[i].head;
	 count = 1;
	 while (p != VQ[i].tail) {
                     if (Q[p].next != p && Q[Q[p].next].prev != p)
	      dbg(DBG_SWITCH2, "corrupted --> Q[%d].next and Q[%d].prev does not match\n", p, Q[p].next);
	   if (p != Q[p].next && Q[p].next < SEND_QUEUE_SIZE) {
	     p = Q[p].next;
	     count++;
	   }
	   else {
	     if (p == Q[p].next)
	       dbg(DBG_SWITCH2, "VQ[%d]: corrupted -- > .tail (i.e., Q[%d]) is gone ???\n", i, VQ[i].tail);
	     if (Q[p].next >= SEND_QUEUE_SIZE)
	       dbg(DBG_SWITCH2, "VQ[%d]: corrupted --> Q[%d].next corrupted (>= SEND_QUEUE_SIZE)\n", i, p);
	     break;
                     }
	 }//while()
	 if (p == VQ[i].tail && count == VQ[i].size && Q[VQ[i].head].prev == VQ[i].head && Q[VQ[i].tail].next == VQ[i].tail)
	   dbg(DBG_SWITCH2, "VQ[%d]: OK\n", i);
	 else {
	   if (count < VQ[i].size)
	     dbg(DBG_SWITCH2, "VQ[%d]: corrupted --> some LOST ???\n", i);
	   if (count > VQ[i].size)
	     dbg(DBG_SWITCH2, "VQ[%d]: corrupted --> EXCEEDS !!!\n", i);
	   if (Q[VQ[i].head].prev != VQ[i].head)
	     dbg(DBG_SWITCH2, "VQ[%d]: corrupted --> .prev of .head CORRUPTED\n", i);
	   if (Q[VQ[i].tail].next != VQ[i].tail)
	     dbg(DBG_SWITCH2, "VQ[%d]: corrupted --> .next of .tail CORRUPTED\n", i);
	 }
       }      
     dbg(DBG_SWITCH2, "checking done\n")
   } //end of queueChecking()
#endif



  ///**********************************************************
  //* exported interface functions
  //**********************************************************/

  command result_t StdControl.init() {
     int i, j;

    atomic{
      Q[0].seq = 0; 
      Q[0].prev = 0;
      Q[0].next = 1;

      for (i = 1; i < SEND_QUEUE_SIZE-1; i++) {
	Q[i].seq = 0;
	Q[i].prev = i-1;
	Q[i].next = i+1;
      }
      Q[SEND_QUEUE_SIZE-1].seq = 0;
      Q[SEND_QUEUE_SIZE-1].prev = SEND_QUEUE_SIZE-2;
      Q[SEND_QUEUE_SIZE-1].next = SEND_QUEUE_SIZE-1;
    } //end of atomic
    atomic {
      pending = FALSE;
      uartPending = FALSE;
      uartWritePtr = uartReadPtr = NUM_BASE_ACK_BUFFERS;
    }

    atomic{
      deFactoTransmissionPower = DefaultTransmissionPower;
      deFactoMaxTransmitCount = firstMaxTransmitCount;

      for (i =0; i <= MAX_TRANSMIT_COUNT; i++) {
	VQ[i].size = 0;
	VQ[i].head = NULL8;
	VQ[i].tail = NULL8;
      }
      VQ[deFactoMaxTransmitCount].size = SEND_QUEUE_SIZE;
      VQ[deFactoMaxTransmitCount].head = 0;
      VQ[deFactoMaxTransmitCount].tail = SEND_QUEUE_SIZE - 1;
      cvq = NULL8;
    }

    atomic {
      for (i =0; i < MAX_NUM_CHILDREN; i++) {
	children[i].node_id = NULL16;
	for (j=0; j < SEND_QUEUE_SIZE; j++)
	  children[i].lastSeq[j] = NULL8;
#ifndef EXPLICIT_ACK
	children[i].ackLeft =  children[i].lastPos = children[i].expect0 =  children[i].expect1 = NULL8;
#endif
      }
      numImNghs = 0;
#ifndef EXPLICIT_ACK
      ackLeft = NULL8;
#endif
    }

   atomic {
      toSnoop = FALSE;
      isBase = FALSE;
      isBaseChild = FALSE;
   }
 
    atomic {
      lastDest = NULL16;
#ifndef EXPLICIT_ACK
      acceptBaseAck = FALSE;
#endif
    }

    atomic {
      pToSend = 0;
      pToSendDev = PARENT_TO_SEND_DEV;
      pMtte = mtte = MTTE<<
#ifndef TOSSIM_SYSTIME
                                                  compJIFFIES_PER_MILLISECOND;
#else
                                                  compSYSTIME_UNITS_PER_MILLISECOND;
#endif
      mtteDev = MTTE_DEV;
      pMtts = mtts = MTTS<<
#ifndef TOSSIM_SYSTIME
                                                  compJIFFIES_PER_MILLISECOND;
#else
                                                  compSYSTIME_UNITS_PER_MILLISECOND;
#endif
      mttsDev = MTTS_DEV;
      mtte0 = mtts0 = 0;
    }

    atomic{
      parentSpace = INIT_PARENT_SPACE;
      parentSpaceDeadPeriod = 0;
      pCongestWait = 0;
    }

    atomic{
      toWD = FALSE;
      contentionWait = 0;
      highestRankedNode = NULL16;
      /*
      highestRanked.node_id = NULL16;
      highestRanked.emptyLen = highestRanked.cvq =  highestRanked.size = NULL8;
      highestRanked.contentionWait = 0;
      secondHighest.node_id = NULL16;
      secondHighest.emptyLen = secondHighest.cvq =  secondHighest.size = NULL8;
      secondHighest.contMonitorW = 0;
      */
    }

#ifndef EXPLICIT_ACK
    atomic{
      nAck = 0;
      lastReceive = 0;
      sendAckPtr = storeAckPtr = 0;
    }
#endif

    atomic{
      baseAckDeadCount = 0;
      pendingDeadPeriod = 0;
    }

#ifdef CALCULATE_LOG
    //Log
    atomic{
      logPtr = (ReliableComm_Reflector *)log;

      //isWritingLog=stateLogged = FALSE;
      //sinceLastLogging = 0;
      //writingLogDeadCount = 0;

      logPtr->myID = TOS_LOCAL_ADDRESS;

      logPtr->queueLength = 0;
      logPtr->queueOverflowCount = 0;
      logPtr->otherQueueOverflowCount = 0;

      logPtr->totalSendsCalled = 0;
      logPtr->totalPacketsSent = 0;
      //logPtr->maxRetransmitFailureCount = 0;
      //logPtr->otherMaxRetransmitFailureCount = 0;
      logPtr->tripleTried = 0;
      logPtr->twiceTried = 0;
      logPtr->delayedACK = 0;
      for (i=0; i < MAX_NUM_PARENTS; i++) {
        logPtr->linkSending[i].node_id = NULL8;
        logPtr->linkSending[i].totalSendsCalled = 0;
        logPtr->linkSending[i].totalPacketsSent = 0;
      }

      logPtr->totalPacketsReceived = 0;
      logPtr->receivedDuplicates = 0;
      for (i=0; i < MAX_NUM_CHILDREN; i++) {
        logPtr->linkReception[i].node_id = NULL8;
        logPtr->linkReception[i].totalPacketsReceived = 0;
        logPtr->linkReception[i].receivedDuplicates = 0;
      }

      logPtr->type1 = 1;
      logPtr->type2 = 2;
      /*
      logPtr->type3 = 3;
      logPtr->child1ID = logPtr->child2ID = logPtr->child3ID = logPtr->child4ID = 0;
      logPtr->totalPacketsFromChild1 = logPtr->totalPacketsFromChild2 = logPtr->totalPacketsFromChild3 = logPtr->totalPacketsFromChild4 = 0;
      logPtr->duplicatesFromChild1 = logPtr->duplicatesFromChild2 = logPtr->duplicatesFromChild3 = logPtr->duplicatesFromChild4 = 0;
      */
    }//end of atomic
#endif
#ifdef INTEGRITY_CHECKING
    overFlows = reTranxits = 0;
#endif
#ifdef LOG_STATE
    call MatchboxControl.init();
#endif
    call UARTControl.init();
#ifndef TOSSIM_SYSTIME
    return rcombine4(call RadioControl.init(), call TsyncControl.init(), call TimerControl.init(), call Leds.init()); 
#else
    return rcombine3(call RadioControl.init(), call TimerControl.init(), call Leds.init()); 
#endif
  }

  command result_t StdControl.start() {
#ifndef EXPLICIT_ACK
    uint8_t i;
    //for baseAck
    //if (TOS_LOCAL_ADDRESS == BASE_STATION_ID)
    if (isBase) //echelon
      for (i=0; i < SEND_QUEUE_SIZE; i++) {
	Q[i].message.addr = BASE_ACK_DEST_ID;
	Q[i].message.length = aggregatedACK * sizeof(Base_Ack_Msg);
	Q[i].message.group = TOS_AM_GROUP;
      }
#endif
#ifdef LOG_STATE
    call MatchboxControl.start();
#endif
#ifndef TOSSIM_SYSTIME
    call CC1000Control.SetRFPower(deFactoTransmissionPower);
#ifdef USE_MacControl
    call MacControl.disableAck();
#endif
    call UARTControl.start();
    return rcombine4(call RadioControl.start(), call TsyncControl.start(), call TimerControl.start(), call Timer.start(TIMER_REPEAT, Timer_Interval)); 
#else
    return rcombine3(call RadioControl.start(), call TimerControl.start(), call Timer.start(TIMER_REPEAT, Timer_Interval)); 
#endif
  }

  command result_t StdControl.stop() {
#ifdef LOG_STATE
    call MatchboxControl.stop();
#endif
    call UARTControl.stop();
#ifndef TOSSIM_SYSTIME
    return rcombine3(call RadioControl.stop(), call TsyncControl.stop(), call TimerControl.stop()); 
#else
    return rcombine(call RadioControl.stop(), call TimerControl.stop()); 
#endif
  }

  default event result_t ReliableSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
  default event TOS_MsgPtr ReliableReceiveMsg.receive[uint8_t id](TOS_MsgPtr m) {
    return NULL;
  }

  /* set to snoop or not*/
  command result_t ReliableCommControl.setSnooping(bool snoop)
  {
    atomic toSnoop = snoop;
    return SUCCESS;
  }

  /* command to set a node to be a base station or otherwise */
  command result_t ReliableCommControl.setBase(bool isABase)
  {
      atomic isBase = isABase;
      return SUCCESS;
  }  

  /* command to set whether a node is a child of a base station or not */
  command result_t ReliableCommControl.setBaseChildren(bool isABaseChild)
  {
      atomic isBaseChild = isABaseChild;
      return SUCCESS;
  }


  /* parameter tuning */
  command result_t ReliableCommControl.parameterTuning(ReliableComm_Tuning_Msg * tuningMsgPtr) 
  {
    parameterTuningImpl(tuningMsgPtr);
    return SUCCESS;
  }



  /**  command for sending a packet **/
  command result_t ReliableSendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg)
  {
#ifndef EXPLICIT_ACK
    ReliableComm_ProtocolMsg * RBCPtr;
#endif
    bool successEnqueue;
#ifdef CALCULATE_LOG
uint8_t j;
#endif

    //dbg(DBG_SWITCH, "ReliableSendMsg.send(): to queue msg\n");

#ifdef CALCULATE_LOG
    //Log: total sends called
    atomic {
                  (logPtr->totalSendsCalled)++;
	j = 0;
	while (j < MAX_NUM_PARENTS && 
                              logPtr->linkSending[j].node_id != NULL8 && 
 	            logPtr->linkSending[j].node_id != (uint8_t)(address&0x00ff))
	  j++;
	if (j < MAX_NUM_PARENTS && logPtr->linkSending[j].node_id == NULL8)
	  logPtr->linkSending[j].node_id = (uint8_t)(address&0x00ff);
	if (j < MAX_NUM_PARENTS)
	  (logPtr->linkSending[j].totalSendsCalled)++;
    }
    //Log: check average queue length
    atomic logPtr->queueLength =  ((logPtr->queueLength * ((logPtr->totalSendsCalled-1) > 0 ? (logPtr->totalSendsCalled-1) : 0)) +  (SEND_QUEUE_SIZE - VQ[deFactoMaxTransmitCount].size))/logPtr->totalSendsCalled;
#endif

    //for base station: send to UART without retransmission only
    //if (TOS_LOCAL_ADDRESS == BASE_STATION_ID) {
    if (isBase) { //echelon
      if ((uartWritePtr == (SEND_QUEUE_SIZE-1) && uartReadPtr == NUM_BASE_ACK_BUFFERS) ||  //queue overflows
           (uartWritePtr != (SEND_QUEUE_SIZE-1) && uartWritePtr == (uartReadPtr - 1))
          ) {
#ifdef CALCULATE_LOG
        //Log: calculate queueOverflowCount 
        atomic ++(logPtr->queueOverflowCount);
#endif
        signal ReliableSendMsg.sendDone[id](msg, FAIL);
        return FAIL;
      }
      enqueueBase(address, length, msg, id);
      if (toUart()) {
          atomic{
	    pending = TRUE;
	    uartPendingDeadPeriod = 0;
	  }
           post sendUart();
     }
     signal ReliableSendMsg.sendDone[id](msg, SUCCESS);
     return SUCCESS;
   } //is base station

    //if is a non-base node, but queue overflows
    if (VQ[deFactoMaxTransmitCount].size == 0) {//no free queue pos
#ifdef CALCULATE_LOG
      //Log: calculate queueOverflowCount 
      atomic {
	++(logPtr->queueOverflowCount);
	if ((uint8_t)msg->data[length] == 0xff && (uint8_t)msg->data[length+1] == 0xff) //packets are locally generated
	  logPtr->otherQueueOverflowCount++;
      }
#endif
#ifdef INTEGRITY_CHECKING
      overFlows++;
      dbg(DBG_SWITCH3, "%d queue overflows\n", overFlows);
#endif
      signal ReliableSendMsg.sendDone[id](msg, FAIL);
      return FAIL;
    }

#ifndef EXPLICIT_ACK
    atomic{
      if ((uint8_t)msg->data[length] == 0xff && (uint8_t)msg->data[length+1] == 0xff) {//packets are locally generated
	RBCPtr = (ReliableComm_ProtocolMsg *)(length + msg->data);
	RBCPtr->frAddr = TOS_LOCAL_ADDRESS;
	RBCPtr->frPos = RBCPtr->frSeq = RBCPtr->cumulLeft = RBCPtr->cumulRight = NULL8;
#ifdef CALCULATE_LOG
	//Log: topology visualization information 
	//logPtr->myParentID = address;
#endif
      }
    }//atomic
#endif

    // get an empty queue position, if any, to store msg, and then append it to the end of Q[0]
    dbg(DBG_SWITCH2, "to enter ENQUEUE(...)\n");
    successEnqueue = enqueue(address, length, msg, id);
    dbg(DBG_SWITCH2, "exited from ENQUEUE(...)\n");
#ifdef INTEGRITY_CHECKING
    queueChecking();
#endif
    
    // Try to send next message, if any 
    if (toSend()) {
          dbg(DBG_SWITCH, "ReliableSendMsg.send(): time to send out a new packet\n");

          atomic{
	    pending = TRUE;
	    pendingDeadPeriod = 0;
	  }
          dbg(DBG_SWITCH2, "to enter sendPacket()\n");
          post sendPacket();
          dbg(DBG_SWITCH2, "exited from sendPacket()\n");
    }

    if (successEnqueue) {
      signal ReliableSendMsg.sendDone[id](msg, SUCCESS);
      return SUCCESS;
    }
    else {
       signal ReliableSendMsg.sendDone[id](msg, FAIL);
       return FAIL;
    }
  } //end of ReliableSendMsg.send(...)


  /** process a sendDone event  **/
   event result_t RadioBareSend.sendDone(TOS_MsgPtr msg, result_t success) 
  {
    if (msg->type < HANDLER_ID_LOWER_BOUND ||
         msg->type > HANDLER_ID_UPPER_BOUND)     //the packet does not belong to ReliableComm
      return SUCCESS;
    else {//the packet does belong to ReliableComm
        //if (TOS_LOCAL_ADDRESS != BASE_STATION_ID && msg != &(Q[lastSendPtr].message)) {
       if (! isBase && msg != &(Q[lastSendPtr].message)) { //echelon
                     atomic pending = FALSE;
	 return SUCCESS;
       }

       post sendDoneProcessing();
    }

    return SUCCESS;
  } //end of processing sendDone event


  /** process a uartSendDone event  **/
  //event result_t UARTBareSend.sendDone(TOS_MsgPtr msg, result_t success)
  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success)
  {
     //if it is for logToUart
     if (msg == &(Q[0].message)) {
       //call UARTBareSend.send(&(Q[1].message));
       call UARTSend.send(TOS_UART_ADDR, Q[1].message.length, &(Q[1].message));
       return SUCCESS;
     }
     else if (msg == &(Q[1].message))
       return SUCCESS;

     //is for queued uart communication
     atomic uartPending = FALSE;
     post uartSendDoneProcessing();
     return SUCCESS;
  } //end of processing uartSendDone event


   /** process a received packet **/
   event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr packet)
  {
#ifndef EXPLICIT_ACK
    uint8_t length;
    uint16_t   frAddr; 
    uint8_t    frPos, frSeq, cumulLeft, cumulRight;
    ReliableComm_ProtocolMsg * RBCPtr;
#endif
    //ReliableComm_Tuning_Msg * tuningMsgPtr;

#ifdef TOSSIM_SYSTIME
    //uint8_t i;
    dbg(DBG_SWITCH, "A new packet is received: \naddr = %d, type = %d, group = %d, length = %d,  data[] =\n", packet->addr, packet->type, packet->group, packet->length);
    //for (i = 0; i < packet->length; i++)
    //  dbg(DBG_SWITCH, "%X \n", (uint8_t)packet->data[i]);
#endif

    //tuning parameters
    /* obsolete
    if (packet->crc  && 
         packet->group == TOS_AM_GROUP && 
         packet->type == ReliableComm_Tuning_Handler && 
         packet->addr == ReliableComm_Tuning_Addr) {

      tuningMsgPtr = (ReliableComm_Tuning_Msg *)(packet->data); 
      if (tuningMsgPtr->transmissionPower > 0 && tuningMsgPtr->maxTransmitCount > 0) {
	call Leds.yellowToggle();
	call Leds.greenToggle();
	call Leds.redToggle();
	parameterTuningImpl(tuningMsgPtr);
      }
      else {
	call Leds.redToggle();
	call Leds.greenToggle();
	call Leds.yellowToggle();
      }
      return packet;
    } //end of parameter-tuning
    */

#ifdef CALCULATE_LOG
    /* obsolete
    //Log state
    if (packet->crc  && 
         packet->group == TOS_AM_GROUP && 
         packet->type == ReliableComm_Log_Handler && 
         packet->addr == ReliableComm_Log_Addr &&
         stateLogged == FALSE) {
     uint16_t tp;
     atomic{
       stateLogged = TRUE;
       sinceLastLogging = 0;
     }
      //log state here
      if (isWritingLog == FALSE || writingLogDeadCount >= MAX_WRITING_LOG_DEAD_COUNT) {
	atomic{
	  for (tp=0; tp < LOG_RECORD_SIZE; tp++)
	    logCopy[tp] = log[tp];
	  writingLogDeadCount = 0;
	  isWritingLog = TRUE;
	}
	if (call DataLogger.writelogData(logCopy, LOG_LENGTH)) {//success 
	  call Leds.greenToggle();
	  call Leds.yellowToggle();
	  call Leds.redToggle();
	} 
	else { //fail 
	  isWritingLog = FALSE; 
	  call Leds.redToggle();
	  call Leds.yellowToggle();
	  call Leds.greenToggle();
	}
      }
      else 
	atomic writingLogDeadCount++;
      return packet;
    }  //end of state-logging
    */
#endif
    
    //if packets are not for ReliableComm
    if (!(packet->crc) || 
         packet->group != TOS_AM_GROUP || 
         packet->type < HANDLER_ID_LOWER_BOUND ||
         packet->type > HANDLER_ID_UPPER_BOUND)
      return packet;

    /*process packets of ReliableComm */
    if (packet->addr == TOS_LOCAL_ADDRESS) { //receive a new message 
      accept(packet);
    }
#ifndef EXPLICIT_ACK
    else if (deFactoMaxTransmitCount > 1 && //snooping for implicit acknowledgement from non-base node
                  //TOS_LOCAL_ADDRESS != BASE_STATION_ID && 
                  ! isBase &&  //echelon
                  packet->addr != BASE_ACK_DEST_ID) { 
      atomic{
	length = packet->length - sizeof(ReliableComm_ProtocolMsg);
	RBCPtr = (ReliableComm_ProtocolMsg *)(length + packet->data);

	frAddr = RBCPtr->frAddr;
	frPos = RBCPtr->frPos;
	frSeq =  RBCPtr->frSeq;
	cumulLeft = RBCPtr->cumulLeft;
	cumulRight = RBCPtr->cumulRight;
      } //atomic

      if (frAddr == TOS_LOCAL_ADDRESS) {
	dbg(DBG_SWITCH, "ANaCK: frPos = %d,  frSeq = %d,  cumulLeft = %d,  cumulRight = %d\n", frPos, frSeq, cumulLeft, cumulRight);
	dbg(DBG_SWITCH2, "to enter ANaCK(...)\n");
	ANaCK(frPos, frSeq, cumulLeft, cumulRight);
	dbg(DBG_SWITCH2, "exited from ANaCK(...)\n");
#ifdef INTEGRITY_CHECKING
	queueChecking();
#endif
      }
    }
    else if (deFactoMaxTransmitCount > 1 && //snooping for explicit acknowledgement from base station(s)
                 packet->addr == BASE_ACK_DEST_ID &&
                 acceptBaseAck &&
                 //TOS_LOCAL_ADDRESS != BASE_STATION_ID
                 ! isBase //echelon
                ) { 
      dbg(DBG_SWITCH2, "to enter eANaCK(...)\n");
      eANaCK(packet);
      dbg(DBG_SWITCH2, "exited from eANaCK(...)\n");
#ifdef INTEGRITY_CHECKING
      queueChecking();
#endif
    }
#endif //explicit ack

    //flow control for non-base node 
    //if (TOS_LOCAL_ADDRESS != BASE_STATION_ID) {
    if (! isBase) { //echelon
      flowControl(packet);
    }

    //for packet snooping
    if (packet->addr != TOS_LOCAL_ADDRESS && toSnoop) {
      atomic packet->length = packet->length - sizeof(ReliableComm_ProtocolMsg);
      signal ReliableReceiveMsg.receive[packet->type](packet);
    }

    return packet;
  } //end of receive() 


  event result_t Timer.fired()
  {
    /*
#ifndef TOSSIM_SYSTIME
    timeSync_t currentTime;
#endif
    uint32_t clockReading;
    */

     /* Add self-stabilization from got-stuck: for "pending"-variable
      */  
    //1) stabilize "pending"
    atomic{
      if (pending) {
	pendingDeadPeriod += Timer_Interval;
	if (pendingDeadPeriod >= NonBasePendingDeadThreshold) {
                    dbg(DBG_SWITCH2, "stabilize pending\n");
	  pending = FALSE;
	  baseAckDeadCount = 0;
	}
      }
    }
    //2) stabilize "parentSpace"
    atomic{
        //if (parentSpace == 0 && cvq != NULL8 && lastDest != BASE_STATION_ID) {
        if (parentSpace == 0 && cvq != NULL8 && ! isBaseChild) { //echelon
	if (parentSpaceDeadPeriod > Timer_Interval)
	  parentSpaceDeadPeriod -= Timer_Interval;
	else {
                    dbg(DBG_SWITCH3, "stabilize parentSpace\n");
                    parentSpace = lastParentSpace>>1;
                    if (parentSpace < STABILIZE_PARENT_SPACE)
		      parentSpace = STABILIZE_PARENT_SPACE;
                    parentSpaceDeadPeriod =  ((SEND_QUEUE_SIZE - parentSpace)/2) *
#ifndef TOSSIM_SYSTIME
   	                                                                            (mtts>>compJIFFIES_PER_MILLISECOND);
#else
	                                                                            (mtts>>compSYSTIME_UNITS_PER_MILLISECOND);
#endif
	}
      }
    }
    //3) stabilize "uartPending"
    atomic{
      if (uartPending) {
	uartPendingDeadPeriod += Timer_Interval;
	if (uartPendingDeadPeriod >= NonBasePendingDeadThreshold) {
                    dbg(DBG_SWITCH2, "stabilize pending\n");
	  uartPending = FALSE;
	}
      }
    }
#ifdef LOG_STATE
    //4) stabilize "logging"
    /* obsolete
    //log state
    atomic{
      if (stateLogged)
	sinceLastLogging += Timer_Interval;
      //sinceLastLogging++;
      if (stateLogged == TRUE && sinceLastLogging > Min_Log_Interval) {
	stateLogged = FALSE;
	sinceLastLogging = 0;
      }
    }//atomic
    */
#endif


    //maintain secondHighest of contention-control
    /*
    if (highestRanked.contentionWait != 0 && secondHighest.node_id != TOS_LOCAL_ADDRESS) {
#ifndef TOSSIM_SYSTIME
      call Time.getLocalTime(&currentTime);
      atomic clockReading = jiffiesToMilliseconds(&currentTime);
#else
      clockReading = (call SysTime.getTime32());
#endif
      atomic{
	if (secondHighest.contMonitorW <= clockReading){
	  secondHighest.node_id = TOS_LOCAL_ADDRESS;
                    secondHighest.emptyLen = VQ[deFactoMaxTransmitCount].size;
	  secondHighest.cvq = cvq;
	  secondHighest.size = (cvq > deFactoMaxTransmitCount ? 0 : VQ[cvq].size);
	  secondHighest.contMonitorW = clockReading + mtts;
	}
      }
    }
    */

#ifndef EXPLICIT_ACK
    //check whether to send packet or ack/nack
    //if (TOS_LOCAL_ADDRESS == BASE_STATION_ID && toAck()) {     //Is the base station and needs to ack
    if (isBase && toAck()) {     //Is the base station and needs to ack: echelon
      atomic{
	pending = TRUE;
	pendingDeadPeriod = baseAckDeadCount = 0;
      }
      post baseAck();
      return SUCCESS;
    }
#endif
 
    //if (TOS_LOCAL_ADDRESS != BASE_STATION_ID && toSend()) {//Is non-base node and needs to send 
    if (! isBase && toSend()) {//Is non-base node and needs to send: echelon
       atomic{
	pending = TRUE;
	pendingDeadPeriod = 0;
      }
      post sendPacket();
    }

     return SUCCESS;
  }  //end of Timer.fired()

#ifdef CALCULATE_LOG
   //sends log state to UART
   task void sendLogToUart()
   {
     uint8_t j;

     //prepare packets
     Q[0].message.addr = TOS_UART_ADDR;
     Q[0].message.type = ReliableComm_Log_Handler;
     Q[0].message.length = FIRST_LOG_SECTION;
     Q[0].message.group = TOS_AM_GROUP;
     for (j=0; j < FIRST_LOG_SECTION; j++)
	Q[0].message.data[j] = log[j];

     Q[1].message.addr = TOS_UART_ADDR;
     Q[1].message.type = ReliableComm_Log_Handler;
     Q[1].message.length = SECOND_LOG_SECTION;
     Q[1].message.group = TOS_AM_GROUP;
     for (j=0; j < SECOND_LOG_SECTION; j++)
	Q[1].message.data[j] = log[FIRST_LOG_SECTION + j];

     //send Q[0].message
     //call UARTBareSend.send(&(Q[0].message));
     call UARTSend.send(TOS_UART_ADDR, Q[0].message.length, &(Q[0].message));
  } //end of sendLogToUart()

  command result_t ReliableCommControl.logToUart() 
  {
     if ((logPtr->linkSending[0].node_id != NULL8) ||  (logPtr->linkReception[0].node_id != NULL8)) //log is still in RAM; write to UART directly
       post sendLogToUart();
#ifdef LOG_STATE
     else //has to fetch data from flash memory
       call FileRead.open("ReliableComm");
#endif
     return SUCCESS;
  }
#endif

#ifdef LOG_STATE
  event result_t FileWrite.opened(filesize_t fileSize, fileresult_t result) {
     if (result == FS_OK)
	  call FileWrite.append(log, sizeof(ReliableComm_Reflector));
    return SUCCESS;
  }

  event result_t FileWrite.appended(void *buf, filesize_t nWritten,
				    fileresult_t result) {
     call FileWrite.close();
    return SUCCESS;
  }

   /* to log the node state */
  command result_t ReliableCommControl.logState()
   {
     call FileWrite.open("ReliableComm", FS_FTRUNCATE | FS_FCREATE);
     return SUCCESS;
   } //end of ReliableCommControl.logState() 

  event result_t FileRead.readDone(void *buf, filesize_t nRead,
				   fileresult_t result) {
    post sendLogToUart();
    call FileRead.close();
    return SUCCESS;
  }

  event result_t FileRead.opened(fileresult_t result) {
    call FileRead.read(log, sizeof(ReliableComm_Reflector));
    return SUCCESS;
  }

  event result_t FileWrite.closed(fileresult_t result) {
    return SUCCESS;
  }

  event result_t FileWrite.synced(fileresult_t result) {
    return SUCCESS;
  }

  event result_t FileWrite.reserved(filesize_t reservedSize, fileresult_t result) {
    return SUCCESS;
  }

  event result_t matchboxReady() 
  {
    return SUCCESS;
  }

  event result_t FileRead.remaining(filesize_t n, fileresult_t result) {
    return SUCCESS;
  }


/*Log: logging state
  event result_t DataLogger.writelogDone(result_t success) 
 {
   isWritingLog = FALSE;

   return SUCCESS;
 }
*/
#endif

#ifdef USE_MacControl
   /* to use MacControl, provided by CC1000RadioC.nc */
  async event int16_t MacBackoff.initialBackoff(TOS_MsgPtr m)
  {
     return 0xffff;
  }
  async event int16_t MacBackoff.congestionBackoff(TOS_MsgPtr m)
  {
     return 0xffff;
  }
#endif

}


// ======================================================
//                   OBSOLETE                                        DESIGN
// ======================================================
  /* swap the head of the highest-ranked virtual queue with 
   * the tail of VQ[deFactoMaxTransmitCount]. 
   */
/*
  void swap() 
  {
    uint8_t k1, k2;
    uint8_t i;
    ReliableComm_ProtocolMsg * RBCPtr;

    atomic{
      k1 = VQ[deFactoMaxTransmitCount].tail;
      k2 = VQ[cvq].head;

      //update VQ[deFactoMaxTransmitCount]
      if (VQ[deFactoMaxTransmitCount].size ==1)
	VQ[deFactoMaxTransmitCount].head = VQ[deFactoMaxTransmitCount].tail = k2;
      else {
	VQ[deFactoMaxTransmitCount].tail = Q[Q[k1].prev].next = k2;
	Q[k2].prev = Q[k1].prev;
      }

      //update VQ[cvq]
      if (VQ[cvq].size == 1)
	VQ[cvq].head = VQ[cvq].tail = k1;
      else {
	VQ[cvq].head = Q[Q[k2].next].prev = k1;
	Q[k1].next = Q[k2].next;
      }
      //(Q[k2].seq)--;

      //copy Q[k2] to Q[k1], update Q[k1]
      Q[k1].message.addr = Q[k1].message.addr;
      Q[k1].message.type = Q[k1].message.type;
      Q[k1].message.length = Q[k1].message.length;
      Q[k1].message.group = Q[k1].message.group;
      for (i = 0; i < Q[k2].message.length; i++)
	Q[k1].message.data[i] = Q[k2].message.data[i];
      Q[k1].message.crc = Q[k2].message.crc;
      Q[k1].message.strength = Q[k2].message.strength;
      Q[k1].message.ack = Q[k2].message.ack;
      Q[k1].message.time = Q[k2].message.time;
      Q[k1].trxt = Q[k2].trxt;
      Q[k1].resend = Q[k2].resend;
      (Q[k1].seq)++;
      if (Q[k1].seq == NULL8)
	Q[k1].seq = 0;
      RBCPtr = (ReliableComm_ProtocolMsg *)(Q[k1].message.length - sizeof(ReliableComm_ProtocolMsg) + Q[k1].message.data);
      //RBCPtr->myAddr = TOS_LOCAL_ADDRESS;
      RBCPtr->myPos = k1;
      RBCPtr->mySeq = Q[k1].seq; 
   
      //update remaining pointers
      Q[k1].prev = k1;
      Q[k2].next = k2;
    } //end of atomic{

  } //end of swap()
*/


   /* # of higher-ranked packets */
   /*
   uint8_t pktsMore(uint8_t emptyElements1, uint8_t cvq1, uint8_t size11, uint8_t emptyElements2, uint8_t cvq2, uint8_t size22)
   {
     uint8_t size1, size2;
     atomic{
       size1 = size11;
       size2 = size22;
       if (size1 > SEND_QUEUE_SIZE)
	 size1 -= (SEND_QUEUE_SIZE+1);
       if (size2 > SEND_QUEUE_SIZE)
	 size2 -= (SEND_QUEUE_SIZE+1);
     }//atomic

     if (emptyElements1 <= L1 && cvq1 == 0 && emptyElements2 > L1)
       if (L1 - emptyElements1 + 1 < size1)
	 return (L1 - emptyElements1 + 1);
       else 
	 return size1;

     if (cvq1 != NULL8 && cvq1 < cvq2)
       return size1;

     if (size1 > size2)
       return (((size1-size2)>>1) +1);

     return 1; 
   }//end of pktsMore(...) 
   */

  /* compare the rank in contention control */
  /*
  bool rankHigher(uint8_t emptyElements1, uint8_t cvq1, uint8_t size1, uint16_t id1, uint8_t emptyElements2, uint8_t cvq2, uint8_t size2, uint16_t id2) 
  {
    if (id1 == id2)
      return TRUE;

    if (cvq1 == NULL8 || size1 > SEND_QUEUE_SIZE) //no packet to send or is to withdraw
      return FALSE;

    if (emptyElements1 <= L1 && cvq1 == 0 && emptyElements2 > L1)
      return TRUE;

    if (emptyElements2 <= L1 && cvq2 == 0 && emptyElements1 > L1)
      return FALSE;

    if (cvq1 != NULL8 && cvq1 < cvq2)
      return TRUE;
    else if (cvq1 == NULL8 || cvq1 > cvq2)
      return FALSE;

    if (size1 > size2) 
      return TRUE;
    else if (size1 < size2)
      return FALSE;

    if (id1 < id2) 
      return TRUE;

    return FALSE;
  } //end of rankHigher(...) 
  */
