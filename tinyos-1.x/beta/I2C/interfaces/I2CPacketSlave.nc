// $Id: I2CPacketSlave.nc,v 1.2 2003/10/30 22:15:43 idgay Exp $

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
 * A higher level interface to send or receive a series of bytes
 * over the I2C hardware bus to/from a specified address.  
 * The underlying implementation uses the
 * <code>I2C</code> byte level command interface
 */
includes I2C;
interface I2CPacketSlave
{
  /**
   * Sets the address of the I2C Slave
   *
   * @param value The 7 lower bits of value are the I2C slave address.
   *   If I2CSLAVE_GENERAL_CALL & value is non-zero, then also respond
   *   to the I2C general call address (address 0).<br>
   *   If value is 0, then stop listening to the I2C bus.
   * @return SUCCESS always
   */
  command result_t setAddress(uint8_t value);

  /**
   * Gets the address of the I2C Slave
   *
   * @return I2C Slave Address. If I2CSLAVE_GENERAL_CALL & return-value
   *   is non-zero, then also responds to the I2C general call address 
   *   (address 0)
   */
  command uint8_t getAddress();

  /**
   * An I2C write has been received
   *
   * @param data Pointer to received data
   * @param length Number of bytes received
   * @return As with the Receive interface, the event handler can either
   *   process data immediately and return it, or hold onto data and
   *   return a free buffer in its place. The returned buffer must be
   *   I2CSLAVE_PACKETSIZE bytes long
   */
  event char *write(char *data, uint8_t length);

  /**
   * An I2C read has been received. The application should return the
   * buffer it wishes to return to the master.
   *
   * @param data The handler should place its buffer address in 
   *   <code>*data</code>
   * @param length The handler should place the number of bytes it wishes
   *   to return in <code>*length</code>. The master will get 0xff for all
   *   bytes beyond <code>*length</code>.
   * @return Ignored.
   */
  event result_t read(char **data, uint8_t *length);

  /**
   * The I2C read signaled by the previous <code>read</code> event has
   * completed.
   * @param sentLength Number of bytes read by the master.
   * @return Ignored.
   */
  event result_t readDone(uint8_t sentLength);
}
