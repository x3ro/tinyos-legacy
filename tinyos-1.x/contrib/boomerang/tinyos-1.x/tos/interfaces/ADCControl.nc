// $Id: ADCControl.nc,v 1.1.1.1 2007/11/05 19:09:01 jpolastre Exp $

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
 * Authors:		Alec Woo, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 *
 */

/**
 * Controls various aspects of the ADC.
 * @author Alec Woo
 * @author David Gay
 * @author Philip Levis
 */
interface ADCControl {
  /**
   * Initializes the ADCControl structures.
   *
   * @return SUCCESS if successful
   */
  command result_t init();

  /**
   * Sets the sampling rate of the ADC.
   * These are the lower three bits in the ADCSR register of the
   * microprocessor.
   *
   * The <code>rate</code> parameter may use the following macros or
   * its own value from the description below.
   * <p>
   * <pre>
   *  TOS_ADCSample3750ns = 0 
   *  TOS_ADCSample7500ns = 1
   *  TOS_ADCSample15us =   2
   *  TOS_ADCSample30us =   3
   *  TOS_ADCSample60us =   4
   *  TOS_ADCSample120us =  5
   *  TOS_ADCSample240us =  6
   *  TOS_ADCSample480us =  7
   * </pre>
   *
   * @param rate 2^rate is the prescaler factor to the ADC.
   * The rate of the ADC is the crystal frequency times the prescaler,
   * or XTAL * 2^rate = 32kHz * 2^rate.
   *
   * @return SUCCESS if successful
   */
  command result_t setSamplingRate(uint8_t rate);

  /**
   * Remaps a port in the ADC portmap <code>TOSH_adc_portmap</code>.
   *
   * See <code>platform/mica/HPLADCC.td</code> for implementation.
   *
   * @param port The port in the portmap you wish to modify
   * @param adcPort The ADC destination port that <code>port</code> binds to
   *
   * @return SUCCESS if successful
   */
  command result_t bindPort(uint8_t port, uint8_t adcPort);
}

