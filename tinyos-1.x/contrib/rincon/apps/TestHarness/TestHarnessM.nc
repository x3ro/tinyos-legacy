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
 * Test Harness Module
 * @author David Moss (dmm@rincon.com)
 */

includes TestHarness;

module TestHarnessM {
  uses {
    interface TestControl;
    interface Transceiver;
    interface Leds; 
    interface Timer as StartDelayTimer;
    interface Timer as ReplyDelayTimer;
  }
}

implementation {

  /** UART Message */
  TOS_MsgPtr tosPtr;
  
  /** Pointer to the TestMsg structure in the payload */
  TestMsg *outPayload;
  
  /** The media to reply to */
  uint8_t replyTo;
  
  /** Param from the payload for delayed starts */
  uint32_t param;
  
  enum { 
    UART,
    RADIO,
  };
  
  /**
   * enable/disable start delays for power testing 
   */
  enum {
    DELAYS_ENABLED = 0,
    DELAY = 512,
  };
  
  /***************** Prototypes ****************/
  TOS_MsgPtr receive(TOS_MsgPtr m);
  result_t newMessage();
  task void sendMsg();
  
  /***************** Send/Receive Events ****************/
  
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
    replyTo = RADIO;
    return receive(m);
  }
  
  /**
   * Received a message over UART.  This is just a forward from
   * UARTComm.ReceiveMsg
   */
  event TOS_MsgPtr Transceiver.receiveUart(TOS_MsgPtr m) {
    replyTo = UART;
    return receive(m);
  }
  
  
   
   
  /***************** TestControl events ***************/
  /**
   * Test is complete.
   */
  event void TestControl.complete(uint32_t var, result_t result) {
    if(newMessage()) {
      outPayload->param = var;
      outPayload->result = result;
      outPayload->cmd = CMD_DONE;
      if(DELAYS_ENABLED) {
        call ReplyDelayTimer.start(TIMER_ONE_SHOT, DELAY);
      } else { 
        post sendMsg();
      } 
    }
  }
  
  /****************** Timers ****************/
  event result_t StartDelayTimer.fired() {
    if(!call TestControl.start(param)) {
      if(newMessage()) {
        outPayload->cmd = CMD_BLOCKED;
        outPayload->result = FAIL;
        outPayload->param = 0;  
        call ReplyDelayTimer.start(TIMER_ONE_SHOT, DELAY);
      }
    }
    return SUCCESS;
  }
  
  event result_t ReplyDelayTimer.fired() {
    post sendMsg();
    return SUCCESS;
  }
  
  /****************** Tasks ****************/
  /**
   * Send the UART Message
   */
  task void sendMsg() {
    if(replyTo == RADIO) {
      call Transceiver.sendRadio(TOS_BCAST_ADDR, sizeof(TestMsg));
    } else {
      call Transceiver.sendUart(sizeof(TestMsg));
    }
  }
  
  /**
   * Allocate a new message
   */
  result_t newMessage() {
    if((tosPtr = call Transceiver.requestWrite()) != NULL) {
      outPayload = (TestMsg *) tosPtr->data;
      return SUCCESS;
    }
    return FAIL;
  }
    
  
  /**
   * Receive a new message
   */
  TOS_MsgPtr receive(TOS_MsgPtr m) {
    TestMsg *inPayload = (TestMsg *) m->data;
    switch(inPayload->cmd) {
      case CMD_START:
        if(DELAYS_ENABLED) {
          param = inPayload->param;
          call StartDelayTimer.start(TIMER_ONE_SHOT, DELAY);
        } else {
          if(!call TestControl.start(inPayload->param)) {
            if(newMessage()) {
              outPayload->cmd = CMD_BLOCKED;
              outPayload->result = FAIL;
              outPayload->param = 0;  
              post sendMsg();
            }
          }
        }
        break;
        
      case CMD_PING:
        if(newMessage()) {
          outPayload->cmd = CMD_PING;
          outPayload->param = 0; 
          outPayload->result = SUCCESS; 
          if(DELAYS_ENABLED) {
            call ReplyDelayTimer.start(TIMER_ONE_SHOT, DELAY);
          } else {
            post sendMsg();
          }
        }
        break;
        
      default:
        break;
     }
     
     return m;
   }
}
