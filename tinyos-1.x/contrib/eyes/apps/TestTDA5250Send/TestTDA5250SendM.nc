/**
 * Sensing a value via ADC and transmitting it over the radio.
 **/
module TestTDA5250SendM {
   provides {
      interface StdControl;
}
   uses {
      interface TimerJiffy as TimeoutTimer;
      interface Leds;
      interface BareSendMsg;
      interface ReceiveMsg;
  }
}

implementation {
   #define TIME_BETWEEN_MSGS     10000
   norace TOS_Msg sendMsg;  
   norace uint16_t seq_no;
   
   /**
   * Send a Message
   **/
   result_t SendMsg() {
     sendMsg.addr = 5;
     sendMsg.type = 17;
     sendMsg.group = 0x7D;
     sendMsg.length = 20;
     sendMsg.data[0] = 0x01;
     sendMsg.data[1] = 0x23;
     sendMsg.data[2] = 0x45;
     sendMsg.data[3] = 0x67;
     sendMsg.data[4] = 0xFF;
     sendMsg.data[5] = 0xFF;
     sendMsg.data[6] = 0x00;
     sendMsg.data[7] = 0xFF;
     sendMsg.data[8] = 0xFF; 
     sendMsg.data[9] = 0xFF;
     sendMsg.data[10] = 0xFF;
     sendMsg.data[11] = 0xFF;
     sendMsg.data[12] = 0xFF;
     sendMsg.data[13] = 0x00;
     sendMsg.data[14] = 0xFF;
     sendMsg.data[15] = 0xFF;
     sendMsg.data[16] = 0x00;
     sendMsg.data[17] = 0xFF;
     sendMsg.data[18] = 0xFF; 
     sendMsg.data[19] = 0xFF;          
     return call BareSendMsg.send(&sendMsg);    
   }

   /**
   * Initializing the components. 
   **/
   command result_t StdControl.init() {
      call Leds.init();
      seq_no = 0;
      return SUCCESS;
   }

   /**
   * Start the component. Send first message.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
   command result_t StdControl.start() {
      return call TimeoutTimer.setOneShot(TIME_BETWEEN_MSGS);
   }
   
   /**
   * Stop the component. Do nothing.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/   
   command result_t StdControl.stop() {
      return SUCCESS;
   }
   
   task void TimoutTimerTask() {
     if(call TimeoutTimer.setOneShot(TIME_BETWEEN_MSGS) == FAIL)
       post TimoutTimerTask();   
   }

   /**
    * Message sent. Now set timer to send another random message sometime
      within the next 512 jiffies
    */
   event result_t BareSendMsg.sendDone(TOS_MsgPtr msg, result_t success){
      seq_no++;
      if(success) call Leds.redOff();
      if(call TimeoutTimer.setOneShot(TIME_BETWEEN_MSGS) == FAIL)
        post TimoutTimerTask();
      return SUCCESS;
   }  
   
   /**
   * Receive a message, but do nothing
   **/
   event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
      call Leds.greenToggle();
      if(m->crc) call Leds.yellowToggle();	
      return m;
   }
   
   /**
    * Timer fired, so send another random message
    */
   event result_t TimeoutTimer.fired() {
      if(SendMsg() == FAIL)
      {
        if(call TimeoutTimer.setOneShot(TIME_BETWEEN_MSGS) == FAIL)
          post TimoutTimerTask(); 
      } else {
            call Leds.redOn();
      }     
      return SUCCESS;
   }
}
