/*
 * Copyright (c) 2004-2006 Rincon Research Corporation.  
 * All rights reserved.
 * 
 * Rincon Research will permit distribution and use by others subject to
 * the restrictions of a licensing agreement which contains (among other things)
 * the following restrictions:
 * 
 *  1. No credit will be taken for the Work of others.
 *  2. It will not be resold for a price in excess of reproduction and 
 *      distribution costs.
 *  3. Others are not restricted from copying it or using it except as 
 *      set forward in the licensing agreement.
 *  4. Commented source code of any modifications or additions will be 
 *      made available to Rincon Research on the same terms.
 *  5. This notice will remain intact and displayed prominently.
 * 
 * Copies of the complete licensing agreement may be obtained by contacting 
 * Rincon Research, 101 N. Wilmot, Suite 101, Tucson, AZ 85711.
 * 
 * There is no warranty with this product, either expressed or implied.  
 * Use at your own risk.  Rincon Research is not liable or responsible for 
 * damage or loss incurred or resulting from the use or misuse of this software.
 */


/**
 * Transceiver Module
 *   SP takes a load off of some of this stuff already, but
 *   below is what Transceiver was meant to do.  The changes
 *   made to Transceiver to make it compatible with SP were
 *   quick and dirty, with no regards (yet) to removing functionality
 *   from the Transceiver that already overlaps with SP.
 *
 *   > Queues TOS_Msg's in a circular buffer and shares it
 *     to prevent an application from using too much RAM
 *     for each module to have its own TOS_Msg.
 *   > Serially sends the available TOS_Msg's as they
 *     become available.
 *   > Filters received packets belonging to other groups
 *     or motes
 *   > Provides the ability to send and receive UART and Radio,
 *     and know for sure that it's working properly.
 *   > Ability to resend a radio packet of a certain AM 
 *     type that still happens to be queued in the buffer, 
 *     to help modules with fault tolerance.
 *   > Clean, easy to maintain code with little to no wasted 
 *     memory.
 *   > .. And other superhuman abilities.
 *
 * Example usage:
 * <code>
 *  TOS_MsgPtr *tosPtr;     // global
 *  YourStruct *yourStruct; // global
 * 
 *  // Easy way to allocate and initialize a message for
 *  // your whole application:
 *  result_t newMessage() {
 *    if((tosPtr = call Transceiver.requestWrite()) != NULL) {
 *      yourStruct = (YourStruct *) tosPtr->data;
 *      yourStruct->msgID = msgID++;          // auto init example
 *      yourStruct->from = TOS_LOCAL_ADDRESS; // auto init example
 *      return SUCCESS;
 *    }
 *    return FAIL;
 *  }
 *
 *  void sendSomething() {
 *    if(newMessage()) {
 *      // This AM type has a message allocated and initialized
 *      yourStruct->value = getCurrentReading(); // example.
 *      call Transceiver.sendRadio(TOS_BCAST_ADDR, sizeof(YourStruct));
 *    }
 *  }
 *  </code>
 *
 * Example Wiring:
 * <code>
 *  components TransceiverC, YourModuleM;
 *  Main.StdControl -> TransceiverC;
 *  YourModuleM.Transceiver -> TransceiverC.Transceiver[AM_YOURTYPE];
 * </code>
 *
 * That's it. Then you have access to radio and uart through the 
 * Transceiver interface. I recommend using it in every application.
 * 
 * Just keep in mind that the Transceiver will hand out exactly
 * one TOS_Msg per AM type.  If a single AM type requestWrite()'s
 * two times before sending the first one, the second call
 * to requestWrite() will return the same pointer that the first
 * call to requestWrite() returned.
 *
 * @author David Moss - dmm@rincon.com
 */
 
includes Transceiver;
includes sp;
includes AM;

module TransceiverM {
  provides {
    interface StdControl;
    interface Transceiver[uint8_t type];
  }
  
  uses {
    interface State as WriteState;
    interface State as SendState;
    interface PacketFilter;
    interface SPSend[uint8_t id];
    interface SPReceive[uint8_t id];
  }
}

implementation {

  struct msg {
    /** The SP Message to send */
    sp_message_t spMsg;
    
    /** Space for a single TOS_Msg */
    TOS_Msg tosMsg;
    
    /** The method to send - RADIO or UART as defined in Transceiver.h */
    uint8_t sendMethod;
    
    /** The state of this message */
    uint8_t state;

  } msg[MAX_TOS_MSGS];
  
  /** An index to which message should be written next */
  uint8_t nextWriteMsg;

  /** An index to which message should be sent next */
  uint8_t nextSendMsg;

  
  /** States for both WriteState and SendState */
  enum {
    /** Nothing is being updated */
    S_IDLE = 0,
    
    /** The current write index is being updated, don't touch it */
    S_WRITING,
    
    /** The current send index is being updated, don't touch it */
    S_SENDING,
  };
  
  /** msg[] struct array states */
  enum {
    /** This message index can be written */
    MSG_S_CANWRITE,
    
    /** This message index is currently being written to */
    MSG_S_WRITING,
    
    /** This message index is done being written and can be sent */
    MSG_S_CANSEND,
    
    /** This message index is currently being sent */
    MSG_S_SENDING,
  };
  
  /***************** Prototypes *****************/    
  /** Pack a message and mark it for sending */
  result_t pack(uint8_t type, uint16_t dest, uint8_t payloadSize, 
      uint8_t outMethod);
  
  /** Send the next message if it and the radio are available */
  void requestNextSend();
  
  /** Returns TRUE if the next send index is ready */
  bool canSend();
  
  /** Advance the storage queue index */
  void advanceSendIndex();
  
  /** Advance the send queue index */
  void advanceWriteIndex();

  /** Cleanup after send is complete */
  void sendDone();
    
    
  /** Task to send the current valid send message */
  task void sendMsg();
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    int i;
    nextWriteMsg = 0;
    nextSendMsg = 0;
    for(i = 0; i < MAX_TOS_MSGS; i++) {
      msg[i].state = MSG_S_CANWRITE;
      msg[i].spMsg.msg = &msg[i].tosMsg;
    }
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  /***************** Transceiver Commands ****************/
  /**
   * Request a pointer to an empty TOS_Msg.data payload buffer.
   * You must call sendRadio(..) or sendUart(..) when finished 
   * to release the pointer and send the message, or the
   * send queue will get clogged up and stop.
   *
   * Only one write message is available at a time for each
   * AM type.
   * 
   * If the same AM type requests a write after it was already granted
   * a pointer but before it released the pointer, the original
   * pointer gets returned.
   *
   * @return TOS_MsgPtr if a message buffer is available,
   *         NULL if no message buffer is available.
   */
  command TOS_MsgPtr Transceiver.requestWrite[uint8_t type]() {
    int i;
    TOS_MsgPtr returnPtr = NULL;
    
    for(i = 0; i < MAX_TOS_MSGS; i++) {
      if(msg[i].tosMsg.type == type && msg[i].state == MSG_S_WRITING) {
        returnPtr = &msg[i].tosMsg;
        break;
      }
    }
    
    if(returnPtr == NULL 
        && msg[nextWriteMsg].state == MSG_S_CANWRITE 
        && call WriteState.requestState(S_WRITING)) {
      msg[nextWriteMsg].tosMsg.type = type;
      msg[nextWriteMsg].state = MSG_S_WRITING;
      returnPtr = &msg[nextWriteMsg].tosMsg;
      advanceWriteIndex();
      call WriteState.toIdle();
    }
    
    return returnPtr;
  }

  /**
   * Check if a TOS_Msg has already been allocated by
   * the Transceiver from requestWrite(). 
   *
   * @return TRUE if requestWrite has been called and a TOS_Msg 
   *         has been allocated to the current AM type.
   */
  command bool Transceiver.isWriteOpen[uint8_t type]() {
    int focusedIndex;
    for(focusedIndex = 0; focusedIndex < MAX_TOS_MSGS; focusedIndex++) {
      if(msg[focusedIndex].tosMsg.type == type 
          && msg[focusedIndex].state == MSG_S_WRITING) {
        return TRUE;
      }
    }
    return FALSE;
  }

  /**
   * Release and send the current contents of the payload buffer over
   * the radio to the given address, with the given payload size.
   * @param dest - the destination address
   * @param payloadSize - the size of the structure inside the TOS_Msg payload.
   * @return SUCCESS if the buffer will be sent. FAIL if no buffer
   *         had been allocated by requestPayload().
   */
  command result_t Transceiver.sendRadio[uint8_t type](uint16_t dest, 
      uint8_t payloadSize) {
    return pack(type, dest, payloadSize, RADIO);
  }
  
  /**
   * Release and send the current contents of the payload buffer over
   * UART with the given payload size.  No address is needed.
   * @param payloadSize - the size of the structure inside the TOS_Msg payload.
   * @return SUCCESS if the buffer will be sent. FAIL if no buffer
   *         had been allocated by requestPayload().
   */
  command result_t Transceiver.sendUart[uint8_t type](uint8_t payloadSize) {
    return pack(type, TOS_UART_ADDR, payloadSize, UART);
  }
  
  /**
   * Attempt to resend the last message sent by this AM type.
   * If the message still exists and the attempt proceeds, SUCCESS
   * will be signaled.  Otherwise, FAIL will be signaled, and the 
   * module will have to reconstruct the message and try sending it
   * again.
   * @return SUCCESS if the attempt proceeds, and sendDone(..) will be signaled.
   */
  command result_t Transceiver.resendRadio[uint8_t type]() {
    int focusedIndex;
    int totalChecked;
    
    if((focusedIndex = (nextWriteMsg - 1)) < 0) {
      focusedIndex = MAX_TOS_MSGS-1;
    }
    
    // Loop through the past messages and find the last one that is of 
    // the correct type that has already been sent, is not in use, 
    // and memcpy it if necessary to the top of the message queue
    for(totalChecked = 0; totalChecked < MAX_TOS_MSGS; totalChecked++) {
      if(msg[focusedIndex].tosMsg.type == type 
          && msg[focusedIndex].sendMethod == RADIO) {
        // The last message has been found.
        
        if(msg[focusedIndex].state == MSG_S_SENDING 
            || msg[focusedIndex].state == MSG_S_CANSEND) {
          // The last message hasn't sent yet.
          return SUCCESS;
          
        } else {
          if(!call WriteState.requestState(S_WRITING)) {
            return FAIL;
          }
          
          if(msg[nextWriteMsg].state != MSG_S_CANWRITE) {
            // Our storage queue is full.
            call WriteState.toIdle();
            return FAIL;
            
          } else if(focusedIndex == nextWriteMsg) {
            // We don't need to memcpy the message.
            msg[nextWriteMsg].state = MSG_S_CANSEND;
            advanceWriteIndex();
            
          } else {
            // We do need to memcpy the message.
            memcpy(&msg[nextWriteMsg].tosMsg, &msg[focusedIndex].tosMsg, 
                sizeof(TOS_Msg));
            msg[nextWriteMsg].sendMethod = RADIO;
            msg[nextWriteMsg].state = MSG_S_CANSEND;
            advanceWriteIndex();

          }
          
          call WriteState.toIdle();
          requestNextSend();
          return SUCCESS;
        }
      }
      
      if((--focusedIndex) < 0) {
        focusedIndex = MAX_TOS_MSGS-1;
      }
    }
    
    return FAIL;
  }
  
  /**
   * @return TRUE if the current AM type is in the process of being sent.
   */
  command bool Transceiver.isSending[uint8_t type]() {
    int focusedIndex;
    for(focusedIndex = 0; focusedIndex < MAX_TOS_MSGS; focusedIndex++) {
      if((msg[focusedIndex].state == MSG_S_CANSEND 
          || msg[focusedIndex].state == MSG_S_SENDING)
          && msg[focusedIndex].tosMsg.type == type) {
        return TRUE;
      }
    }
    return FALSE;
  }

  
  /***************** SPSend Events ****************/
  /**
   * Notification that the SP message has completed transmission.
   * <p>
   * Viable feedback options: <br>
   * <pre>
   * - SP_FLAG_F_CONGESTION
   * - SP_FLAG_F_PHASE
   * - SP_FLAG_F_RELIABLE
   * </pre>
   * <p>
   * Flags are accessible through the flags parameter
   *
   * @param msg the SP message removed from the message pool
   * @param flags feedback from SP to network protocols
   * @param error notification of any errors that the message incurred
   *
   */
  event void SPSend.sendDone[uint8_t id](sp_message_t* m, sp_message_flags_t flags, sp_error_t error) {
    if(m == &msg[nextSendMsg].spMsg) {
      signal Transceiver.radioSendDone[id](m->msg, (error == SP_SUCCESS));
      sendDone();
    }
  }
  
  /***************** SPReceive Events ****************/
  /**
   * Notification that a packet (TOSMsg) has been received.
   * The pointers passed into the receive function are <b>only valid</b>
   * within the context of the function.  Once the callee returns control
   * to the caller, the pointers are no longer valid.  Users of this
   * interface must copy data or perform actions before returning from
   * the receive handler.
   * <p>
   * To access the device on which the message was received, call the
   * <tt>SPMessage.getDev(sp_message_t*)</tt>
   * and then query the device using the <tt>SPInterface</tt> interface.
   *
   * @param spmsg An sp_message_t structure containing metadata about the
   *              received message.  Access sp_message_t fields <b>only</b>
   *              through the SPMessage interface.
   * @param tosmsg The packet received.
   * @param result Indication of an error, if any, during message reception.
   */
  event void SPReceive.receive[uint8_t id](sp_message_t* spmsg, TOS_MsgPtr m, sp_error_t result) {
    if(spmsg->dev == SP_I_RADIO) {
      if(call PacketFilter.filterPacket(m, RADIO)) {
        signal Transceiver.receiveRadio[id](m);
      }
      
    } else {
      m->group = TOS_AM_GROUP;
      if(call PacketFilter.filterPacket(m, UART)) {
        signal Transceiver.receiveUart[id](m);
      }
    }
  }
  
  
  
  /***************** Tasks ****************/  
  /**
   * Task to Force the current nextSendMsg index to send
   * over radio or uart
   */
  task void sendMsg() {
    if(!call SPSend.send[msg[nextSendMsg].tosMsg.type](&msg[nextSendMsg].spMsg, &msg[nextSendMsg].tosMsg, msg[nextSendMsg].tosMsg.addr, msg[nextSendMsg].tosMsg.length)) {
      post sendMsg();
    }
  }
  
  
  /***************** Functions ****************/
  /**
   * Pack a message into the send queued and attempt to send it.
   * When dest == TOS_UART_ADDR || outMethod == RADIO, 
   * that address is not actually changed in the
   * TOS_Msg.dest.  It's not used by anything anyway,
   * and by not adding it we leave room for the Transceiver to be
   * quickly wired up as an eavesdropper.
   */
  result_t pack(uint8_t type, uint16_t dest, uint8_t payloadSize, 
      uint8_t outMethod) {
    int i;
    for(i = 0; i < MAX_TOS_MSGS; i++) {
      if(msg[i].tosMsg.type == type && msg[i].state == MSG_S_WRITING) {
        if(payloadSize > TOSH_DATA_LENGTH) {
          payloadSize = TOSH_DATA_LENGTH;
        }
        
        msg[i].state = MSG_S_CANSEND;
        msg[i].sendMethod = outMethod;
        msg[i].tosMsg.length = payloadSize;
        msg[i].tosMsg.group = TOS_AM_GROUP;
        if(outMethod == RADIO) {
          msg[i].tosMsg.addr = dest;
        } else {
          msg[i].tosMsg.addr = TOS_UART_ADDR;
        }
        
        requestNextSend();
        return SUCCESS;
      }
    }
    return FAIL;
  }
  
  
  /**
   * Cleanup after a send is complete
   */
  void sendDone() {
    msg[nextSendMsg].state = MSG_S_CANWRITE;
    advanceSendIndex();  
    call SendState.toIdle();
    requestNextSend();
  }
  
  /** 
   * Send the current send index if it is available and
   * we aren't currently sending something else.
   */
  void requestNextSend() {
    if(msg[nextSendMsg].state == MSG_S_CANSEND) {
      if(call SendState.requestState(S_SENDING)) {
        msg[nextSendMsg].state = MSG_S_SENDING;
        post sendMsg();
      }
    }
  }
  
  /** 
   * Advance the index in our storage queue
   */
  void advanceWriteIndex() {
    nextWriteMsg++;
    nextWriteMsg %= MAX_TOS_MSGS;
  }
  
  /**
   * Advance the index in our sending queue.
   */
  void advanceSendIndex() {
    nextSendMsg++;
    nextSendMsg %= MAX_TOS_MSGS;
  }
  
  
  /***************** Defaults ****************/
  default event result_t Transceiver.radioSendDone[uint8_t type](TOS_MsgPtr m, 
      result_t result) {
    return SUCCESS;
  }

  default event result_t Transceiver.uartSendDone[uint8_t type](TOS_MsgPtr m, 
      result_t result) {
    return SUCCESS;
  }
  
  default event TOS_MsgPtr Transceiver.receiveRadio[uint8_t type](TOS_MsgPtr m){
    return m;
  }
  
  default event TOS_MsgPtr Transceiver.receiveUart[uint8_t type](TOS_MsgPtr m) {
    return m;
  } 
  
}


