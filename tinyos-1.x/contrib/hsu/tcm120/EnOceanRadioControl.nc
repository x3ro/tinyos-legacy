/* 
 * Copyright (c) Helmut-Schmidt-University, Hamburg
 *		 Dpt.of Electrical Measurement Engineering  
 *		 All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Helmut-Schmidt-University nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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

 * @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 * $Revision: 1.1 $
 *
 */

interface EnOceanRadioControl
{
  /**
   * put the EnOceanRadi into transmit mode.
   *
   * @return SUCCESS if the radio was successfully switched to TX mode.
   */

  async command result_t TxMode();

  /**
   * put  the CC1000 Radio in receive mode.
   *
   * @return SUCCESS if the radio was successfully switched to RX mode.
   */

  async command result_t RxMode();

  /**
   * configure the EnOceanRadio RFGain.
   *
   *     sensitivity == 1 -> high gain mode
   *     sensitivity == 0 -> low gain mode
   *                         gain is reduced by approximately 18 dB                   
   * 
   * @return SUCCESS allways.
   */

  async command result_t ConfigureRFGain(uint8_t  sensitivity);

}
