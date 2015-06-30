
module RfmToCricketM {
  provides interface StdControl;
  uses {
    interface Leds;    
    interface ByteComm;
    interface ReceiveMsg;
  }
}

implementation {
  
  //bool receiving;
  result_t _success;
  bool deliveringResult;
  uint16_t id;
  uint8_t serno;
  uint8_t dataSize;
  uint8_t dptr;
  char data[DATA_SIZE];
  TOS_Msg _msg;
  TOS_MsgPtr _msgp;
  
  uint8_t count;
  
  void reset() {
    //receiving = FALSE;
    //atomic {
      deliveringResult = FALSE;
      dptr = 0;
      memset(data, 0, DATA_SIZE);  
    //}
  }
  
  command result_t StdControl.init() {        
    call Leds.init();        
    _msgp = &_msg;
    reset();
    count = 0;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {    
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  task void deliverResult() {
    atomic {
      call ByteComm.txByte(data[dptr]);
      //call ByteComm.txByte('a' + count++);
    }
  }
  
  task void deliverNextResult() {
    //if (deliveringResult) {
      atomic {
        if (_success)     
          dptr++;      
      }

      if (dptr != dataSize)
        post deliverResult();
      else {
        call Leds.yellowToggle();
        deliveringResult = FALSE;
        //call ByteComm.txByte('\n');
      }
    //}
  }

  /**
   * Notification that the bus is ready to transmit/queue another byte
   *
   * @param success Notification of the successful transmission of the last byte
   *
   * @return SUCCESS if successful
   */
  async event result_t ByteComm.txByteReady(bool success) {
    atomic {
      _success = success;
    }
    post deliverNextResult();
    return SUCCESS;
  }  
  
  task void processMsg() {
    struct CricketMsg *cMsg = (struct CricketMsg *)_msgp->data;          
    
    //atomic {
      if (!deliveringResult) {
        if (cMsg->start == 0) {     
          reset();
          //receiving = TRUE;
          id = cMsg->id;
          dataSize = cMsg->size;
          serno = cMsg->serno;
          call Leds.redToggle();
        }
        if (id == cMsg->id && serno == cMsg->serno && dptr == cMsg->start) {
          uint8_t bytesLeft = dataSize - cMsg->start;
          if (bytesLeft > CRICKET_MSG_DATA_SIZE) {
            strncpy(&data[dptr], cMsg->data, CRICKET_MSG_DATA_SIZE);
            dptr += CRICKET_MSG_DATA_SIZE;
          } else {
            strncpy(&data[dptr], cMsg->data, bytesLeft);
            dptr += bytesLeft;        
          }
          if (dptr == cMsg->size) {
            data[dataSize++] = '\n';
            data[dataSize++] = '\r';
            deliveringResult = TRUE;
            dptr = 0;
            call Leds.greenToggle();
            post deliverResult();
          }
        } else
          reset();
      }
    //}
  }
  
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    TOS_MsgPtr swap = _msgp;
    _msgp = m;
    post processMsg();
    return swap;        
  }  

  /**
   * Notification that the transmission has been completed
   * and the transmit queue has been emptied.
   *
   * @return SUCCESS always
   */
  async event result_t ByteComm.txDone() {
    return SUCCESS;
  }

  /**
   * Notification that the radio is ready to receive another byte
   *
   * @param data the byte read from the radio
   * @param error determines the success of receiving the byte
   * @param strength the signal strength of the received byte
   *
   * @return SUCCESS if successful
   */  
  async event result_t ByteComm.rxByteReady(uint8_t d, bool error, uint16_t strength) {
    return SUCCESS;
  }  
}

