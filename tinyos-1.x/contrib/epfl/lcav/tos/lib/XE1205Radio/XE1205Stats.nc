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

/**
 *
 * XE1205 Link-layer statistics interface
 * @author Henri Dubois-Ferriere 
 *
 */
interface XE1205Stats
{

  command void resetStats();
  
  /*
   * Total number of bytes transmitted (including preamble bytes, ACK bytes, ..).
   */
  command uint32_t bytesTX();

  /*
   * Total number of packets transmitted.
   */  
  command uint32_t pktsTX();

  /*
   * Total number of bytes received (including preamble bytes, ACK bytes, ..).
   */  
  command uint32_t bytesRX();

  /*
   * Total number of packets received without errors.
   */  
  command uint32_t pktsRX();

  /*
   * Total number of packets received with CRC errors.
   */  
  command uint16_t crcErrsRX();

  /* 
   * Number of unacknowledged packets (packets sent to a unicast 
   * address for which we got no ACK, when ACKs were enabled).
   */
  command uint16_t pktsNotAcked();

}
