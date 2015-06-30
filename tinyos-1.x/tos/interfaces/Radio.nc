// $Id: Radio.nc,v 1.2 2003/10/07 21:46:14 idgay Exp $

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
 * A bit-level interface to the mote radio. The radio has two states,
 * transmit and receive, and can be set. The sampling/interrupt rate
 * can be adjusted to one of three values: 0 (double sampling), 1
 * (one-and-a=half-sampling) and 2 (single sampling).
 *
 * <p> This interface, as it directly abstracts hardware, follows the
 * hardware interface convention of not maintaining state. Therefore,
 * some conditions that could be understood by a higher layer to be
 * errors execute properly; for example, one can call
 * <code>txBit</code> when in receive mode. A higher level interface
 * must provide the checks for conditions such as this.
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

interface Radio {

  /**
   * Start transmitting this bit. Does nothing if in receive mode.
   *
   * @return SUCCESS always.
   */
  
  command result_t txBit(uint8_t data);

  /**
   * Transition into transmit mode.
   *
   * @return SUCCESS always.
   */

  command result_t txMode();

  /**
   * Transition into receive mode.
   *
   * @return SUCCESS always.
   */

  command result_t rxMode();

  /**
   * Set bit rate to 0 (20Khz), 1 (13 KHz) or 2 (10 KHz).
   *
   * @return SUCCESS if valid setting, FAIL otherwise.
   *
   */
  command result_t setBitRate(char level);

  /**
   * Notification that a bit has been transmitted;
   * transmit next one with txBit.
   *
   * @return SUCCESS always.
   *
   */
  
  event result_t txBitDone();

  /**
   * Notification that a bit has been received.
   *
   * @return SUCCESS always.
   *
   */
  
  event result_t rxBit(uint8_t bit);
}
