//$Id: BytePort.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
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
 * Interface for a byte port. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

interface BytePort {
  /**
   * Initiates a write of 1 byte data to the given port.
   *
   * @return SUCCESS if the write is successfully initiated.
   */
  command result_t setPort(uint8_t bits);
  /**
   * Indicates that the write to the port is done.
   *
   * @return SUCCESS if the write is successfully done.
   */
  event void setPortDone(result_t result);
  /**
   * Initiates a read of 1 byte data from the given port.
   *
   * @return SUCCESS if the read is successfully initiated.
   */
  command result_t getPort();
  /**
   * Indicates that the read from the port is done.
   *
   * @return SUCCESS if the read is successfully done.
   */
  event void getPortDone(uint8_t bits, result_t result);

}
