//$Id: X1226.nc,v 1.2 2005/07/06 17:25:14 cssharp Exp $
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
 * Interface for X1226 Real Timer Clock/Calendar chip. <p>
 *
 * @modified 5/17/05
 *
 * @author Jaein Jeong
 */

interface X1226  {
  /**
   * Initiates a write of 1 byte data to the given address
   *
   * @param wordaddr the address of X1226 where data will be written.
   * @param bits 1 byte data to be written.
   * @return SUCCESS if X1226 is available for write
   */
  command result_t setRegByte(uint16_t wordaddr, uint8_t bits);
  /**
   * Initiates a write of 'datalen' byte data to the given address
   *
   * @param wordaddr the address of X1226 where data will be written.
   * @param datalen the length of data in bytes.
   * @param bits_array array of data bytes to be written.
   * @return SUCCESS if X1226 is available for write
   */
  command result_t setRegPage(uint16_t wordaddr, uint8_t datalen,
                              uint8_t *bits_array);
  /**
   * Initiates a read of 1 byte data from the given address
   *
   * @param wordaddr the address of X1226 where data will be read from.
   * @return SUCCESS if X1226 is available for read
   */
  command result_t getRegByte(uint16_t wordaddr);
  /**
   * Initiates a read of 'datalen' byte data from the given address
   *
   * @param wordaddr the address of X1226 where data will be read from.
   * @param datalen the length of data in bytes.
   * @return SUCCESS if X1226 is available for read
   */
  command result_t getRegPage(uint16_t wordaddr, uint8_t datalen);
  /**
   * Indicates that 1 byte data has been written as a result of 
   * <code>setRegByte()</code> command.
   *
   * @param result SUCCESS if 1 byte data is successfully written to
   * X1226 chip.
   */
  event void setRegByteDone(result_t result);
  /**
   * Indicates that n-byte data has been written as a result of 
   * <code>setRegPage()</code> command.
   *
   * @param result SUCCESS if n-byte data is successfully written to
   * X1226 chip.
   */
  event void setRegPageDone(result_t result);
  /**
   * Indicates that 1 byte data has been read as a result of 
   * <code>getRegByte()</code> command.
   *
   * @param databyte 1 byte data read from X1226 chip.
   * @param result SUCCESS if 1 byte data is successfully written to
   * X1226 chip.
   */
  event void getRegByteDone(uint8_t databyte, result_t result);
  /**
   * Indicates that n-byte data has been read as a result of 
   * <code>getRegPage()</code> command.
   *
   * @param datalen length of data read in bytes.
   * @param databytes array of data bytes read from X1226 chip.
   * @param result SUCCESS if 1 byte data is successfully written to
   * X1226 chip.
   */
  event void getRegPageDone(uint8_t datalen, uint8_t* databytes,
                            result_t result);
}
  
