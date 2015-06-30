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
 */
includes FlashBridgeViewer;

module FlashBridgeViewerM {
  provides {
    interface StdControl;
  }
  
  uses {
    interface Leds;
    interface State;
    interface Transceiver;
    interface FlashBridge;
    interface FlashModify;
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
  

  /***************** StdControl ****************/
  command result_t StdControl.init() { 
    call Leds.init();
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
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

  /***************** FlashBridge Events ****************/
  /**
   * Read is complete
   * @param addr - the address to read from
   * @param *buf - the buffer to read into
   * @param len - the amount to read
   * @return SUCCESS if the bytes will be read
   */
  event void FlashBridge.readDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
    if(result) {
      outMsg->cmd = REPLY_READ;
    } else {
      outMsg->cmd = REPLY_READ_FAILED;
    }
    outMsg->addr = addr;
    outMsg->len = len;
    sendMessage();
  }
  
  /**
   * Write is complete
   * @param addr - the address to write to
   * @param *buf - the buffer to write from
   * @param len - the amount to write
   * @return SUCCESS if the bytes will be written
   */
  event void FlashBridge.writeDone(uint32_t addr, void *buf, uint32_t len, result_t result) {
    // NOT EXECUTED IN THIS COMPONENT
    if(result) {
      outMsg->cmd = REPLY_WRITE;
    } else {
      outMsg->cmd = REPLY_WRITE_FAILED;
    }
    outMsg->addr = addr;
    outMsg->len = len;
    sendMessage();
  }
  
  /**
   * Erase is complete
   * @param sector - the sector id to erase
   * @return SUCCESS if the sector will be erased
   */
  event void FlashBridge.eraseDone(uint16_t sector, result_t result) {
    if(result) {
      outMsg->cmd = REPLY_ERASE;
    } else {
      outMsg->cmd = REPLY_ERASE_FAILED;
    }
    outMsg->addr = sector;
    sendMessage();
  }
  
  /**
   * Flush is complete
   * @param result - SUCCESS if the flash was flushed
   */
  event void FlashBridge.flushDone(result_t result) {
    if(result) {
      outMsg->cmd = REPLY_FLUSH;
    } else {
      outMsg->cmd = REPLY_FLUSH_FAILED;
    }
    sendMessage();
  }
  
  /**
   * CRC-16 is computed
   * @param crc - the computed CRC.
   * @param addr - the address to start the CRC computation
   * @param len - the amount of data to obtain the CRC for
   * @return SUCCESS if the CRC will be computed.
   */
  event void FlashBridge.crcDone(uint16_t crc, uint32_t addr, uint32_t len, result_t result) {
    if(result) {
      outMsg->cmd = REPLY_CRC;
    } else {
      outMsg->cmd = REPLY_CRC_FAILED;
    }
    outMsg->len = crc;
    sendMessage();
  }

  event void FlashBridge.ready(result_t result) {
    call Leds.yellowOff();
    if(result) {
      call Leds.greenOn();
      call Leds.redOff();
    } else {
      call Leds.redOn();
      call Leds.greenOff();
    }
  }
  
  /***************** FlashModify Events ****************/
  /**
   * Bytes have been modified on flash
   * @param addr The address modified
   * @param *buf Pointer to the buffer that was written to flash
   * @param len The amount of data from the buffer that was written
   * @param result SUCCESS if the bytes were correctly modified
   */
  event void FlashModify.modified(uint32_t addr, void *buf, uint32_t len, result_t result) {
    if(result) {
      outMsg->cmd = REPLY_WRITE;
    } else {
      outMsg->cmd = REPLY_WRITE_FAILED;
    }
    outMsg->addr = addr;
    outMsg->len = len;
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
          if(!call FlashBridge.read(message->addr, outMsg->data, message->len)) {
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
          if(!call FlashModify.modify(message->addr, message->data, message->len)) {
            outMsg->cmd = REPLY_WRITE_CALL_FAILED;
            sendMessage();
          }
        }
        break;
      
      case CMD_ERASE:
        if(newMessage()) {
          if(!call FlashBridge.erase(message->addr)) {
            outMsg->addr = message->addr;
            outMsg->cmd = REPLY_ERASE_CALL_FAILED;
            sendMessage();
          }
        }
        break;
        
      case CMD_FLUSH:
        if(newMessage()) {
          if(!call FlashBridge.flush()) {
            outMsg->cmd = REPLY_FLUSH_CALL_FAILED;
            sendMessage();
          }
        }
        break;
        
     case CMD_CRC:
        if(newMessage()) {
          if(!call FlashBridge.crc(message->addr, message->len)) {
            outMsg->cmd = REPLY_CRC_CALL_FAILED;
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
}


