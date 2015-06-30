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
 * Utility functions for SP's primary operations, including
 * link quality support and time stamping support.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface SPUtil {
  /**
   * Get the link quality of a neighbor, n, based on a received message, msg.
   * The link quality is an ETX value for the neighbor, where lower
   * values indicate a better link.  There is no maximum bound for 
   * the return value.  Values along a path may be added together for
   * the path quality, when using retransmissions, or multiplied together,
   * when not using retransmissions.
   *
   * @param n Neighbor whose link quality should be adjusted
   * @param msg Incoming message used for adjusting current link quality
   *
   * @return new link quality based on the above requirements
   */
  command uint16_t getQuality(sp_neighbor_t* n, TOS_Msg* msg);

  /**
   * When any packet is received, get the time that the packet was
   * received.  The time returned is a 32-bit value based on a 32.768kHz
   * clock signal.  The time is acquired from the same source as LocalTimeC.
   *
   * @param msg Received message
   * @return 32-bit 32.768kHz timestamp
   */
  command uint32_t getReceiveTimestamp(TOS_MsgPtr msg);
  /**
   * If a message is sent with the <tt>SP_FLAG_C_TIMESTAMP</tt> flag set,
   * the sender will append a timestamp to the end of the message with
   * the sender's local time.  This time may be extracted from a received
   * message by passing it to the getSenderTimestamp function and
   * specifying the location of the timestamp.  Usually, the timestamp
   * is the last 4 bytes of the data message. 
   *
   * @param msg Received message
   * @return 32-bit 32.768kHz timestamp
   */
  command uint32_t getSenderTimestamp(TOS_MsgPtr msg, int8_t offset);
}
