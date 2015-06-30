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
 * Transceiver Interface
 *
 * Transceiver allocates a set number of TOS_Msg's per application,
 * reducing memory requirements and allowing modules to share
 * same TOS_Msg for sending messages.  It also provides a queue
 * of TOS_Msg's, the size of which is defined by the preprocessor
 * variable MAX_TOS_MSGS
 *
 * Because each module in your application could have fault tolerance schemes
 * built in, Transceiver keeps track of whether or not the last
 * message is still valid.  If the module requests the last message
 * to be resent, TOS_Msg will resend if the message from that particular
 * AM type still exists, or return FAIL if it doesn't exist.
 *
 * The implementation is meant to keep a queue of messages to send while
 * using the minimum amount of memory necessary.
 * @author David Moss - dmm@rincon.com
 */

includes AM;

interface Transceiver {
  /**
   * Request a pointer to an empty TOS_Msg.data payload buffer.
   * This will allocate one TOS_Msg to the requesting AM type.
   * This message will be allocated to the requesting AM type until
   * it is sent.
   *
   * You must call sendRadio(..) or sendUart(..) when finished 
   * to release the pointer and send the message.
   *
   * @return a TOS_MsgPtr to an allocated TOS_Msg if available,
   *         NULL if no buffer is available.
   */
  command TOS_MsgPtr requestWrite();


  /**
   * Check if a TOS_Msg has already been allocated by
   * the Transceiver from requestWrite(). Note that if a
   * TOS_Msg is already allocated to the requesting AM type,
   * calling requestWrite() again will return a pointer
   * to the TOS_Msg that is already allocated.
   * @return TRUE if requestWrite has been called and a TOS_Msg 
   *         has been allocated to the current AM type.
   */
  command bool isWriteOpen();


  /**
   * Release and send the current contents of the payload buffer over
   * the radio to the given address, with the given payload size.
   * @param dest - the destination address
   * @param size - the size of the structure inside the TOS_Msg payload.
   * @return SUCCESS if the buffer will be sent. FAIL if no buffer
   *         had been allocated by requestWrite().
   */
  command result_t sendRadio(uint16_t dest, uint8_t payloadSize);
  
  /**
   * Release and send the current contents of the payload buffer over
   * UART with the given payload size.  No address is needed.
   * @param size - the size of the structure inside the TOS_Msg payload.
   * @return SUCCESS if the buffer will be sent. FAIL if no buffer
   *         had been allocated by requestWrite().
   */
  command result_t sendUart(uint8_t payloadSize);
  
  /**
   * Attempt to resend the last message sent by this AM type.
   * If the message still exists in the pool and the attempt 
   * proceeds, SUCCESS will be signaled.  Otherwise, FAIL will 
   * be signaled. In that case, the requesting module will have 
   * to reconstruct the message and try sending it again.
   * @return SUCCESS if the attempt proceeds, and sendDone(..) will be signaled.
   */
  command result_t resendRadio();
  
  /**
   * @return TRUE if the requesting AM type is in the process of being sent.
   */
  command bool isSending();
  
  
  
  /**
   * A message was sent over radio.
   * @param m - a pointer to the sent message, valid for the duration of the 
   *     event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t radioSendDone(TOS_MsgPtr m, result_t result);
  
  /**
   * A message was sent over UART.
   * @param m - a pointer to the sent message, valid for the duration of the 
   *     event.
   * @param result - SUCCESS or FAIL.
   */
  event result_t uartSendDone(TOS_MsgPtr m, result_t result);
  
  /**
   * Received a message over the radio
   * @param m - the receive message, valid for the duration of the 
   *     event.
   */
  event TOS_MsgPtr receiveRadio(TOS_MsgPtr m);
  
  /**
   * Received a message over UART
   * @param m - the receive message, valid for the duration of the 
   *     event.
   */
  event TOS_MsgPtr receiveUart(TOS_MsgPtr m);
}

