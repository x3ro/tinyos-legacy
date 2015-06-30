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
 * JDebug v.2.0 module
 * Recommend you increase the MAX_TOS_MSGS length for the
 * Transceiver. The transceiver is acting as the message buffer.
 * @author David Moss (dmm@rincon.com)
 */
 
includes JDebug;

module JDebugM {
  provides {
    interface JDebug;
    interface StdControl;
  }
  
  uses {
    interface State;
    interface Transceiver;
  }
}

implementation {

  /** Our location in the current string chunk */
  uint8_t charIndex;
  
  /** Total amount of bytes loaded from the current message */
  uint8_t totalSent;
  
  /** Amount to copy into the current message from the string */
  uint8_t amountToCopy;
  
  /** Allocated TOS Message */
  TOS_MsgPtr tosPtr;
  
  /** Allocated JDebug struct in the payload */
  JDebugMsg *jdebug;
  
  enum { 
    S_IDLE = 0,
    S_SENDING = 1,
  };
  
  /**************** Prototypes ****************/
  result_t newMessage();
  
  /**************** StdControl commands ****************/
  command result_t StdControl.init() {
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  /**
   * Debug command to send a blackbook debug message to the UART
   * 
   * String Flags:
   *   %<x>l - long
   *   %<x>i - int
   *   %<x>s - short
   *  where including 'x' would print the value in hex
   */
  command result_t JDebug.jdbg(char *s, uint32_t dlong, uint16_t dint, uint8_t dshort) {
    if(!call State.requestState(S_SENDING)) {
      return FAIL;
    }
    
    while(*s) {
      charIndex = 0;
      if(newMessage()) {
        
        while(*s && charIndex < sizeof(jdebug->msg)) {
          jdebug->msg[charIndex] = *s++;
          charIndex++;
        }
        
        if(*s) {
          jdebug->newLine = FALSE;
        } else { 
          jdebug->newLine = TRUE;
        }
        
        jdebug->dlong = dlong;
        jdebug->dint = dint;
        jdebug->dshort = dshort;
        call Transceiver.sendUart(sizeof(JDebugMsg));

      } else {
        call State.toIdle();
        return FAIL;
      }
    }
    
    call State.toIdle();
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
    return m;
  }
  
  /**
   * Received a message over UART.  This is just a forward from
   * UARTComm.ReceiveMsg
   */
  event TOS_MsgPtr Transceiver.receiveUart(TOS_MsgPtr m) {
    return m;
  }
  
  /***************** functions *****************/
  result_t newMessage() {
    if((tosPtr = call Transceiver.requestWrite()) != NULL) {
      jdebug = (JDebugMsg *) tosPtr->data;
      memset(jdebug, 0, sizeof(JDebugMsg));
      return SUCCESS;
    }
    return FAIL;
  }
}


