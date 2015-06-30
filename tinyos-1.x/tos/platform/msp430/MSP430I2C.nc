// $Id: MSP430I2C.nc,v 1.1 2005/01/24 02:33:04 jpolastre Exp $
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

/**
 * @author Joe Polastre
 * Revision:  $Revision: 1.1 $
 *
 */
interface MSP430I2C {
  /**
   * Enable the I2C module (set the I2CEN bit)
   */
  async command result_t enable();
  /**
   * Disable the I2C module (clear the I2CEN bit)
   */
  async command result_t disable();

  /**
   * Set Master I2C mode
   */
  async command result_t setModeMaster();
  /**
   * Set Slave I2C mode
   */
  async command result_t setModeSlave();

  /**
   * Use 7-bit addressing mode
   */
  async command result_t setAddr7bit();
  /**
   * Use 10-bit addressing mode
   */
  async command result_t setAddr10bit();

  /**
   * Set the MSP430's own address
   */
  async command result_t setOwnAddr(uint16_t addr);
  /**
   * Set the slave address of the device for the next i2c bus transaction
   */
  async command result_t setSlaveAddr(uint16_t addr);

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

  /**
   * Set the data to transmit in the I2C data register.
   */
  async command result_t setData(uint16_t value);
  /**
   * Get data from the I2C data register when in receive mode.
   */
  async command uint16_t getData();

  /**
   * Set the number of bytes to transmit or receive in master mode.
   */
  async command result_t setByteCount(uint8_t value);
  /**
   * Number of bytes to transmit or receive remaining in master mode.
   */
  async command uint8_t  getByteCount();

  async command result_t isArbitrationLostPending();
  async command result_t isNoAckPending();
  async command result_t isOwnAddrPending();
  async command result_t isReadyRegAccessPending();
  async command result_t isReadyRxDataPending();
  async command result_t isReadyTxDataPending();
  async command result_t isGeneralCallPending();
  async command result_t isStartRecvPending();

  async command void enableArbitrationLost();
  async command void disableArbitrationLost();

  async command void enableNoAck();
  async command void disableNoAck();

  async command void enableOwnAddr();
  async command void disableOwnAddr();

  async command void enableReadyRegAccess();
  async command void disableReadyRegAccess();

  async command void enableReadyRxData();
  async command void disableReadyRxData();

  async command void enableReadyTxData();
  async command void disableReadyTxData();

  async command void enableGeneralCall();
  async command void disableGeneralCall();

  async command void enableStartRecv();
  async command void disableStartRecv();

}
