/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * MSP430I2CPacket provides commands for reading and writing a series of
 * bytes across an I2C interface.
 * <p>
 * <b> You must acquire a handle for the I2C interface before using it,
 * otherwise your operations will fail.</b> Use the 
 * <code>I2CResourceC</code> generic component to request the resource
 * when it is needed.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface MSP430I2CPacket {
  /**
   * Read a packet from the device at address <code>addr</code> on the I2C bus.
   *
   * @param rh Resource handle for the I2C bus is required before use.
   * @param addr Address of the slave I2C device.
   * @param length Number of bytes to read from the device.
   * @param data Pointer to the location where data should be stored.
   *
   * @return SUCCESS if the operation has successfully started.
   */
  command result_t readPacket( uint8_t rh, uint16_t addr, uint8_t length, uint8_t* data );
  /**
   * Write a packet to a device at address <code>addr</code> on the I2C bus.
   *
   * @param rh Resource handle for the I2C bus is required before use.
   * @param addr Address of the slave I2C device.
   * @param length Number of bytes to write to the device.
   * @param data Pointer to the location of data to send.
   *
   * @return SUCCESS if the operation has successfully started.
   */
  command result_t writePacket( uint8_t rh, uint16_t addr, uint8_t length, uint8_t* data );

  /**
   * Notification that the read operation has completed.  Check the
   * result value to see if it was successful.
   *
   * @param addr Address of the slave I2C device.
   * @param length Number of bytes to write to the device.
   * @param data Pointer to the location where data should be stored.
   * @param success Result of the operation.
   */
  event void readPacketDone(uint16_t addr, uint8_t length, uint8_t* data, result_t success);
  /**
   * Notification that the write operation has completed.  Check the
   * result value to see if it was successful.
   *
   * @param addr Address of the slave I2C device.
   * @param length Number of bytes to write to the device.
   * @param data Pointer to the location of data to send.
   * @param success Result of the operation.
   */
  event void writePacketDone(uint16_t addr, uint8_t length, uint8_t* data, result_t success);
}
