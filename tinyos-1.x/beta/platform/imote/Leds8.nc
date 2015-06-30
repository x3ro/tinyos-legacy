/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Abstraction of the iMote LEDs.
 *
 */

interface Leds8 {

  /**
   * Initialize the LEDs; among other things, initialization turns
   * them all off.
   *
   * @return SUCCESS always.
   *
   */

  command result_t init();

  /**
   * Set specific led on
   *
   * @param bit ranging from 0 to 7 inclusive
   *
   * @return SUCCESS Always
   *
   */
   command result_t bitOn(uint8_t bit);

  /**
   * Set specific led off
   *
   * @param bit ranging from 0 to 7 inclusive
   *
   * @return SUCCESS Always
   *
   */
   command result_t bitOff(uint8_t bit);

  /**
   * Toggle specific led bit
   *
   * @param bit ranging from 0 to 7 inclusive
   *
   * @return SUCCESS Always
   *
   */
   command result_t bitToggle(uint8_t bit);

  /**
   * Get current Leds information
   *
   * @return A uint8_t typed value representing Leds status
   *
   */
   command uint8_t get();

  /**
   * Set Leds to a specified value
   *
   * @param value ranging from 0 to 255 inclusive
   *
   * @return SUCCESS Always
   *
   */
   command result_t set(uint8_t value);
}
