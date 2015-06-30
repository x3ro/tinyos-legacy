/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "sp.h"

/**
 * Interface for SP message futures.
 * <p>
 * SPSendNext works in conjunction with SPSend to implement the full
 * SP message pool functionality.  When a message is submitted via
 * the SPSend interface with a quantity greater than 1, 
 * SPSendNext.request() is signalled after each packet transmission
 * until the entire message has been sent.  After completion of the
 * message, the SPSend.sendDone() event is fired.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface SPSendNext {

  /**
   * SP messages may specify a number of packets called "message futures"
   * that do not need to be materialized until the radio requests these
   * packets.  After sending the first packet in an SP message, SP will
   * request (through this request event) the next TOS_Msg in the sequence.
   * The service must return the next TOS_Msg by calling the
   * response() command BEFORE execution is returned to the service
   * that signalled the request event.  If no packet is returned,
   * the sp message is aborted and SPSend.sendDone() is signalled with
   * a corresponding error code.
   *
   * @param msg The SP message currently being transmitted
   * @param tosmsg The TOS_Msg previously sent
   * @param remaining The number of packets remaining in the message
   */
  event void request(sp_message_t* msg, TOS_Msg* tosmsg, uint8_t remaining);

  /**
   * response() must ONLY be called after receiving a request() and before
   * execution from the request call is returned to the caller.
   * response() must include the next packet to send in the SP message
   *
   * @param msg the SP message that is being referenced
   * @param tosmsg the next packet in the sequence
   * @param length the length of the data payload of the TOS_Msg packet
   */
  command void response(sp_message_t* msg, TOS_Msg* tosmsg, uint8_t length);

}
