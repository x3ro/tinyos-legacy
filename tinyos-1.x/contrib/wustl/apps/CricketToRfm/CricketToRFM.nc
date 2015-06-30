includes CricketToRF;

module CricketToRFM {
  provides {
    interface StdControl;
  } 
  uses {
    interface Serial;
    interface Leds;    
    interface SendMsg;
  }
}

implementation {
  
  char data[DATA_SIZE];  // Cricket data  
  uint8_t dataSize;
  uint8_t dptr;  // data pointer  
  uint8_t serno;
  bool sending;
  TOS_Msg _msg;
  
  command result_t StdControl.init() {
    sending = FALSE;
    serno = dptr = 0;
    memset(data, 0, DATA_SIZE);
    call Leds.init();  // InitLeds    
    call Serial.SetStdoutSerial();  // Init serial port
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  task void sendData() {
    struct CricketMsg *cMsg = (struct CricketMsg *)_msg.data;
    uint8_t bytesLeft = dataSize - dptr; 
    
    cMsg->id = TOS_LOCAL_ADDRESS;
    cMsg->serno = serno;
    cMsg->start = dptr;
    cMsg->size = dataSize;
    if (CRICKET_MSG_DATA_SIZE > bytesLeft) {
      strncpy(cMsg->data, &data[dptr], bytesLeft);
    } else {
      strncpy(cMsg->data, &data[dptr], CRICKET_MSG_DATA_SIZE);      
    }
    call SendMsg.send(TOS_BCAST_ADDR, sizeof(CricketMsg), &_msg);
  }
  
  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (success)
      dptr += CRICKET_MSG_DATA_SIZE;
    if (dptr < dataSize)
      post sendData();
    else {
      serno++;
      sending = FALSE;
      dptr = 0;
      memset(data, 0, DATA_SIZE);
      call Leds.yellowToggle();
    }
    return SUCCESS;
  }
  
  event result_t Serial.Receive(char* buf, uint8_t len) {
    if (!sending) {
      sending = TRUE;
      strncpy(data, buf, len);
      dataSize = len;
      if (post sendData())
        call Leds.greenToggle();      
    }
    return SUCCESS;
  }
}

