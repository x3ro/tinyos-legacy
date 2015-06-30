module TestTDA5250ReceiveM {
   provides {
      interface StdControl;
}
   uses {
      interface Leds;

      interface BareSendMsg;
      interface ReceiveMsg;
  }
}

implementation {

   command result_t StdControl.init() {
      call Leds.init();
      return SUCCESS;
   }

   /**
   * Start the component. Send first message.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
   command result_t StdControl.start() {
     return SUCCESS;
   }
   
   /**
   * Stop the component. Do nothing.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/   
   command result_t StdControl.stop() {
      return SUCCESS;
   }

   /**
    * Message sent. Now set timer to send another random message sometime
      within the next 512 jiffies
    */
   event result_t BareSendMsg.sendDone(TOS_MsgPtr msg, result_t success){
     return SUCCESS;
   }  
   
   /**
   * Receive a message, but do nothing
   **/
   event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
     if (m->crc == 1) {
       call Leds.yellowToggle();
     }
     return m;
   }
}
