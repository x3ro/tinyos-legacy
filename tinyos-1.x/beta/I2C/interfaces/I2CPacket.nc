// $Id: I2CPacket.nc,v 1.2 2004/02/11 23:52:11 idgay Exp $

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
interface I2CPacket
{
  /**
   * Reads a series of bytes from a slave device
   *
   * @param length the number of bytes to be read
   * @param flags bitmask that is defined:<br>
   * <table border=0>
   * <tr><td><code>I2C_NOACK_FLAG</code></td>
   * <td>By default, the master acks every byte except the last. Set
   *    I2C_NOACK_FLAG to disable these acks.</td></tr>
   * <tr><td><code>I2C_ACK_END_FLAG</code></td>
   * <td>Set this flag to ack the last byte read</td></tr>
   * <tr><td><code>I2C_ADDR_8BITS_FLAG</code></td>
   * <td>The slave address is a full eight bits, not seven and a read flag
   *    (this may not work with some lower-level I2C layers).</td></tr>
   * </table>
   *
   * @return SUCCESS if the request is accepted
   */
  command result_t readPacket(char *data, uint8_t length, uint8_t flags);

  /**
   * Writes a series of bytes to a slave device
   *
   * @param length the number of bytes to be written
   * @param data a pointer to the data to be written
   * @param flags bitmask that is defined:<br>
   * <table border=0>
   * <tr><td><code>I2C_ADDR_8BITS_FLAG</code></td>
   * <td>The slave address is a full eight bits, not seven and a read 
   * flag (this may not work with some lower-level I2C layers).</td></tr>
   * </table>
   *
   * @return SUCCESS if the request is accepted
   */
  command result_t writePacket(char *data, uint8_t length, uint8_t flags);  

  /**
   * Notifies that the bytes have been read from the slave device
   *
   * @param data a pointer to the bytes read from the bus
   * @param length number of bytes read
   * @param SUCCESS if the slave acknowledged its address, FAIL otherwise
   *   (in the latter case, no bytes will have been read and length will be 0)
   * @return Ignored.
   */
  event result_t readPacketDone(char *data, uint8_t length, result_t result);

  /**
   * Notifies that the bytes have been written to the slave device
   *
   * @param data pointer to bytes written to the bus
   * @param length number of bytes actually written. If a byte is not
   *   acknowledged, the transmission is aborted but that byte is included
   *   in the write count. So an unacknowledged address will lead to a
   *   length of 0, while if the nth byte is sent but not acknowledged, the
   *   length will be n.
   * @param result SUCCESS if the slave acknowledged all bytes, FAIL otherwise
   *
   * @return Ignored.
   */
  event result_t writePacketDone(char *data, uint8_t length, result_t result);
}
