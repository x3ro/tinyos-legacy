/**
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Andrew Christian <andrew.christian@hp.com>
 *         December 2004
 *
 *  Low-level interface to CC2420 chip
 */

includes Message;

interface CC2420LowLevel {
  /**
   * Send a command strobe
   * 
   * @return status byte from the chipcon
   */
  async command uint8_t cmd(uint8_t addr);

  /**
   * Transmit 16-bit data
   *
   * @return status byte from the chipcon.  0xff is return of command failed.
   */
  async command uint8_t write(uint8_t addr, uint16_t data);

  /**
   * Read 16-bit data
   *
   * @return 16-bit register value
   */
  async command uint16_t read(uint8_t addr);

  async command result_t readRAM( uint16_t addr, uint8_t length, uint8_t* buffer );
  async command result_t writeRAM( uint16_t addr, uint8_t length, uint8_t* buffer );

  async command result_t writeTXFIFO( struct Message * msg );

  async command void     openRXFIFO();
  async command void     closeRXFIFO();
  async command result_t readRXFIFO( uint8_t *data, int len );
  async command void     readRXFIFOsafe( uint8_t *data, int len );
}
