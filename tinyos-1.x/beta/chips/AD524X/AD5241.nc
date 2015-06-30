// $Id: AD5241.nc,v 1.1 2005/02/01 05:05:09 jpolastre Exp $
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
 * The AD5241 interface provides commands for using the
 * Analog Devices AD5241 single-channel 256-position digitally
 * controlled variable resistor device.  The AD5241 and AD5242
 * share the same I2C bus protocol, but they are kept as seperate
 * interfaces to enforce compile time errors
 * (ie: trying to use Pot2 on the AD5241 should not be permitted).
 *
 * The lower 2 bits (AD1 and AD0) must be provided as the address.
 * The full address may be provided as well, but all other bits will be
 * stripped (addr = addr & 0x03)
 */
interface AD5241 {
  /**
   * Start the AD5241 device.  This sets the SD bit to enable the device
   * via the I2C bus.  This command does not alter the physical shutdown
   * pin of the device.  The StdControl interface is responsible for
   * the physical shutdown of the device.
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @return SUCCESS if the request was accepted
   */
  command result_t start(uint8_t addr);
  /**
   * Notification that there was an attempt to set the SD bit.
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @param result SUCCESS if the bit was actually set, FAIL if the
   *               device could not be reached or the operation failed
   */
  event void startDone(uint8_t addr, result_t result);

  /**
   * Stop the AD5241 device.  This clears the SD bit to enable the device
   * via the I2C bus.  This command does not alter the physical shutdown
   * pin of the device.  The StdControl interface is responsible for
   * the physical shutdown of the device.
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @return SUCCESS if the request was accepted
   */
  command result_t stop(uint8_t addr);
  /**
   * Notification that there was an attempt to clear the SD bit.
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @param result SUCCESS if the bit was actually cleared, FAIL if the
   *               device could not be reached or the operation failed
   */
  event void stopDone(uint8_t addr, result_t result);

  /**
   * Set the value of the Output 1 (O1) pin.
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @param high TRUE if O1 should be set, FALSE if it should be cleared
   * @return SUCCESS if the request was accepted
   */
  command result_t setOutput1(uint8_t addr, bool high);
  /**
   * Notification that the state of the O1 pin may have changed.
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @param result SUCCESS if the output O1 was successfully changed
   * @return SUCCESS if the request was accepted
   */
  event void setOutput1Done(uint8_t addr, result_t result);

  /**
   * Set the value of the Output 2 (O2) pin.
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @param high TRUE if O2 should be set, FALSE if it should be cleared
   * @return SUCCESS if the request was accepted
   */
  command result_t setOutput2(uint8_t addr, bool high);
  /**
   * Notification that the state of the O2 pin may have changed.
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @param result SUCCESS if the output O2 was successfully changed
   * @return SUCCESS if the request was accepted
   */
  event void setOutput2Done(uint8_t addr, result_t result);

  /**
   * Get the value of the Output 1 (O1) pin.
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @return TRUE if the bit is set, FALSE otherwise
   */
  command bool getOutput1(uint8_t addr);

  /**
   * Get the value of the Output 2 (O2) pin.
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @return TRUE if the bit is set, FALSE otherwise
   */
  command bool getOutput2(uint8_t addr);

  /**
   * Set the value of RDAC 1 (potentiometer channel 1)
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @param value A 256-bit value corresponding to the wiper position
   * @return SUCCESS if the request was accepted
   */
  command result_t setPot1(uint8_t addr, uint8_t value);
  /**
   * Notification that RDAC1 may be set to a new value
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @param SUCCESS if the value of RDAC1 was changed
   */
  event void setPot1Done(uint8_t addr, result_t result);

  /**
   * Get the value of RDAC 1 (potentiometer channel 1)
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @return SUCCESS if the request was accepted
   */
  command result_t getPot1(uint8_t addr);
  /**
   * Result of the get operation with the value of the RDAC 1 potentiometer.
   *
   * @param addr Lower 2 bits (AD1,AD0) of the device I2C address
   * @param value A 256-bit value corresponding to the wiper position
   * @param result SUCCESS if the value was correctly obtained from the
   *               device.  If FAIL is returned, the value is not valid.
   */
  event void getPot1Done(uint8_t addr, uint8_t value, result_t result);
}
