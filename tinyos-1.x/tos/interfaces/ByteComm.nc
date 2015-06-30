// $Id: ByteComm.nc,v 1.3 2003/10/07 21:46:14 idgay Exp $

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
/*
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 *
 */

/**
 * A byte-level communication interface. It signals byte receptions and
 * provides a split-phased byte send interface. txByteReady states
 * that the component can accept another byte in its queue to send,
 * while txDone states that the send queue has been emptied.
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */
interface ByteComm {
  /**
   * Transmits a byte over the radio
   *
   * @param data the byte to be transmitted
   *
   * @return SUCCESS if successful
   */
  async command result_t txByte(uint8_t data);

  /**
   * Notification that the radio is ready to receive another byte
   *
   * @param data the byte read from the radio
   * @param error determines the success of receiving the byte
   * @param strength the signal strength of the received byte
   *
   * @return SUCCESS if successful
   */
  async event result_t rxByteReady(uint8_t data, bool error, uint16_t strength);

  /**
   * Notification that the bus is ready to transmit/queue another byte
   *
   * @param success Notification of the successful transmission of the last byte
   *
   * @return SUCCESS if successful
   */
  async event result_t txByteReady(bool success);

  /**
   * Notification that the transmission has been completed
   * and the transmit queue has been emptied.
   *
   * @return SUCCESS always
   */
  async event result_t txDone();
}
