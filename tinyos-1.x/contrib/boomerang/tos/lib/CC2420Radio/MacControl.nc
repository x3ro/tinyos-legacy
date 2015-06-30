/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Mac Control Interface. Sets the acknowlegement options for outgoing
 * and incoming messages.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface MacControl
{
  /** 
   * Enable outgoing acknowledgments for packets with the ack request
   * bit set
   */
  async command void enableAck();
  /** 
   * Disable outgoing acknowledgments regardless of ack bit status
   */
  async command void disableAck();
  /**
   * After msg is submitted and accepted by the radio stack,
   * request an ack for msg.
   */
  async command void requestAck(TOS_MsgPtr msg);
  /**
   *
   */
  async command cc2420_linkstate_t getState();
}
