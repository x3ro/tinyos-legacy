// $Id: PIC18F4620I2C.nc,v 1.1 2005/04/29 12:42:37 hjkoerber Exp $
/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
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
 */

/*
 * @author Joe Polastre
 * @author hjkoerber
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 
 * $Revision: 1.1 $
 */

interface PIC18F4620I2C {
  /**
   * Enable the I2C module, i.e. set MSSP to I2C mode
   */
  async command result_t enable();
  /**
   * Disable the I2C module (clear the SSPEN bit)
   */
  async command result_t disable();

  /**
   * Set Master I2C mode
   */
  async command result_t setModeMaster();
 
 /**
   * Only valid in Master mode.  Set the next i2c bus transaction to
   * transmit to a slave device.
   */
  async command result_t setTx();
  /**
   * Only valid in Master mode.  Set the next i2c bus transaction to
   * receive from a slave device.
   */
  async command result_t setRx();




  //   async event result_t sendStartDone();

  /**
   * Notifies that the end condition has been established
   *
   * @return Always return SUCCESS (you have released the bus)
   */
  //async event result_t sendEndDone();

  /**
   * Returns the byte read from the I2C bus
   *
   * @return SUCCESS to continue using the bus, FAIL to release it
   */
  //async event result_t readDone(uint8_t data);

  /**
   * Notifies that the byte has been written to the I2C bus
   *
   * @param success SUCCESS if the slave acknowledged the byte, FAIL otherwise
   *
   * @return SUCCESS to continue using the bus, FAIL to release it
   */
  // async event result_t writeDone(bool success);

  /**
   * Set the number of bytes to transmit or receive in master mode.
   */
  //  async command result_t setByteCount(uint8_t value);
  /**
   * Number of bytes to transmit or receive remaining in master mode.
   */
  //async command uint8_t  getByteCount();
 /**
   * Set Slave I2C mode
   */
 // async command result_t setModeSlave();

  /**
   * Use 7-bit addressing mode
   */
  // async command result_t setAddr7bit();
  /**
   * Use 10-bit addressing mode
   */
  //async command result_t setAddr10bit();

  /**
   * Set the PIC18F4620's own address
   */
  //async command result_t setOwnAddr(uint16_t addr);
  /**
   * Set the slave address of the device for the next i2c bus transaction
   */
  //async command result_t setSlaveAddr(uint16_t addr);

}
