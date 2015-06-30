/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
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
 *
 * - Description ---------------------------------------------------------
 * Interface for controlling the LEDs on the Infineon board
 * Based on the original interface Leds
 * The board has four LEDs named: led0, led1, led2 and led3
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/01/26 14:13:59 $
 * @author: Vlado Handziski
 * ========================================================================
 */

interface LedsNumbered {

  /**
   * Initialize the LEDs; among other things, initialization turns
   * them all off.
   *
   * @return SUCCESS always.
   *
   */

  async command result_t init();

  /**
   * Turn the led0 LED on.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led0On();

  /**
   * Turn the led0 LED off.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led0Off();

  /**
   * Toggle the led0 LED. If it was on, turn it off. If it was off,
   * turn it on.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led0Toggle();

  /**
   * Turn the led1 LED on.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led1On();

  /**
   * Turn the led1 LED off.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led1Off();

  /**
   * Toggle the led1 LED. If it was on, turn it off. If it was off,
   * turn it on.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led1Toggle();

  /**
   * Turn the led2 LED on.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led2On();

  /**
   * Turn the led2 LED off.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led2Off();

  /**
   * Toggle the led2 LED. If it was on, turn it off. If it was off,
   * turn it on.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led2Toggle();

  /**
   * Turn the led3 LED on.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led3On();

  /**
   * Turn the led3 LED off.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led3Off();

  /**
   * Toggle the led3 LED. If it was on, turn it off. If it was off,
   * turn it on.
   *
   * @return SUCCESS always.
   *
   */
  async command result_t led3Toggle();

  /**
   * Get current Leds information
   *
   * @return A uint8_t typed value representing Leds status
   *
   */
   async command uint8_t get();

  /**
   * Set Leds to a specified value
   *
   * @param value ranging from 0 to 15 inclusive
   *
   * @return SUCCESS Always
   *
   */
   async command result_t set(uint8_t value);
}
