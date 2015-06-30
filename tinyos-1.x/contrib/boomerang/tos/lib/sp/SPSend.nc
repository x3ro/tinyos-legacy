// $Id: SPSend.nc,v 1.1.1.1 2007/11/05 19:11:28 jpolastre Exp $
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
 * The primary interface for sending a message using SP.
 * SPSend submits messages (which are composed of packets)
 * to the SP message pool for transmission.  When each link
 * is available, SP dispatches messages from the pool to the link.
 * After transmission of the message, a sendDone() event is signalled
 * with the appropriate error codes.
 * <p>
 * For multi-packet messages, the SPSendNext interface is used to
 * acquire the next packet of data.  Please see the documentation
 * within the SPSendNext interface for more information about
 * message futures.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface SPSend {

  /**
   * Send a message using the SP abstraction.  
   * <p>
   * All sp_message_t fields other than msg->msg are *internal* to SP
   * and should not be set by the user.  Doing so may result in
   * unpredictable results.
   * <p>
   * Each sp_message_t must define the first TOS_Msg to be sent over the radio.
   * 
   * @param msg the SP message to send.
   * @param tosmsg the first TOS_Msg packet in the SP message
   * @param addr the destination address of the message
   * @param length the length of the first TOS_Msg
   *
   * @return SUCCESS if the SP message pool has room to accept the message
   */
  command result_t send(sp_message_t* msg, TOS_Msg* tosmsg, sp_address_t addr, uint8_t length);

  /** 
   * Advanced SP Send command.
   * <p>
   * <code>sendAdv</code> includes additional parameters for setting the
   * message flags, destination interface, and message futures.
   * <p>
   * All sp_message_t fields other than msg->msg are *internal* to SP
   * and should not be set by the user.  Doing so may result in
   * unpredictable results.
   * <p>
   * Each sp_message_t must define the first TOS_Msg to be sent over the radio.
   * <p>
   * Users of SP may set the control flags using the following options:
   * <p>
   * <pre>
   * - SP_FLAG_C_TIMESTAMP == adds a timestamp to all outgoing messages.  See the SPUtil interface for more information.
   * - SP_FLAG_C_RELIABLE  == attempts to send the message with reliable transport
   * - SP_FLAG_C_URGENT    == marks the message as urgent, a priority mechanism
   * - SP_FLAG_C_NONE      == removes all flags
   * - SP_FLAG_C_ALL       == sets all flags
   * </pre>
   * <p>
   * For example, if you want timestamping and reliable transport,<br>
   * <tt>flags = SP_FLAG_C_TIMESTAMP | SP_FLAG_C_RELIABLE;</tt>
   * <p>
   * Current SP device/interface options are:
   * <pre>
   * - SP_I_NOT_SPECIFIED == send over the default interface
   * - SP_I_RADIO         == send over the primary radio link
   * - SP_I_UART          == send over the primary uart link
   * </pre>
   *
   * @param msg the SP message to send.
   * @param tosmsg the first TOS_Msg packet in the SP message
   * @param dev the destination interface for the message
   * @param addr the destination address of the message
   * @param length the length of the first TOS_Msg
   * @param flags the flags for control information for this message
   * @param quantity the number of packets in the message using SP message futures
   *
   * @return SUCCESS if the message is accepted into the SP message pool
   */
  command result_t sendAdv(sp_message_t* msg, TOS_Msg* tosmsg, sp_device_t dev, sp_address_t addr, uint8_t length, sp_message_flags_t flags, uint8_t quantity);

  /**
   * Update the contents of a message currently in the message pool.
   *
   * @return FAIL if the message is not in the pool or if it is busy
   */
  command result_t update(sp_message_t* msg, TOS_Msg* tosmsg, sp_device_t dev, sp_address_t addr, uint8_t length, sp_message_flags_t flags, uint8_t quantity);

  /**
   * Remove a message from the SP message pool.
   *
   * @param msg The SP message to remove from the pool
   *
   * @return SUCCESS if the message is removed or FAIL if the message 
   *                 is not in the pool or is currently busy.
   */
  command result_t cancel(sp_message_t* msg);

  /**
   * Notification that the SP message has completed transmission.
   * <p>
   * Viable feedback options: <br>
   * <pre>
   * - SP_FLAG_F_CONGESTION
   * - SP_FLAG_F_PHASE
   * - SP_FLAG_F_RELIABLE
   * </pre>
   * <p>
   * Flags are accessible through the flags parameter
   *
   * @param msg the SP message removed from the message pool
   * @param flags feedback from SP to network protocols
   * @param error notification of any errors that the message incurred
   *
   */
  event void sendDone(sp_message_t* msg, sp_message_flags_t flags, sp_error_t error);

}
