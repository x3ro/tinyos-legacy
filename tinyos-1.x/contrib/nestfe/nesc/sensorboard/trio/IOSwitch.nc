//$Id: IOSwitch.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/**
 * Interface for PCA9555 I2C switch chip. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

interface IOSwitch {
  /**
   * Initiates the setting or clearing for a given bit position 
   * in port 0.
   * @param mask a bit-mask that contains 1-bit for the bit position to
   * be updated.
   * @high If TRUE, sets the bit position. 
   * If FALSE, clears the bit position.
   * @return SUCCESS if the port update is successfully initiated.
   */
  command result_t setPort0Pin(uint8_t mask, bool high);
  /**
   * Initiates the setting or clearing for a given bit position
   * in port 1.
   * @param mask a bit-mask that contains 1-bit for the bit position to
   * be updated.
   * @high If TRUE, sets the bit position.
   * If FALSE, clears the bit position.
   * @return SUCCESS if the port update is successfully initiated.
   */
  command result_t setPort1Pin(uint8_t mask, bool high);
  /**
   * Initiates a write to port 0 and 1.
   * @param bits the 2-byte data to be written.
   * @return SUCCESS if the port update is successfully initiated.
   */
  command result_t setPort(uint16_t bits);
  /**
   * Initiates a read from port 0 and 1.
   * @return SUCCESS if the port read is successfully initiated.
   */
  command result_t getPort();
  /**
   * Indicates that the port update is done.
   * @param result SUCCESS if the port update is successfully done.
   */
  event void setPortDone(result_t result);
  /**
   * Indicates that the port read is done.
   * @param bits the data read from the port.
   * @param result SUCCESS if the port read is successfully done.
   */
  event void getPortDone(uint16_t bits, result_t result);
}



