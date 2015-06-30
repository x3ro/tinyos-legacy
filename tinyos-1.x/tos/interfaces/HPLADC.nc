// $Id: HPLADC.nc,v 1.3 2003/10/07 21:46:14 idgay Exp $

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
 * Interface to the hardware ADC. Allows binding of virtual ports to
 * physical hardware ports (useful for platform independence).
 *
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

interface HPLADC {

  /**
   * Initialize the ADC.
   *
   * @return SUCCESS always.
   */
  async command result_t init();

  /**
   * Sets the ADC sampling rate in terms of clock ticks.
   *
   * @return SUCCESS always.
   */

  async command result_t setSamplingRate(uint8_t rate);

  /**
   * Bind a virtual port number to an actual ADC data port.
   *
   * @return FAIL if virtual port out of range, SUCCESS otherwise.
   */
  
  async command result_t bindPort(uint8_t port, uint8_t adcPort);

  /**
   * Request a single data sample on a port.
   *
   * @return SUCCESS always.
   */
  async command result_t samplePort(uint8_t port);

  /**
   * Sample the most recently sampled port again.
   * 
   * @return SUCCESS alway s.
   */
  async command result_t sampleAgain();

  /**
   * Stop sampling. Return to an idle mode.
   *
   * @return SUCCESS always.
   */
  async command result_t sampleStop();

  /**
   * Signaled when a data ready is ready.
   *
   * @return SUCCESS always.
   */
  
  async event result_t dataReady(uint16_t data);
}

