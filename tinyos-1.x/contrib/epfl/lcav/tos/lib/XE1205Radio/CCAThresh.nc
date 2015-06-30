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
 * RSSI Threshold Estimator Interface
 *
 * @author Henri Dubois-Ferriere
 *
 */

interface CCAThresh
{
  /*
   * Reset estimator state.
   */
 command void reset();

  /*
   * Feed into RSSI estimator a new sample that was taken during a packet reception.
   */
 command void newRXSample(uint8_t rssi);

  /*
   * Feed into RSSI estimator a new sample that was (believed to be) taken during a 
   * clear channel period.
   * A good moment to measure the clear channel should be just after a packet transmission,
   * but of course the radio can not know for sure that the channel is clear.
   *
   */
 command void newClearSample(uint8_t rssi);
 
  /* 
   * Get the RSSI's current estimate for the 'clear threshold', ie the RSSI value below
   * which it is ok to transmit.
   * Note: For radio timing reasons, this command should return rapidly. 
   * So, if a component implementing this interface uses a CPU-intensive computation to 
   * establish the threshhold, it should be pre-computed (ie each time a new sample is added).
   */
  async command uint8_t getClearThresh();
}
