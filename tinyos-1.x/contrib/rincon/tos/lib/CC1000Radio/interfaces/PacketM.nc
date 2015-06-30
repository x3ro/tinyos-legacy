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
 * This module provides the Packet interface 
 * with default packet information.
 * 
 * The packet interface can be overridden by
 * comm layers higher up in the stack, such as security
 * or bcast.  This allows application components that sit on
 * top to know how much of the payload belongs to them and
 * where it starts.
 *
 * @author David Moss - dmm@rincon.com
 */
 
module PacketM {
  provides {
    interface Packet;
  }
}

implementation {


  /***************** Packet Commands ****************/
  /**
    * Clear out this packet.  Note that this is a deep operation and
    * total operation: calling clear() on any layer will completely
    * clear the packet for reuse.
    *
    * Note that the Transceiver relies on the AM type to
    * be present throughout the lifetime of an allocated
    * packet. This means we cannot clear the entire
    * packet, or we'd erase the AM type and the allocated
    * message would never get sent.
    */
  command void Packet.clear(TOS_MsgPtr msg) {
    memset(msg->data, 0, sizeof(msg->data));
  }

  /**
    * Return the length of the payload of msg. This value may be less
    * than what maxPayloadLength() returns, if the packet is smaller than
    * the MTU. If a communication component does not support variably
    * sized data regions, then payloadLength() will always return
    * the same value as maxPayloadLength(). 
    */

  command uint8_t Packet.payloadLength(TOS_MsgPtr msg) {
    return TOSH_DATA_LENGTH;
  }

  /**
   * Set the length of the payload in this packet
   */
  command void Packet.setPayloadLength(TOS_Msg *msg, uint8_t len) {
    msg->length  = len;
  }
  
 /**
   * Return the maximum payload length that this communication layer
   * can provide. Note that, depending on protocol fields, a
   * given request to send a packet may not be able to send the
   * maximum payload length (e.g., if there are variable length
   * fields). Protocols may provide specialized interfaces
   * for these circumstances.
   */
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }

 /**
   * Return point to a protocol's payload region in a packet.
   * If len is not NULL, getPayload will return the length of
   * the payload in it, which is the same as the return value
   * from payloadLength(). If a protocol does not support
   * variable length packets, then *len is equal to 
   * maxPayloadLength().
   */
  command void* Packet.getPayload(TOS_MsgPtr msg, uint8_t* len) {
    if(len != NULL) {
      *len = TOSH_DATA_LENGTH;
    }
    return msg->data;
  }
}

