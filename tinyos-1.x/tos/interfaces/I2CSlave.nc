// $Id: I2CSlave.nc,v 1.2 2003/10/07 21:46:14 idgay Exp $

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
interface I2CSlave
{
  /**
   * Sets the address of the I2C Slave
   *
   * @return SUCCESS always
   */
  command result_t setAddress(uint8_t value);

  /**
   * Gets the address of the I2C Slave
   *
   * @return I2C Slave Address
   */
  command uint8_t getAddress();

  /**
   * Notifies the application that the master has written
   * a byte to the slave
   *
   * @return SUCCESS always
   */
  event result_t masterWrite(uint8_t value);

  /**
   * Notifies the application that the current data transfer
   * from the master has been completed
   *
   * @return SUCCESS always
   */
  event result_t masterWriteDone();

  /**
   * Notifies the application that the master is requesting
   * a byte from the slave.  The slave must *immediately* return
   * the next byte to be send and tell the I2C protocol if another
   * byte will be sent.
   *
   * @return byte to be sent to the master
   */
  event uint8_t masterRead();

  /**
   * Notifies the application that the master is done reading
   * from the slave
   *
   * @return SUCCESS always
   */
  event result_t masterReadDone();
  
}
