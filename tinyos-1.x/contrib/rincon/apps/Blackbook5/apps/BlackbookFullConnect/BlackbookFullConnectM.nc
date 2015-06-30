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
 * Test Blackbook
 * @author David Moss - dmm@rincon.com
 */
 

includes Blackbook;
includes BlackbookFullConnect;
 
module BlackbookFullConnectM {
  provides {
    interface StdControl;
  }
  
  uses {
    interface BBoot;
    interface BClean;
    interface BFileRead;
    interface BFileWrite;
    interface BFileDelete;
    interface BFileDir;
    interface BDictionary;
    interface Transceiver;
    interface Transceiver as NodeTransceiver;
    interface Transceiver as FileTransceiver;
    interface Transceiver as SectorTransceiver;
    interface NodeMap;
    interface SectorMap; 
    interface State;
    interface Leds;
  }
}

implementation {

  /** The communication method the last message was received */
  uint8_t receiveMethod;
  
  /** TOS Message to write */
  TOS_MsgPtr tosPtr;
  
  /** Message payload to send */
  BlackbookConnectMsg *outMsg;
  

  /** Receive methods */
  enum {
    RADIO,
    UART,
  };

  /** States */
  enum {
    S_IDLE = 0,
    S_BUSY,
  };
  
  /***************** Prototypes ****************/
  /** Process an incoming message */
  TOS_MsgPtr processMsg(TOS_MsgPtr m);
  
  /** Make a new message */
  result_t newMessage();
  
  /** Send the message */
  void sendMsg();
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    call Leds.init();
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call Leds.redOn();
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  /***************** Transceiver Events ****************/
  /**
   * A message was sent over radio.
   * @param m - a pointer to the sent message, valid for the duration of the 
   *     event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t Transceiver.radioSendDone(TOS_MsgPtr m, result_t result) {
    return SUCCESS; 
  }
  
  /**
   * A message was sent over UART.
   * @param m - a pointer to the sent message, valid for the duration of the 
   *     event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t Transceiver.uartSendDone(TOS_MsgPtr m, result_t result) {
    return SUCCESS; 
  }
  
  /**
   * Received a message over the radio
   * @param m - the receive message, valid for the duration of the 
   *     event.
   */
  event TOS_MsgPtr Transceiver.receiveRadio(TOS_MsgPtr m) {
    receiveMethod = RADIO;
    return processMsg(m);
  }
  
  /**
   * Received a message over UART
   * @param m - the receive message, valid for the duration of the 
   *     event.
   */
  event TOS_MsgPtr Transceiver.receiveUart(TOS_MsgPtr m) {
    receiveMethod = UART;
    return processMsg(m);
  }
  
  
  /***************** NodeTransceiver ****************/
  /**
   * Received a message over UART
   * @param m - the receive message, valid for the duration of the 
   *     event.
   */
  event TOS_MsgPtr NodeTransceiver.receiveUart(TOS_MsgPtr m) {
    TOS_MsgPtr nodeTosPtr;
    BlackbookNodeMsg *nodeOutMsg;
    BlackbookNodeMsg *inMsg = (BlackbookNodeMsg *) m->data;
    
    if((nodeTosPtr = call NodeTransceiver.requestWrite()) != NULL) {
      nodeOutMsg = (BlackbookNodeMsg *) nodeTosPtr->data;
      memcpy(&nodeOutMsg->focusedNode, call NodeMap.getNodeAtIndex(inMsg->focusedNode.state), sizeof(flashnode));
      call NodeTransceiver.sendUart(sizeof(BlackbookNodeMsg));
    }
    return m;
  }
  
  /**
   * A message was sent over radio.
   * @param m - a pointer to the sent message, valid for the duration of the 
   *     event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t NodeTransceiver.radioSendDone(TOS_MsgPtr m, result_t result) {
    return SUCCESS; 
  }
  
  /**
   * A message was sent over UART.
   * @param m - a pointer to the sent message, valid for the duration of the 
   *     event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t NodeTransceiver.uartSendDone(TOS_MsgPtr m, result_t result) {
    return SUCCESS; 
  }
  
  /**
   * Received a message over the radio
   * @param m - the receive message, valid for the duration of the 
   *     event.
   */
  event TOS_MsgPtr NodeTransceiver.receiveRadio(TOS_MsgPtr m) {
    return m;
  }
  

  
  /***************** File Transceiver *****************/
   /**
   * Received a message over UART
   * @param m - the receive message, valid for the duration of the 
   *     event.
   */
  event TOS_MsgPtr FileTransceiver.receiveUart(TOS_MsgPtr m) {
    TOS_MsgPtr fileTosPtr;
    BlackbookFileMsg *fileOutMsg;
    BlackbookFileMsg *inMsg = (BlackbookFileMsg *) m->data;
    
    if((fileTosPtr = call FileTransceiver.requestWrite()) != NULL) {
      fileOutMsg = (BlackbookFileMsg *) fileTosPtr->data;
      memcpy(&fileOutMsg->focusedFile, call NodeMap.getFileAtIndex(inMsg->focusedFile.state), sizeof(file));
      call FileTransceiver.sendUart(sizeof(BlackbookFileMsg));
    }
    return m;
  }
  
 
  /**
   * A message was sent over radio.
   * @param m - a pointer to the sent message, valid for the duration of the 
   *     event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t FileTransceiver.radioSendDone(TOS_MsgPtr m, result_t result) {
    return SUCCESS; 
  }
  
  /**
   * A message was sent over UART.
   * @param m - a pointer to the sent message, valid for the duration of the 
   *     event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t FileTransceiver.uartSendDone(TOS_MsgPtr m, result_t result) {
    return SUCCESS; 
  }
  
  /**
   * Received a message over the radio
   * @param m - the receive message, valid for the duration of the 
   *     event.
   */
  event TOS_MsgPtr FileTransceiver.receiveRadio(TOS_MsgPtr m) {
    return m;
  }
  

  
  /***************** Sector Transceiver ****************/  
  /**
   * Received a message over UART
   * @param m - the receive message, valid for the duration of the 
   *     event.
   */
  event TOS_MsgPtr SectorTransceiver.receiveUart(TOS_MsgPtr m) {
    TOS_MsgPtr sectorTosPtr;
    BlackbookSectorMsg *sectorOutMsg;
    BlackbookSectorMsg *inMsg = (BlackbookSectorMsg *) m->data;
    
    if((sectorTosPtr = call SectorTransceiver.requestWrite()) != NULL) {
      sectorOutMsg = (BlackbookSectorMsg *) sectorTosPtr->data;
      memcpy(&sectorOutMsg->focusedSector, call SectorMap.getSectorAtVolume(inMsg->focusedSector.index), sizeof(flashsector));
      call SectorTransceiver.sendUart(sizeof(BlackbookSectorMsg));
    }
    return m;
  }
  
  /**
   * A message was sent over radio.
   * @param m - a pointer to the sent message, valid for the duration of the 
   *     event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t SectorTransceiver.radioSendDone(TOS_MsgPtr m, result_t result) {
    return SUCCESS; 
  }
  
  /**
   * A message was sent over UART.
   * @param m - a pointer to the sent message, valid for the duration of the 
   *     event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t SectorTransceiver.uartSendDone(TOS_MsgPtr m, result_t result) {
    return SUCCESS; 
  }
  
  /**
   * Received a message over the radio
   * @param m - the receive message, valid for the duration of the 
   *     event.
   */
  event TOS_MsgPtr SectorTransceiver.receiveRadio(TOS_MsgPtr m) {
    return m;
  }

  
  /***************** BBoot Events ****************/
  /**
   * The file system finished booting
   * @param totalNodes - the total number of nodes found on flash
   * @param result - SUCCESS if the file system is ready for use.
   */
  event void BBoot.booted(uint16_t totalNodes, uint8_t totalFiles, result_t result) {
    call Leds.redOff();
    call Leds.yellowOn();
    
    if(newMessage()) {
      outMsg->cmd = REPLY_BOOT;
      outMsg->length = totalNodes;
      outMsg->data[0] = totalFiles;
      outMsg->result = result;
      sendMsg();
    }
  }
  
  
  /***************** BClean Events ****************/
  /**
   * The Garbage Collector is erasing a sector - this may take awhile
   */
  event void BClean.erasing() {
    call Leds.yellowOff();
    
    if(newMessage()) {
      outMsg->cmd = REPLY_BCLEAN_ERASING;
      sendMsg();
    }
  }
  
  /**
   * Garbage Collection is complete
   * @return SUCCESS if any sectors were erased.
   */
  event void BClean.gcDone(result_t result) {
    call Leds.yellowOn();
    
    if(newMessage()) {
      outMsg->cmd = REPLY_BCLEAN_DONE;
      outMsg->result = result;
      sendMsg();
    }
  }
  
  /***************** BFileRead Events ****************/
  /**
   * A file has been opened
   * @param fileName - name of the opened file
   * @param len - the total data length of the file
   * @param result - SUCCESS if the file was successfully opened
   */
  event void BFileRead.opened(uint32_t amount, result_t result) {
    if(newMessage()) {
      outMsg->length = amount;
      outMsg->result = result;
      outMsg->cmd = REPLY_BFILEREAD_OPEN;
      sendMsg();
    }
  }

  /**
   * Any previously opened file is now closed
   * @param result - SUCCESS if the file was closed properly
   */
  event void BFileRead.closed(result_t result) {
    if(newMessage()) {
      outMsg->result = result;
      outMsg->cmd = REPLY_BFILEREAD_CLOSE;
      sendMsg();
    }
  }

  /**
   * File read complete
   * @param *buf - this is the buffer that was initially passed in
   * @param len - the length of the data read into the buffer
   * @param result - SUCCESS if there were no problems reading the data
   */
  event void BFileRead.readDone(void *buf, uint16_t len, result_t result) {
    // data is already setup
    outMsg->length = len;
    outMsg->result = result;
    outMsg->cmd = REPLY_BFILEREAD_READ;
    sendMsg();
  }
  
  
  /***************** BFileWrite Events ****************/
  /**
   * Signaled when a file has been opened, with the results
   * @param fileName - the name of the opened write file
   * @param len - The total reserved length of the file
   * @param result - SUCCSES if the file was opened successfully
   */
  event void BFileWrite.opened(uint32_t len, result_t result) {
    if(newMessage()) {
      outMsg->length = len;
      outMsg->result = result;
      outMsg->cmd = REPLY_BFILEWRITE_OPEN;
      sendMsg();
    }
  }

  /** 
   * Signaled when the opened file has been closed
   * @param result - SUCCESS if the file was closed properly
   */
  event void BFileWrite.closed(result_t result) {
    if(newMessage()) {
      outMsg->result = result;
      outMsg->cmd = REPLY_BFILEWRITE_CLOSE;
      sendMsg();
    }
  }

  /**
   * Signaled when this file has been saved.
   * This does not require the save() command to be called
   * before being signaled - this would happen if another
   * file was open for writing and that file was saved, but
   * the behavior of the checkpoint file required all files
   * on the system to be saved as well.
   * @param fileName - name of the open write file that was saved
   * @param result - SUCCESS if the file was saved successfully
   */
  event void BFileWrite.saved(result_t result) {
    if(newMessage()) {
      outMsg->result = result;
      outMsg->cmd = REPLY_BFILEWRITE_SAVE;
      sendMsg();
    }
  }

  /**
   * Signaled when data is written to flash. On some media,
   * the data is not guaranteed to be written to non-volatile memory
   * until save() or close() is called.
   * @param fileName
   * @param data The buffer of data appended to flash
   * @param amountWritten The amount written to flash
   * @param result
   */
  event void BFileWrite.appended(void *data, uint16_t amountWritten, result_t result) {
    if(newMessage()) {
      outMsg->length = amountWritten;
      outMsg->result = result;
      outMsg->cmd = REPLY_BFILEWRITE_APPEND;
      sendMsg();
    }
  }
  
  
  /***************** BFileDelete Events ****************/
  /**
   * A file was deleted
   * @param result - SUCCESS if the file was deleted from flash
   */
  event void BFileDelete.deleted(result_t result) {
    if(newMessage()) {
      outMsg->result = result;
      outMsg->cmd = REPLY_BFILEDELETE_DELETE;
      sendMsg();
    }
  }
  
  
  /***************** BFileDir Events ****************/
  /**
   * The corruption check on a file is complete
   * @param fileName - the name of the file that was checked
   * @param isCorrupt - TRUE if the file's actual data does not match its CRC
   * @param result - SUCCESS if this information is valid.
   */
  event void BFileDir.corruptionCheckDone(char *fileName, bool isCorrupt, result_t result) {
    if(newMessage()) {
      outMsg->result = result;
      outMsg->length = isCorrupt;
      outMsg->cmd = REPLY_BFILEDIR_CHECKCORRUPTION;
      sendMsg();
    }
  }

  /**
   * The check to see if a file exists is complete
   * @param fileName - the name of the file
   * @param doesExist - TRUE if the file exists
   * @param result - SUCCESS if this information is valid
   */
  event void BFileDir.existsCheckDone(char *fileName, bool doesExist, result_t result) {
    if(newMessage()) {
      outMsg->result = result;
      outMsg->length = doesExist;
      outMsg->cmd = REPLY_BFILEDIR_EXISTS;
      sendMsg();
    }
  }
  
  
  /**
   * This is the next file in the file system after the given
   * present file.
   * @param fileName - name of the next file
   * @param result - SUCCESS if this is actually the next file, 
   *     FAIL if the given present file is not valid or there is no
   *     next file.
   */  
  event void BFileDir.nextFile(char *fileName, result_t result) {
    if(newMessage()) {
      memcpy(outMsg->data, fileName, sizeof(filename));
      outMsg->result = result;
      outMsg->cmd = REPLY_BFILEDIR_READNEXT;
      sendMsg();
    }
  }
    
  
  /***************** BDictionary Events ****************/
  /**
   * A Dictionary file was opened successfully.
   * @param totalSize - the total amount of flash space dedicated to storing
   *     key-value pairs in the file
   * @param remainingBytes - the remaining amount of space left to write to
   * @param result - SUCCESS if the file was successfully opened.
   */
  event void BDictionary.opened(uint32_t totalSize, uint32_t remainingBytes, result_t result) {
    if(newMessage()) {
      outMsg->length = totalSize;
      outMsg->result = result;
      outMsg->cmd = REPLY_BDICTIONARY_OPEN;
      sendMsg();
    }
  }

  /**
   * @param isDictionary - TRUE if the file is a dictionary
   * @param result - SUCCESS if the reading is valid
   */
  event void BDictionary.fileIsDictionary(bool isDictionary, result_t result) {
    if(newMessage()) {
      outMsg->length = isDictionary;
      outMsg->result = result;
      outMsg->cmd = REPLY_BDICTIONARY_ISDICTIONARY;
      sendMsg();
    }
  }

 
  /** 
   * The opened Dictionary file is now closed
   * @param result - SUCCSESS if there are no open files
   */
  event void BDictionary.closed(result_t result) {
    if(newMessage()) {
      outMsg->result = result;
      outMsg->cmd = REPLY_BDICTIONARY_CLOSE;
      sendMsg();
    }
  }
  
  /**
   * A key-value pair was inserted into the currently opened Dictionary file.
   * @param key - the key used to insert the value
   * @param value - pointer to the buffer containing the value.
   * @param valueSize - the amount of bytes copied from the buffer into flash
   * @param result - SUCCESS if the key was written successfully.
   */
  event void BDictionary.inserted(uint32_t key, void *value, uint16_t valueSize, result_t result) {
    if(newMessage()) {
      outMsg->result = result;
      outMsg->length = key;
      outMsg->cmd = REPLY_BDICTIONARY_INSERT;
      sendMsg();
    }
  }
  
  /**
   * A value was retrieved from the given key.
   * @param key - the key used to find the value
   * @param valueHolder - pointer to the buffer where the value was stored
   * @param valueSize - the actual size of the value.
   * @param result - SUCCESS if the value was pulled out and is uncorrupted
   */
  event void BDictionary.retrieved(uint32_t key, void *valueHolder, uint16_t valueSize, result_t result) {
    /*
     * We don't request a new message here because the local
     * newMessage() component erases the already allocated
     * message payload
     * Just make sure that message doesn't send before this event is 
     * handled.
     */ 
    outMsg->result = result;
    outMsg->length = valueSize;
    outMsg->cmd = REPLY_BDICTIONARY_RETRIEVE;
    sendMsg();
  }
  
  /**
   * A key-value pair was removed
   * @param key - the key that should no longer exist
   * @param result - SUCCESS if the key was really removed
   */
  event void BDictionary.removed(uint32_t key, result_t result) {
    if(newMessage()) {
      outMsg->result = result;
      outMsg->length = key;
      outMsg->cmd = REPLY_BDICTIONARY_REMOVE;
      sendMsg();
    }
  }
  
  /**
   * The next key in the open Dictionary file
   * @param nextKey - the next key
   * @param result - SUCCESS if this is the really the next key,
   *     FAIL if the presentKey was invalid or there is no next key.
   */
  event void BDictionary.nextKey(uint32_t nextKey, result_t result) {
    if(newMessage()) {
      outMsg->result = result;
      outMsg->length = nextKey;
      outMsg->cmd = REPLY_BDICTIONARY_NEXTKEY;
      sendMsg();
    }
  }
  
  event void BDictionary.totalKeys(uint16_t totalKeys) {
  }

  /***************** Functions ****************/
  /**
   * Process the incoming message
   */
  TOS_MsgPtr processMsg(TOS_MsgPtr m) {
    BlackbookConnectMsg *inMsg = (BlackbookConnectMsg *) m->data;
    
    if(!call State.requestState(S_BUSY)) {
      return m;
    }
    
    if(!newMessage()) {
      return m;
    }
    
    switch(inMsg->cmd) {
    
      /** BFileWrite Commands */
      case CMD_BFILEWRITE_OPEN:
        if(!call BFileWrite.open((char *) inMsg->data, inMsg->length)) {
          outMsg->cmd = ERROR_BFILEWRITE_OPEN;
          sendMsg();
        }
        break;
      

      case CMD_BFILEWRITE_CLOSE:
        if(!call BFileWrite.close()) {
          outMsg->cmd = ERROR_BFILEWRITE_CLOSE;
          sendMsg();
        }
        break;

        
      case CMD_BFILEWRITE_APPEND:
        if(!call BFileWrite.append(inMsg->data, inMsg->length)) {
          outMsg->cmd = ERROR_BFILEWRITE_APPEND;
          sendMsg();
        }
        break;
        
      case CMD_BFILEWRITE_SAVE:
        if(!call BFileWrite.save()) {
          outMsg->cmd = ERROR_BFILEWRITE_SAVE;
          sendMsg();
        }
        break;
        
      case CMD_BFILEWRITE_REMAINING:
        outMsg->length = call BFileWrite.getRemaining();
        outMsg->cmd = REPLY_BFILEWRITE_REMAINING;
        sendMsg();
        break;
  
  
      /** BFileRead Commands */
      case CMD_BFILEREAD_OPEN:
        if(!call BFileRead.open((char *) inMsg->data)) {
          outMsg->cmd = ERROR_BFILEREAD_OPEN;
          sendMsg();
        }
        break;
        
      case CMD_BFILEREAD_CLOSE:
        if(!call BFileRead.close()) {
          outMsg->cmd = ERROR_BFILEREAD_CLOSE;
          sendMsg();
        }
        break;
        
      case CMD_BFILEREAD_READ:
        if(inMsg->length > sizeof(outMsg->data)) {
          inMsg->length = sizeof(outMsg->data);
        }
        
        if(!call BFileRead.read(outMsg->data, inMsg->length)) {
          outMsg->cmd = ERROR_BFILEREAD_READ;
          sendMsg();
        }
        break;
        
      case CMD_BFILEREAD_SEEK:
        if(!call BFileRead.seek(inMsg->length)) {
          outMsg->cmd = ERROR_BFILEREAD_SEEK;
          sendMsg();
        } else {
          outMsg->cmd = REPLY_BFILEREAD_SEEK;
          outMsg->result = SUCCESS;
          sendMsg();
        }
        break;
        
      case CMD_BFILEREAD_SKIP:
        if(!call BFileRead.skip(inMsg->length)) {
          outMsg->cmd = ERROR_BFILEREAD_SKIP;
          sendMsg();
        } else { 
          outMsg->cmd = REPLY_BFILEREAD_SKIP;
          outMsg->result = SUCCESS;
          sendMsg();
        }
        break;
        
      case CMD_BFILEREAD_REMAINING:
        outMsg->length = call BFileRead.getRemaining();
        outMsg->cmd = REPLY_BFILEREAD_REMAINING;
        sendMsg();
        break;
  
  
      /** BFileDelete Commands */
      case CMD_BFILEDELETE_DELETE:
        if(!call BFileDelete.delete((char *) inMsg->data)) {
          outMsg->cmd = ERROR_BFILEDELETE_DELETE;
          sendMsg();
        }
        break;
        
        
      /** BFileDir Commands */
      case CMD_BFILEDIR_TOTALFILES:
        outMsg->length = call BFileDir.getTotalFiles();
        outMsg->cmd = REPLY_BFILEDIR_TOTALFILES;
        sendMsg();
        break;
        
      case CMD_BFILEDIR_TOTALNODES:
        outMsg->length = call BFileDir.getTotalNodes();
        outMsg->cmd = REPLY_BFILEDIR_TOTALNODES;
        sendMsg();
        break;
        
      case CMD_BFILEDIR_GETFREESPACE:
        outMsg->length = call BFileDir.getFreeSpace();
        outMsg->cmd = REPLY_BFILEDIR_GETFREESPACE;
        sendMsg();
        break;
        
      case CMD_BFILEDIR_EXISTS:
        if(!call BFileDir.checkExists((char *) inMsg->data)) {
          outMsg->cmd = ERROR_BFILEDIR_EXISTS;
          sendMsg();
        }
        break;
        
      case CMD_BFILEDIR_READNEXT:
        if(!call BFileDir.readNext((char *) inMsg->data)) {
          outMsg->cmd = ERROR_BFILEDIR_READNEXT;
          sendMsg();
        }
        break;
       
      case CMD_BFILEDIR_READFIRST:
        if(!call BFileDir.readFirst()) {
          outMsg->cmd = ERROR_BFILEDIR_READFIRST;
          sendMsg();
        }
        break;
 
      case CMD_BFILEDIR_RESERVEDLENGTH:
        outMsg->length = call BFileDir.getReservedLength((char *) inMsg->data);
        outMsg->cmd = REPLY_BFILEDIR_RESERVEDLENGTH;
        sendMsg();
        break;
        
      case CMD_BFILEDIR_DATALENGTH:
        outMsg->length = call BFileDir.getDataLength((char *) inMsg->data);
        outMsg->cmd = REPLY_BFILEDIR_DATALENGTH;
        sendMsg();
        break;
        
      case CMD_BFILEDIR_CHECKCORRUPTION:
        if(!call BFileDir.checkCorruption((char *) inMsg->data)) {
          outMsg->cmd = ERROR_BFILEDIR_CHECKCORRUPTION;
          sendMsg();
        }
        break;
        
        
      /** BDicitonary Commands */
      case CMD_BDICTIONARY_OPEN:
        if(!call BDictionary.open((char *) inMsg->data, inMsg->length)) {
          outMsg->cmd = ERROR_BDICTIONARY_OPEN;
          sendMsg();
        }
        break;
        
      case CMD_BDICTIONARY_CLOSE:
        if(!call BDictionary.close()) {
          outMsg->cmd = ERROR_BDICTIONARY_CLOSE;
          sendMsg();
        }
        break;
        
      case CMD_BDICTIONARY_INSERT:
        // length = key
        // data = value
        // result = valueSize
        if(!call BDictionary.insert(inMsg->length, inMsg->data, inMsg->result)) {
          outMsg->cmd = ERROR_BDICTIONARY_INSERT;
          sendMsg();
        }
        break;
        
      case CMD_BDICTIONARY_RETRIEVE:
        if(!call BDictionary.retrieve(inMsg->length, outMsg->data, sizeof(outMsg->data))) {
          outMsg->cmd = ERROR_BDICTIONARY_RETRIEVE;
          sendMsg();
        }
        break;
        
      case CMD_BDICTIONARY_REMOVE:
        if(!call BDictionary.remove(inMsg->length)) {
          outMsg->cmd = ERROR_BDICTIONARY_REMOVE;
          sendMsg();
        }
        break;
      
      case CMD_BDICTIONARY_NEXTKEY:
        if(!call BDictionary.getNextKey(inMsg->length)) {
          outMsg->cmd = ERROR_BDICTIONARY_NEXTKEY;
          sendMsg();
        }
        break;
        
      case CMD_BDICTIONARY_FIRSTKEY:
        if(!call BDictionary.getFirstKey()) {
          outMsg->cmd = ERROR_BDICTIONARY_FIRSTKEY;
          sendMsg();
        }
        break;
       
      case CMD_BDICTIONARY_ISDICTIONARY:
        if(!call BDictionary.isFileDictionary((char *) inMsg->data)) {
          outMsg->cmd = ERROR_BDICTIONARY_ISDICTIONARY;
          sendMsg();
        }
        break;
        
        
      default:    
    }
    
    return m;
  }
  
  /**
   * Create a new message
   */
  result_t newMessage() {
    if((tosPtr = call Transceiver.requestWrite()) != NULL) {
      outMsg = (BlackbookConnectMsg *) tosPtr->data;
      memset(outMsg->data, 0, sizeof(outMsg->data));
      return SUCCESS;
    }
    return FAIL;
  }
 
  /** 
   * Send the message
   */
  void sendMsg() {
    call State.toIdle();
    if(receiveMethod == RADIO) {
      call Transceiver.sendRadio(TOS_BCAST_ADDR, sizeof(BlackbookConnectMsg));
    } else {
      call Transceiver.sendUart(sizeof(BlackbookConnectMsg));
    }
  }
}


