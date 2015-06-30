/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * @modified 3/8/06
 *
 * @author Arsalan Tavakoli <arsalan@cs.berkeley.edu>
 * @author Sukun Kim <binetude@cs.berkeley.edu>
 */
module SPM
{
  provides {
    interface SplitControl as Control;
    
    interface SPSend[uint8_t id];
    interface SPReceive[uint8_t id];
    interface SPNeighbor;
    interface SPSendQueue[uint8_t id];
  } uses {
    interface SplitControl as RadioControl;
    interface SendSP as RadioSend;
    interface ReceiveSP as RadioReceive;
    
    interface StdControl as UARTControl;
    interface SendSP as UARTSend;
    interface ReceiveSP as UARTReceive;

    interface SPLinkAdaptor;
    interface LinkEstimator;
    interface LocalTime as Time;

    interface StdControl as TimerControl;
    interface Timer as EvictionTimer;
    interface Leds;
  }
}

implementation
{
  // Pool of Message Pointers
  sp_message_t* msgTableP[SP_MESSAGE_BUF_SIZE];

  // Neighbor Table
  sp_neighbor_t nghTable[SP_NEIGHBOR_BUF_SIZE];
  sp_neighbor_t* nghTableP[SP_NEIGHBOR_BUF_SIZE];

  // Separate Entry for Broadcast Neighbor
  sp_neighbor_t bcastNeighbor;

  // Current Message SP is dealing with
  sp_message_t* currentMsg;
  sp_message_t* uartMsg;

  enum {
    IDLE = 0, SENDING,
    RADIO = 0, UART};

  uint8_t spState;

  void send_message(uint8_t sp_handle);
  result_t transmitMessage(sp_message_t* nextMessage);
  result_t process_sendDone(TOS_MsgPtr msg, result_t result, uint8_t linkSent);
  void sendComplete(sp_message_t* _msg, result_t result);
  void set_eviction_timer();
  bool sendToNeighbor(uint8_t handle);
  void remove_message(sp_message_t* msg);
  
  command result_t Control.init() {
    uint8_t i = 0;
    result_t okRadio = SUCCESS;
    result_t okTimer = SUCCESS;
    result_t okUART = SUCCESS;
    
    atomic currentMsg = NULL;
    atomic uartMsg = NULL;

    atomic {
      for (i = 0; i < SP_NEIGHBOR_BUF_SIZE; i++) {
        nghTableP[i] = NULL;
	nghTable[i].sp_handle = i;
	nghTable[i].timeOn = SP_MAX_TIME;
	nghTable[i].timeOff = SP_MAX_TIME;
	nghTable[i].quality = 0;
	nghTable[i].listen = FALSE;
	nghTable[i].messagesPending = 0;
	nghTable[i].addrLL.addr_type = 0;}
    }

    atomic spState = IDLE;
    
    call Leds.init();

    
    okRadio = call RadioControl.init();
    okUART = call UARTControl.init();
    okTimer = call TimerControl.init();

    bcastNeighbor.sp_handle = TOS_BCAST_HANDLE;
    bcastNeighbor.addrLL.addr_type = 0;
    bcastNeighbor.timeOn = SP_MAX_TIME;
    bcastNeighbor.timeOff = SP_MAX_TIME;
    bcastNeighbor.listen = FALSE;

    return okRadio && okTimer && okUART;
  }

  event result_t RadioControl.initDone() {
    return signal Control.initDone();
  }

  command result_t Control.start() {
    result_t okRadio = call RadioControl.start();
    result_t okTimer = call TimerControl.start();
    result_t okUART = call UARTControl.start();

    return okRadio && okTimer & okUART;
  }

  event result_t RadioControl.startDone() {
    return signal Control.startDone();
  }

  command result_t Control.stop() {
    result_t okRadio = call RadioControl.stop();
    result_t okUART = call UARTControl.stop();

    return okRadio && okUART;
  }

  event result_t RadioControl.stopDone() {
    return signal Control.stopDone();
  }

 /*** Interface Function Implementations ***/
  
 /* SPSend.send
  * Used to send a message through SP
  * @param msg - SP Message, containing a TOS_MsgPtr, the
  *   correct length, neighbor handle, and any other
  *   desired options
  * 
  * @result - Indicates whether message was successfully
  *   inserted into message pool, not if it was sent
  *   successfully
  */
  command result_t SPSend.send[uint8_t id](sp_message_t* msg) {
    int next_pos;
    dbg(DBG_USR3, "SPSend.send entered with value: %d\n", msg->msg->data[0]);
    for (next_pos = 0; next_pos < SP_MESSAGE_BUF_SIZE; next_pos++) {
      if(msgTableP[next_pos] == NULL)
        break;
    }

    if (next_pos >= SP_MESSAGE_BUF_SIZE) {
      return FAIL;
    }

    atomic msgTableP[next_pos] = msg;

    msg->time_submitted = call Time.read();
    msg->busy = FALSE;
    msg->retries = 0;
    msg->service = id;

    if (msg->sp_handle == TOS_BCAST_HANDLE)
      msg->reliability = FALSE;

    dbg(DBG_USR3, "next_pos: %d, time_submitted: %d, handle: %d\n", next_pos, msg->time_submitted, msg->sp_handle);
    if (msg->sp_handle == TOS_UART_HANDLE) {
      transmitMessage(msg);
    } 
    else {
      if (msg->sp_handle != TOS_BCAST_HANDLE)
        atomic nghTableP[msg->sp_handle]->messagesPending += 1;
      send_message(TOS_NO_HANDLE);
    }
    return SUCCESS;
 }

 /* SPSend.cancel
  * Used to cancel a message in the message pool
  * NOTE: Message can only be cancelled if not currently in
  *  use.
  * @param msg - SP Message that is to be removed
  *
  * @result - Inidcates whether message was successfully
  *  removed.
  */
  command result_t SPSend.cancel[uint8_t id](sp_message_t* msg) {
    int counter = 0;
    for (counter = 0; counter < SP_MESSAGE_BUF_SIZE; counter ++) {
      if ((msgTableP[counter] == msg) &&
          (msgTableP[counter]->busy == FALSE)) {
	    atomic {
	      msgTableP[counter] = NULL;
	      if ((msg->sp_handle != TOS_UART_HANDLE) &&
	          (msg->sp_handle != TOS_BCAST_HANDLE))
	            nghTableP[msg->sp_handle]->messagesPending -= 1;
	    }
	    return SUCCESS;
      }
    }
    return FAIL;
  } 

 /* SPSend.getBuffer
  * Used by above layers to get payload information
  *
  * @param msg - Message for which payload information is
  *  needed
  * @param length - A pointer representing length of payload
  * @param src - Indicates whether source address will be
  *   embedded in packet.
  * @param handle - Indicates neighbor this message will be
  *   addressed to
  *
  * @result void* - A pointer to the beginning of the data
  *   payload within the packet.
  *
  * TODO: If MAC Header unions are implemented, as in T2,
  *  then destination of the packet will no longer matter.
  *  Currently it is used to determine which interface the
  *  getBuffer call should be forwarded to.
  *
  * TODO: If the handle is TOS_UART_HANDLE, this function
  *  just returns a pointer to the beginning of the
  *  message, and sets length to be 0xFFFF.  A link adaptor
  *  for the UART interface needs to be written so that
  *  it functions exactly like the Radio interface
  */
  command void* SPSend.getBuffer[uint8_t id](TOS_MsgPtr msg, uint16_t* length, bool src, uint8_t handle) {
    // Just call the appropriate underlying interface
    if (handle == TOS_UART_HANDLE)
      return call UARTSend.getBuffer(msg, length, src);
    else
      return call RadioSend.getBuffer(msg, length, src);
  }

  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t result) {
    dbg(DBG_USR3, "RadioSend.sendDone with value: %d and result:%d\n", msg->data[0], result);
    return process_sendDone(msg, result, RADIO);
  }

  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t result) {
    return process_sendDone(msg, result, UART);
  }

  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr msg, void* payload, uint16_t payloadLen, uint8_t _sourceHandle, uint8_t _destHandle, uint8_t msgID, uint8_t groupID) {
    if(groupID == TOS_AM_GROUP) {
      if ((_sourceHandle != TOS_NO_HANDLE) && (_sourceHandle != TOS_OTHER_HANDLE)) {
        call SPNeighbor.adjust(nghTableP[_sourceHandle], msg);
      }
      return signal SPReceive.receive[msgID](msg, payload, payloadLen, _sourceHandle, _destHandle);
    }
    return msg;
  }

  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr msg, void* payload, uint16_t payloadLen, uint8_t _sourceHandle, uint8_t _destHandle, uint8_t msgID, uint8_t groupID) {
    //if(groupID == TOS_AM_GROUP) 
    if ((_sourceHandle != TOS_NO_HANDLE) && (_sourceHandle != TOS_OTHER_HANDLE)) {
      call SPNeighbor.adjust(nghTableP[_sourceHandle], msg);
    }
    return signal SPReceive.receive[msgID](msg, payload, payloadLen, _sourceHandle, _destHandle);
    //return msg;
  }

 /* SPNeighbor.insert
  * Inserts a neighbor into the table
  *
  * @param neighbor - Entry that is to be inserted into the
  *   table
  * @param msg - Packet received from neighbor to be
  *   inserted into table.  Message is used to derive
  *   the link address of the new neighbor
  *
  * @result - SP Handle of inserted neighbor.  Returns
  *   TOS_NO_HANDLE if operation failed.
  */
  command uint8_t SPNeighbor.insert(sp_neighbor_t* neighbor, TOS_MsgPtr msg) {
    // Call appropriate function for inserting neighbor
    int counter;
    sp_neighbor_t* existing = NULL;
    sp_neighbor_t newNeighbor;
    newNeighbor.timeOn = SP_MAX_TIME;
    newNeighbor.timeOff = SP_MAX_TIME;
    newNeighbor.quality = 0;
    newNeighbor.listen = FALSE;
    newNeighbor.messagesPending = 0;


    if (neighbor == NULL) {
      if (msg == NULL)
        return TOS_NO_HANDLE;
      else
        existing = call SPLinkAdaptor.findNode(NULL, msg);
      neighbor = &newNeighbor;
    } else {
      existing = call SPLinkAdaptor.findNode(neighbor, msg);
    }

    /*if((neighbor == NULL) ||
       ((neighbor->addrLL.addr_type == 0) && (msg == NULL)))
         return FAIL;
    else
      // TODO: MAKE SURE THIS FUNCTION WORKS CORRECTLY
      existing = call SPLinkAdaptor.findNode(neighbor, msg);
*/
    if (existing != NULL) {
      atomic {
        if ((neighbor->timeOn != SP_MAX_TIME) &&
	    (neighbor->timeOn != 0)) {
	  existing->timeOn = neighbor->timeOn;
	  existing->timeOff = neighbor->timeOff;
	  existing->quality = neighbor->quality;
	}
      }
      return existing->sp_handle;
    }
    else {
      addr_struct* _tmp = call SPLinkAdaptor.getAddress(msg);
      if (_tmp == NULL)
        return TOS_NO_HANDLE;
      neighbor->addrLL.addr_type = _tmp->addr_type;
      if (neighbor->addrLL.addr_type == TOS_UART_HANDLE)
        return TOS_NO_HANDLE;
      neighbor->addrLL.addr = _tmp->addr;
      call SPNeighbor.adjust(neighbor, msg);
      for(counter = 0; counter < SP_NEIGHBOR_BUF_SIZE; counter++) {
        if (nghTableP[counter] == NULL) {
	  neighbor->sp_handle = counter;
	  if (signal SPNeighbor.admit(neighbor) == SUCCESS) {
	    atomic {
	      nghTableP[counter] = &nghTable[counter];
	      nghTable[counter] = *neighbor;
	    }
	    return counter;
	  }
	  return TOS_NO_HANDLE;
	}
      }
      return TOS_NO_HANDLE;
    }
	  
  }

 /* SPNeighbor.getPointer
  * Gets a pointer to a SP Neighbor table entry
  * 
  * @param msg - A message from the node for which the requested entry will be used.
  *
  * @result - Returns NULL if no space is available AND if the node is already in the table. (Should this change)
  *
  * NOTE: Sets up potential race condition.  One node requests pointer, and if before it inserts the neighbor,
  *  another node calls the function, it will get the same pointer.
  *
  */
  command sp_neighbor_t* SPNeighbor.getPointer(TOS_MsgPtr msg) {
    int counter;
    sp_neighbor_t* existing = NULL;
    existing = call SPLinkAdaptor.findNode(NULL, msg);
    if (existing != NULL)
      return NULL;
    for (counter = 0; counter < SP_NEIGHBOR_BUF_SIZE; counter++) {
      if (nghTableP[counter] == NULL)
        return nghTableP[counter];
    }
    return NULL;
  }
    

 /* SPNeighbor.remove
  * Removes a neighbor from the table
  * NOTE: A Neighbor can not be removed if a message to
  *  it is pending.
  *
  * @param neighbor - Neighbor to be removed from the table
  *
  * @result - SUCCESS if neighbor was removed or is not in
  *  table
  *
  */
  command result_t SPNeighbor.remove(sp_neighbor_t* neighbor) {
    // Call appropriate function for removing neighbor
    if (neighbor == NULL)
      return FAIL;


    //if ((call SPLinkAdaptor.compareLinkAddr(&nghTableP[neighbor->sp_handle]->addrLL, &neighbor->addrLL)) &&
        //(neighbor->messagesPending == 0)) {
    if ((nghTableP[neighbor->sp_handle] != NULL) &&
        (nghTableP[neighbor->sp_handle]->messagesPending == 0)) {
	  signal SPNeighbor.evicted(nghTableP[neighbor->sp_handle]);
	  atomic {
	    nghTableP[neighbor->sp_handle] = NULL;
	  }
	  return SUCCESS;
    }
    return FAIL;
  }

 /* SPNeighbor.listen
  * Notifies SP that it needs to listen during this nodes on
  *  time.
  * NOTE: This function really only has meaning if the radio
  *  is being duty-cycled.
  *
  * @param neighbor - The neighbor who SP should listen to
  *   during its active period.
  *
  * @result - SUCCESS if neighbor has valid active period
  */
  command result_t SPNeighbor.listen(sp_neighbor_t* neighbor) {
    if((neighbor != NULL) &&
       (neighbor->timeOff != SP_MAX_TIME) &&
       (neighbor->timeOn >=  call Time.read())) {
         neighbor->listen = TRUE;
	 // TODO: Signal an update event so that link layer knows
	 return SUCCESS;
    }
    return FAIL;
    
  }

 /* SPNeighbor.get
  * Returns a pointer to the neighbor table entry with the
  *  given handle.
  *
  * @param handle - The handle of the desired neighbor table
  *   entry
  * 
  * @result - The appropriate neighbor table handle
  */
  command sp_neighbor_t* SPNeighbor.get(uint8_t handle) {
    if (handle == TOS_BCAST_HANDLE)
      return &bcastNeighbor;

    if (handle < SP_NEIGHBOR_BUF_SIZE)
      return nghTableP[handle];

    return NULL;
  }

 /* SPNeighbor.adjust
  * Updates the Link Quality Estimate of a neighbor based
  *  on a recently received estimate.
  *
  * @param neighbor - The neighbor whose link quality needs
  *   to be updated.
  * @param msg - The recently received packet that contains
  *   the new LQI value.
  *
  * @result - Whether the link quality of the neighbor was
  *   successfully updated.
  *
  * TODO: Using only the LQI as a link estimator is not
  *   good enough.  A new link estimator should
  *   be created that is more thorough.
  *
  * TODO: Have to check to make sure received packet came
  *   from the neighbor whose entry is being updated
  */
  command result_t SPNeighbor.adjust(sp_neighbor_t* neighbor, TOS_MsgPtr msg) {
    // Call the correct function
    if ((neighbor != NULL) && (msg != NULL)) {
      neighbor->quality = call LinkEstimator.estimate(neighbor, msg);
      return SUCCESS;
    }
    return FAIL;
  }

 /* SPNeighbor.find()
  * Used to tell the underlying link layer to look for more
  *  neighbors.  Method is link-specific.
  */
  command result_t SPNeighbor.find() {
    // Call underlying function
    return call SPLinkAdaptor.find();
  }

 /* SPNeighbor.findDone()
  * Used to stop an earlier find call.
  */
  command result_t SPNeighbor.findDone() {
    // Call underlying function
    return call SPLinkAdaptor.findDone();
  }


  
  command uint8_t SPNeighbor.max_neighbors() {
    return SP_NEIGHBOR_BUF_SIZE;
  }

  default event result_t SPSend.sendDone[uint8_t id](sp_message_t* msg, result_t success) {
    return SUCCESS;
  }

  default event TOS_MsgPtr SPReceive.receive[uint8_t id](TOS_MsgPtr _msg, void* payload, uint16_t payloadLen, uint8_t sp_handle, uint8_t dest_handle) {
    return _msg;
  }

  default event TOS_MsgPtr SPSendQueue.nextQueueElement[uint8_t id](sp_message_t* _msg) {
    return NULL;
  }

  void send_message(uint8_t handle) {
    int counter;
    bool priorityFound = FALSE;
    uint32_t timeNow = call Time.read();
    uint32_t earliestSubmitted = SP_MAX_TIME;
    sp_message_t* nextMessage = NULL;
    
    dbg(DBG_USR3, "send_message entered with handle: %d\n", handle);
    
    if ((spState != IDLE) ||
	(call SPLinkAdaptor.getState() != SP_LINK_AWAKE)) {
	  dbg(DBG_USR3, "spState != IDLE.  Leaving send_message\n");
	  return;
    }

    if ((handle != TOS_NO_HANDLE) &&
        (nghTableP[handle] != NULL) &&
        (sendToNeighbor(handle) == SUCCESS)) {
	  for (counter = 0; counter < SP_MESSAGE_BUF_SIZE; counter++) {
	    if((msgTableP[counter] != NULL) &&
	       (msgTableP[counter]->sp_handle == handle)) {
	         if((msgTableP[counter]->urgent == FALSE) &&
		    (timeNow - msgTableP[counter]->time_submitted > SP_LATENCY_TIMEOUT))
		      msgTableP[counter]->urgent = TRUE;
		 if((priorityFound) &&
		    (msgTableP[counter]->urgent) &&
		    (msgTableP[counter]->time_submitted < earliestSubmitted)) {
		      atomic earliestSubmitted = msgTableP[counter]->time_submitted;
		      atomic nextMessage = msgTableP[counter];
		 }
		 if((!priorityFound) &&
		    ((msgTableP[counter]->urgent) ||
		     (msgTableP[counter]->time_submitted < earliestSubmitted))) {
		     atomic earliestSubmitted = msgTableP[counter]->time_submitted;
		     atomic nextMessage = msgTableP[counter];
		     if(msgTableP[counter]->urgent)
		       atomic priorityFound = TRUE;
		 }
	    }
	  }
    }

    if (nextMessage != NULL) {
      transmitMessage(nextMessage);
      return;
    }

    if (handle == TOS_NO_HANDLE) {
      for (counter = 0; counter < SP_MESSAGE_BUF_SIZE; counter++) {
        if((msgTableP[counter] != NULL) &&
	   (sendToNeighbor(msgTableP[counter]->sp_handle))) {
	     if((msgTableP[counter]->urgent == FALSE) &&
	        (timeNow - msgTableP[counter]->time_submitted > SP_LATENCY_TIMEOUT))
		  msgTableP[counter]->urgent = TRUE;
	     if((priorityFound) &&
	        (msgTableP[counter]->urgent) &&
		(msgTableP[counter]->time_submitted < earliestSubmitted)) {
		  atomic earliestSubmitted = msgTableP[counter]->time_submitted;
		  atomic nextMessage = msgTableP[counter];
	     }
	     if((!priorityFound) &&
	        ((msgTableP[counter]->urgent) ||
		 (msgTableP[counter]->time_submitted < earliestSubmitted))) {
		   atomic earliestSubmitted = msgTableP[counter]->time_submitted;
		   atomic nextMessage = msgTableP[counter];
		   if(msgTableP[counter]->urgent)
		     atomic priorityFound = TRUE;
             }
	}
      }
    }

    if (nextMessage != NULL)
      transmitMessage(nextMessage);
  }

  result_t transmitMessage(sp_message_t* nextMessage) {
    
    dbg(DBG_USR3, "transmitMessage Entered with value: %d\n", nextMessage->msg->data[0]);
    if (nextMessage->sp_handle == TOS_UART_HANDLE) {
      if((uartMsg != NULL) && ((uartMsg->busy) &&
         (uartMsg != nextMessage))) {
	   return FAIL;
      }
      else {
        atomic uartMsg = nextMessage;
	atomic uartMsg->busy = TRUE;
        if (!call UARTSend.send(uartMsg)) {
	  atomic {
	    uartMsg->busy = FALSE;
	    uartMsg = NULL;
	  }
	  sendComplete(nextMessage, FAIL);
	}
      }
      return SUCCESS;
    }
	  
    
    if ((call SPLinkAdaptor.getState() == SP_LINK_AWAKE) &&
        ((spState == IDLE) || (nextMessage == currentMsg)) &&
	 (sendToNeighbor(nextMessage->sp_handle))) {
	   atomic {
	     spState = SENDING;
	     currentMsg = nextMessage;
	     currentMsg->busy = TRUE;
	   }
	   dbg(DBG_USR3, "Calling Send destined to %d\n", currentMsg->sp_handle);
	   if (!call RadioSend.send(currentMsg)) {
	     /*atomic {
	       spState = IDLE;
	       currentMsg->busy = FALSE;
	       currentMsg == NULL;
	     }*/
	     process_sendDone(currentMsg->msg, FAIL, RADIO);
	   }
    }
    return FAIL;
  }

  result_t process_sendDone(TOS_MsgPtr msg, result_t result, uint8_t linkSent) {
    if (linkSent == RADIO) {
      if (result == FAIL) {
        if ((currentMsg->reliability) &&
	    (currentMsg->retries < SP_MAX_RETRIES)) {
	      currentMsg->retries++;
	      if(!transmitMessage(currentMsg)) {
	        atomic {
		  currentMsg->busy = FALSE;
		  spState = IDLE;
		}
	      }
	}
	else {
	  dbg(DBG_USR3, "sendDone: Radio failed, sendComplete being called\n");
	  sendComplete(currentMsg, FAIL);
	}
      }
      else {
        if (currentMsg->quantity <= 1)
	  sendComplete(currentMsg, SUCCESS);
	else {
	  atomic currentMsg->quantity--;
	  currentMsg->msg = signal SPSendQueue.nextQueueElement[currentMsg->service](currentMsg);
	  atomic currentMsg->retries = 0;
	  if (currentMsg->msg == NULL) {
	    dbg(DBG_USR3, "sendDone: Radio succeeded, nextElement failed\n");
	    sendComplete(currentMsg, FAIL);
	  }
	  if(!transmitMessage(currentMsg)) {
	    atomic {
	      currentMsg->busy = FALSE;
	      spState = IDLE;
	    }
	  }
	}
      }
    }
    else if(linkSent == UART) {
      if (result == FAIL) {
        sendComplete(uartMsg, FAIL);
      }
      else {
        if (uartMsg->quantity <= 1) {
	  sendComplete(uartMsg, SUCCESS);
	}
	else {
	  atomic uartMsg->quantity--;
	  uartMsg->msg = signal SPSendQueue.nextQueueElement[uartMsg->service](uartMsg);
	  if (uartMsg->msg == NULL) {
	    sendComplete(uartMsg, FAIL);
	  }
	  if (!transmitMessage(uartMsg)) {
	    atomic {
	      uartMsg->busy = FALSE;
	    }
	  }
	}
      }
    }
    send_message(TOS_NO_HANDLE);
    return SUCCESS;
  }

  void sendComplete(sp_message_t* _msg, result_t result) {
    sp_message_t* _tmpMsg;
    atomic {
      _tmpMsg = _msg;
      _tmpMsg->busy = FALSE;
      _tmpMsg->time_submitted = SP_MAX_TIME;
      remove_message(_tmpMsg);
      if (_tmpMsg->sp_handle == TOS_UART_HANDLE)
	uartMsg = NULL;
      else {
	currentMsg = NULL;
	spState = IDLE;
      }
    }
    dbg(DBG_USR3, "Send Done for Count: %d, Result: %d\n", _tmpMsg->msg->data[0], result);
    signal SPSend.sendDone[_tmpMsg->service](_tmpMsg, result);
    send_message(TOS_NO_HANDLE);
  }

  void remove_message(sp_message_t* _msg) {
    int i = 0;
    dbg(DBG_USR3, "Remove_message entered\n");
    for (i = 0; i < SP_MESSAGE_BUF_SIZE; i++) {
      if (msgTableP[i] == _msg) {
        atomic {
	  if((_msg->sp_handle == TOS_BCAST_HANDLE) ||
	     (_msg->sp_handle == TOS_UART_HANDLE)) {
	       msgTableP[i] = NULL;
	  }
	  else {
	    msgTableP[i] = NULL;
	    if (nghTableP[_msg->sp_handle] != NULL)
	      nghTableP[_msg->sp_handle]->messagesPending--;
	  }
	}
	return;
	/*if((nghTableP[_msg->sp_handle] != NULL) &&
	   (nghTableP[_msg->sp_handle]->messagesPending == 1))
	*/
      }
    }
  }
  
  void set_eviction_timer() {
    uint32_t nextEviction = SP_MAX_TIME;
    uint32_t now = call Time.read();
    int counter;

    for (counter = 0; counter < SP_NEIGHBOR_BUF_SIZE; counter++) {
      if ((nghTableP[counter] != NULL) &&
          (nghTableP[counter]->timeOff < nextEviction) &&
	  (nghTableP[counter]->timeOff > now))
	    nextEviction = nghTableP[counter]->timeOff;
    }

    if ((bcastNeighbor.timeOff < nextEviction) &&
        (bcastNeighbor.timeOff > now))
	  nextEviction = bcastNeighbor.timeOff;
    
    if (nextEviction == SP_MAX_TIME)
      return;
    else if ((nextEviction - now < MIN_TIMER_START_PERIOD) ||
             (now > nextEviction))
	       call EvictionTimer.start(TIMER_ONE_SHOT, MIN_TIMER_START_PERIOD);
    else
      call EvictionTimer.start(TIMER_ONE_SHOT, nextEviction - now);
  }

  void check_neighbors_expiration() {
    int counter;
    uint32_t _now = call Time.read();
    uint32_t _timeoff, _timeon;

    for (counter = 0; counter < SP_NEIGHBOR_BUF_SIZE; counter++) {
      if ((nghTableP[counter] != NULL) &&
          (nghTableP[counter]->timeOff <= _now)) {
	    atomic {
	      _timeon = nghTableP[counter]->timeOn;
	      _timeoff = nghTableP[counter]->timeOff;
	      nghTableP[counter]->timeOn = SP_MAX_TIME;
	      nghTableP[counter]->timeOff = SP_MAX_TIME;
	      nghTableP[counter]->listen = FALSE;
	    }
	    signal SPNeighbor.expired(nghTableP[counter], _timeon, _timeoff);
      }
    }

    if (bcastNeighbor.timeOff <= _now) {
      atomic {
        _timeon = bcastNeighbor.timeOn;
	_timeoff = bcastNeighbor.timeOff;
	bcastNeighbor.timeOn = SP_MAX_TIME;
	bcastNeighbor.timeOff = SP_MAX_TIME;
	bcastNeighbor.listen = FALSE;
      }
      signal SPNeighbor.expired(&bcastNeighbor, _timeon, _timeoff);
    }
  }

  event result_t EvictionTimer.fired() {
    check_neighbors_expiration();
    set_eviction_timer();
    return SUCCESS;
  }
	  
  bool sendToNeighbor(uint8_t handle) {
    uint32_t timeNow = call Time.read();
    sp_neighbor_t* neighbor = NULL;
    if (handle == TOS_UART_HANDLE) {
      if ((uartMsg == NULL) || (!uartMsg->busy))
        return TRUE;
      return FALSE;
    }
    else if (handle == TOS_BCAST_HANDLE) {
      neighbor = &bcastNeighbor;}
    else if (handle < SP_NEIGHBOR_BUF_SIZE) {
      neighbor = nghTableP[handle];
    }
    if (neighbor == NULL)
      return FALSE;
    if ((neighbor->timeOn == 0) ||
        (neighbor->timeOn == SP_MAX_TIME) ||
	((neighbor->timeOn < timeNow) &&
	 (neighbor->timeOff > timeNow)))
	   return TRUE;
    return FALSE;
  }
}
  









  
