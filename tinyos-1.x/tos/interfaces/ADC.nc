// $Id: ADC.nc,v 1.7 2004/05/30 23:37:27 jpolastre Exp $

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

includes ADC;
//includes sensorboard; // this defines the user names for the ports

/**
 * Analog to Digital Converter Interface. <p>
 * Defines the functions provided by any ADC
 * 
 * @modified  6/25/02
 *
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

interface ADC {
  /**
   * Initiates an ADC conversion on a given port.
   *
   * @return SUCCESS if the ADC is free and available to accept the request
   */
  async command result_t getData();
  /**
   * Initiates a series of ADC conversions. Each return from 
   * <code>dataReady()</code> initiates the next conversion.
   *
   * @return SUCCESS if the ADC is free and available to accept the request
   */
  async command result_t getContinuousData();

  /**
   * Indicates a sample has been recorded by the ADC as the result
   * of a <code>getData()</code> command.
   *
   * @param data a 2 byte unsigned data value sampled by the ADC.
   *
   * @return SUCCESS if ready for the next conversion in continuous mode.
   * if not in continuous mode, the return code is ignored.
   */
  async event result_t dataReady(uint16_t data);
}

