/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL)
 * and Shockfish SA, Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   and Shockfish SA, nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */

/*
 * HPL for XE1205 access interface specification.
 *
 * @author Remy Blank
 * @author Henri Dubois-Ferriere
 *
 */

interface HPLXE1205 {



  /**
   * Write a sequence of configuration registers.
   *
   * The buffer contains a sequence of (address, value) pairs. The address
   * is already formatted as expected by the XE1205, i.e. the buffer is
   * transmitted as-is.
   */
  async command result_t writeConfig(uint8_t const* buffer_, int size_);

  /**
   * Read a sequence of configuration registers.
   *
   * The buffer must contain a sequence of addresses, formatted as expected
   * for reading from the XE1205. Each address is replaced by the value of
   * that register.
   */
  async command result_t readConfig(uint8_t* buffer_, int size_);


  /* 
   * These functions are used to reserve/release the bus and should be used 
   * before after any calls to writeData(), readData(), and readByteFast().
   * On a platform that has a dedicated bus to the XE1205, these would always 
   * return SUCCESS;
   */
  async command result_t getBus();
  async command result_t releaseBus();

  /**
   * The two functions below are same as writeConfig (resp. readConfig), except that the bus 
   * is assumed to be already reserved. 
   * They break the HPL model whereby the XE1205 code gets a platform-independent 
   * view of how the radio is interfaced, but this allows to significantly cut down 
   * overhead in highly timing-sensitive portions of XE1205RadioM.
   *
   **/
  async command result_t writeConfig_havebus(uint8_t const* buffer_, int size_);
  async command result_t readConfig_havebus(uint8_t* buffer_, int size_);

  /**
   * Write a sequence of data bytes to the output FIFO.
   *
   * Care must be taken not to overflow the FIFO (16 bytes).
   */
  async command result_t writeData(uint8_t const* buffer_, int size_);


  /**
   * Read a sequence of data bytes from the input FIFO.
   *
   * The FIFO level is not checked, and care must be taken not to underflow
   * the FIFO (16 bytes).
   */
  async command result_t readData(uint8_t* buffer_, int size_);

  /**
   * Read a single byte from the input FIFO.
   *
   * The FIFO level is not checked, and care must be taken not to underflow
   * the FIFO (16 bytes).
   */
  async command uint8_t readByteFast();
}

