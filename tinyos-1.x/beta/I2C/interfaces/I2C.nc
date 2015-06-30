// $Id: I2C.nc,v 1.2 2003/10/30 22:15:43 idgay Exp $

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

/**
 * Byte and Command interface for using the I2C hardware bus
 */
interface I2C
{
  /**
   * Send a start condition when the bus is free. You will, some day,
   * get a sendStartDone event.
   *
   * @return SUCCESS
   */
  async command result_t sendStart();

  /**
   * Sends a stop/end condition over the bus
   *
   * @return SUCCESS if the end request is accepted, FAIL otherwise
   */
  async command result_t sendEnd();

  /**
   * reads a single byte from the I2C bus from a slave device
   * the byte will be acknowledged iff ack is true
   * if ack is false, the next request must be sendStart or sendEnd
   *
   * @return SUCCESS if the read request is accepted, FAIL otherwise
   */
  async command result_t read(bool ack);

  /**
   * writes a single byte to the I2C bus from master to slave
   *
   * @return SUCCESS if the write request is accepted, FAIL otherwise
   */
  async command result_t write(char data);
  
  /**
   * Notifies that the start condition has been established
   *
   * @return SUCCESS to continue using the bus, FAIL to release it
   */
  async event result_t sendStartDone();

  /**
   * Notifies that the end condition has been established
   *
   * @return Always return SUCCESS (you have released the bus)
   */
  async event result_t sendEndDone();

  /**
   * Returns the byte read from the I2C bus
   *
   * @return Ignored.
   */
  async event result_t readDone(char data);

  /**
   * Notifies that the byte has been written to the I2C bus
   *
   * @param success TRUE if the slave acknowledged the byte, FALSE otherwise
   * @param lostArbitration TRUE if bus arbitration lost, FALSE otherwise
   *   After losing arbitration, the mote must restart the transmission from
   *   start if it wishes to retry.
   *
   * @return Ignored.
   */
  async event result_t writeDone(bool success, bool lostArbitration);
}
