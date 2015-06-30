// $Id: TinySec.nc,v 1.1.1.1 2007/11/05 19:09:04 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* Authors: Chris Karlof
 * Date:    9/26/02
 */

/**
 * @author Chris Karlof
 */

includes AM;
interface TinySec
{
  /**
   * Initializes the TinySec component for receiving a packet. This
   * should be called once at the start of packet reception, even before
   * we know whether TinySec is enabled on that packet. This does not
   * re-enable interrupts and is safe to call anywhere.
   *
   * Pre-condition:
   * No reception or transmission is currently in progress
   * and TinySec is initialized.
   *
   * Post-condition:
   * TinySec is ready to receive packet. 
   *
   * @param cleartext_ptr Pointer to TOS_Msg receive buffer.
   * @return Whether receive initialization succeeded.
   */  
  async command result_t receiveInit(TOS_Msg_TinySecCompat* cleartext_ptr);

  /**
   * Signals the completion of receive initialization for TinySec.
   * Currently, this happens when the length byte is received and the
   * appropriate bits are examined.
   *
   * Pre-condition:
   * TinySec.receive was called and TinySec is initialized.
   *
   * Post-condition:
   * TinySec has determined the proper reception mode. 
   *
   * @param result Indicates whether receive initialization was successful.
   *               Reasons for failure include an invalid length field.
   * @param rxlength Indicates the total receive length in bytes.
   * @param tinysec_enabled Indicates if TinySec is enabled.
   * @return Whether the signal handler was successful.
   */  
  async event result_t receiveInitDone(result_t result, uint16_t rxlength, bool tinysec_enabled);

  /**
   * Signals the completion of reception in TinySec.
   * This indicates that all crypto operations have completed
   * and the crc field is set in the TOS_Msg buffer.
   *
   * Pre-condition:
   * TinySec reception has been initialized.
   *
   * Post-condition:
   * All crypto operations have completed and the packet is ready for
   * delivery to higher layers. 
   *
   * @param result Indicates whether reception was successful.
   *               This currently cannot fail.
   * @return Whether the signal handler was successful.
   */      
  async event result_t receiveDone(result_t result);

  /**
   * Initializes the TinySec component for sending a packet. This
   * should be called once the stack is committed to sending, i.e.,
   * after channel acquisition. This does not re-enable interrupts
   * and is safe to call anywhere.
   *
   * Pre-condition:
   * No reception or transmission is currently in progress
   * and TinySec is initialized. The radio channel has been
   * acquired. The extra bits in the length field indicate
   * the desired TinySec mode.
   *
   * Post-condition:
   * TinySec is ready to send a packet. 
   *
   * @param cleartext_ptr Pointer to buffer containing TOS_Msg.
   * @return Total number of message bytes (excluding MAC or crc) that
   *         will be sent.
   */
  async command uint16_t sendInit(TOS_Msg_TinySecCompat* cleartext_ptr);

  /**
   * Initiates sending side crypto operations. This
   * should be called once the stack is committed to sending, i.e.,
   * after channel acquisition. This does re-enable interrupts
   * and should be the last action taken in the lower layer's
   * interrupt handler.
   *
   * Pre-condition:
   * TinySec.sendInit has been called and TinySec is initialized and
   * the radio channel has been acquired.
   *
   * Post-condition:
   * MAC computation and (if enabled) encryption has completed.
   *
   * @return Whether the sending side crypto operations were successful.
   */
  async command result_t send();

  /**
   * Indicates the last byte from TinySec has been requested.
   *
   * Pre-condition:
   * TinySec.send() and TinySec.sendInit() have been called.
   *
   * Post-condition:
   * All bytes have been requested from TinySec using
   * TinySecRadio.getTransmitByte.
   *
   * @param result Indicates the whether sending was succesful.
   * @return Whether the signal handler was successful.
   */  
  async event result_t sendDone(result_t result);
}
