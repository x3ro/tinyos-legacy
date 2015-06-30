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
 * Eavesdropper Module
 * Provides the same functionality as TOSBase but with 
 * the Transceiver.
 * 
 * @author David Moss - dmm@rincon.com
 */

module EavesdropperM {
  provides {
    interface StdControl;
  }
  
  uses {
    interface Transceiver[uint8_t type];
    interface Leds;
    interface Packet;
  }
}

implementation {
  
  /** Pointer to the current radio write message */
  TOS_MsgPtr tosRadioPtr;
  
  /** Pointer to the current uart write message */
  TOS_MsgPtr tosUartPtr;
  
  /***************** Prototypes ****************/
  result_t newUartMessage(uint8_t type);
  result_t newRadioMessage(uint8_t type);
  
  /***************** StdControl Commands ****************/ 
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
   * Received a message over the radio.
   */
  event TOS_MsgPtr Transceiver.receiveRadio[uint8_t type](TOS_MsgPtr m) {
    if(newUartMessage(type)) {
      call Packet.clear(tosUartPtr);
      memcpy(tosUartPtr, m, sizeof(TOS_Msg));
      call Transceiver.sendUart[type](m->length);
    } else {
      call Leds.redToggle();
    }
    return m;
  }
    
  
  /**
   * Received a message over UART.
   */
  event TOS_MsgPtr Transceiver.receiveUart[uint8_t type](TOS_MsgPtr m) {
    if(newRadioMessage(type)) {
      call Packet.clear(tosRadioPtr);
      memcpy(tosRadioPtr, m, sizeof(TOS_Msg));
      call Transceiver.sendRadio[type](m->addr, m->length);
    } else {
      call Leds.redToggle();
    }
    return m;
  }
  
  /**
   * A message was sent over radio.
   * @param m - a pointer to the sent message, valid for the duration of the event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t Transceiver.radioSendDone[uint8_t type](TOS_MsgPtr m, result_t result) {
    call Leds.yellowToggle();
    return SUCCESS;
  }
  
  /**
   * A message was sent over UART.
   * @param m - a pointer to the sent message, valid for the duration of the event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t Transceiver.uartSendDone[uint8_t type](TOS_MsgPtr m, result_t result) {
    call Leds.greenToggle();
    return SUCCESS;
  }



  /***************** Functions ****************/
  result_t newUartMessage(uint8_t type) {
    if((tosUartPtr = call Transceiver.requestWrite[type]()) != NULL) {
      return SUCCESS;
    }
    return FAIL;
  }

  result_t newRadioMessage(uint8_t type) {
    if((tosRadioPtr = call Transceiver.requestWrite[type]()) != NULL) {
      return SUCCESS;
    }
    return FAIL;
  }
}




