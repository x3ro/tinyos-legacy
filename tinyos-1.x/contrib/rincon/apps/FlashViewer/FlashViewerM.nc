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
 * Flash Viewer implementation
 * Receives commands from the computer and replies with
 * a command or data.
 * @author David Moss (dmm@rincon.com)
 */
includes FlashViewer;

module FlashViewerM {
  provides {
    interface StdControl;
  }
  
  uses {
    interface Leds;
    interface State;
    interface Transceiver;
    interface BlockRead;
    interface BlockWrite;
    interface Mount;
  }
}

implementation { 
  
  /** Pointer to the allocated TOS_Msg */
  TOS_MsgPtr tosPtr;
  
  /** Pointer to the ViewerMsg payload inside the TOS_Msg */
  ViewerMsg *outMsg;
  
  /** Pointer to the incoming message payload */
  ViewerMsg *inMsg;
  
  /** the current method of communication */
  uint8_t commMethod;
  
  /** comm method options */
  enum {
    RADIO,
    UART,
  };
  
  enum { 
    S_IDLE = 0,
    S_BUSY,
  };

  /***************** Prototypes ****************/
  /** Allocate a new message to send */
  result_t newMessage();
  
  /** Execute the received command */
  void execute(ViewerMsg *message);
  
  /** Send a message over the method the command was received */
  void sendMessage();
  
  /** Convert a storage result to a result_t */
  result_t resultCheck(storage_result_t result);
  
  /***************** StdControl ****************/
  command result_t StdControl.init() { 
    call Leds.init();
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call Leds.redOn(); 
    call Mount.mount(0);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  
  /***************** Transceiver ****************/
  /**
   * A message was possibly sent over the radio.
   * Check the result to see if it sent successfully.
   * @param m - a pointer to the sent message, valid for the duration of the event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t Transceiver.radioSendDone(TOS_MsgPtr m, result_t result) {
    return SUCCESS;
  }
  
  /**
   * A message was sent over UART.
   * @param m - a pointer to the sent message, valid for the duration of the event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t Transceiver.uartSendDone(TOS_MsgPtr m, result_t result) {
    return SUCCESS;
  }
  
  /**
   * Received a message over the radio.  This is just a forward from
   * GenericComm.ReceiveMsg
   */
  event TOS_MsgPtr Transceiver.receiveRadio(TOS_MsgPtr m) {
    inMsg = (ViewerMsg *) m->data;
    if(inMsg->cmd > 9) {
      // This is a reply from another mote
      return m;
    }
    
    if(!call State.requestState(S_BUSY)) {
      return m;
    }
    
    commMethod = RADIO;
    execute(inMsg);
    return m;
  }
  
  /**
   * Received a message over UART.  This is just a forward from
   * UARTComm.ReceiveMsg
   */
  event TOS_MsgPtr Transceiver.receiveUart(TOS_MsgPtr m) {
    inMsg = (ViewerMsg *) m->data;
    if(inMsg->cmd > 9) {
      // This is a reply from another mote
      return m;
    }
    
    if(!call State.requestState(S_BUSY)) {
      return m;
    }
    
    commMethod = UART;
    execute(inMsg);
    return m;
  }
  
  /***************** BlockRead events ****************/  
  event void BlockRead.readDone(storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) {
    if(resultCheck(result)) {
      outMsg->cmd = REPLY_READ;
    } else {
      outMsg->cmd = REPLY_READ_FAILED;
    }
    outMsg->addr = addr;
    outMsg->len = len;
    sendMessage();
  }

  event void BlockRead.verifyDone(storage_result_t result) {
    // not supported
  }

  event void BlockRead.computeCrcDone(storage_result_t result, uint16_t crc, block_addr_t addr, block_addr_t len) {
    // not supported
  }
  
  /***************** BlockWrite events ****************/
  event void BlockWrite.writeDone(storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) { 
    if(resultCheck(result)) {
      outMsg->cmd = REPLY_WRITE;
    } else {
      outMsg->cmd = REPLY_WRITE_FAILED;
    }
    outMsg->addr = addr;
    outMsg->len = len;
    sendMessage();
  }

  event void BlockWrite.eraseDone(storage_result_t result) {
    if(resultCheck(result)) {
      outMsg->cmd = REPLY_ERASE;
    } else {
      outMsg->cmd = REPLY_ERASE_FAILED;
    }
    sendMessage();
  }
  
  event void BlockWrite.commitDone(storage_result_t result) {
    if(resultCheck(result)) {
      outMsg->cmd = REPLY_COMMIT;
    } else {
      outMsg->cmd = REPLY_COMMIT_FAILED;
    }
    sendMessage();
  }
  
  /***************** Mount events ****************/
  event void Mount.mountDone(storage_result_t result, volume_id_t id) {
    if(resultCheck(result)) {
      call Leds.redOff();
      call Leds.greenOn(); 
      outMsg->cmd = REPLY_MOUNT;
    } else {
      outMsg->cmd = REPLY_MOUNT_FAILED;
    }
    outMsg->id = id;
    sendMessage();
  }
  
  
  /***************** Functions ****************/
  /**
   * Allocate and define a new message
   */
  result_t newMessage() { 
    if((tosPtr = call Transceiver.requestWrite()) != NULL) {
      outMsg = (ViewerMsg *) tosPtr->data;
      memset(outMsg, 0x0, sizeof(outMsg));
      return SUCCESS;
    }
    return FAIL;
  }
  
  /**
   * Send the message over the communications method the command
   * was received
   */
  void sendMessage() {
    if(commMethod == RADIO) {
      call Transceiver.sendRadio(TOS_BCAST_ADDR, sizeof(ViewerMsg));
    } else {
      call Transceiver.sendUart(sizeof(ViewerMsg));
    }
    call State.toIdle();
  }
  
  /**
   * Execute a command 
   */
  void execute(ViewerMsg *message) {
    switch(message->cmd) {
      case CMD_READ:
        if(newMessage()) {
          if(message->len > sizeof(outMsg->data)) {
            message->len = sizeof(outMsg->data);
          }
          if(!call BlockRead.read(message->addr, outMsg->data, message->len)) {
            outMsg->cmd = REPLY_READ_CALL_FAILED;
            sendMessage();
          }
        }
        break;
        
      case CMD_WRITE:
        if(newMessage()) {
          if(message->len > sizeof(outMsg->data)) {
            message->len = sizeof(outMsg->data);
          }
          memcpy(outMsg->data, message->data, message->len);
          if(!call BlockWrite.write(message->addr, message->data, message->len)) {
            outMsg->cmd = REPLY_WRITE_CALL_FAILED;
            sendMessage();
          }
        }
        break;
      
      case CMD_ERASE:
        if(newMessage()) {
          if(!call BlockWrite.erase()) {
            outMsg->cmd = REPLY_ERASE_CALL_FAILED;
            sendMessage();
          }
        }
        break;
        
      case CMD_MOUNT:
        if(newMessage()) {
          if(!call Mount.mount(message->id)) {
            outMsg->cmd = REPLY_MOUNT_CALL_FAILED;
            sendMessage();
          }
        }
        break;
        
      case CMD_COMMIT:
        if(newMessage()) {
          if(!call BlockWrite.commit()) {
            outMsg->cmd = REPLY_COMMIT_CALL_FAILED;
            sendMessage();
          }
        }
        break;
        
      case CMD_PING:
        if(newMessage()) {
          outMsg->cmd = REPLY_PING;
          sendMessage();
        }
        break;
        
      default:
    }
  }
  
  /**
   * convert a storage result to TRUE if it passed, FALSE if it failed
   */
  result_t resultCheck(storage_result_t result) {
    if(result == STORAGE_OK) {
      return SUCCESS;
    } else {
      return FAIL;
    }
  }
}


