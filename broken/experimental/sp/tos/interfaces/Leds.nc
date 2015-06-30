/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 *
 */

/**
 * Abstraction of the LEDs.
 *
 */

interface Leds {

  /**
   * Initialize the LEDs; among other things, initialization turns
   * them all off.
   *
   * @return SUCCESS always.
   *
   */
  
  command result_t init();

  /**
   * Turn the red LED on.
   *
   * @return SUCCESS always.
   *
   */
  command result_t redOn();

  /**
   * Turn the red LED off.
   *
   * @return SUCCESS always.
   *
   */
  command result_t redOff();

  /**
   * Toggle the red LED. If it was on, turn it off. If it was off,
   * turn it on.
   *
   * @return SUCCESS always.
   *
   */
  command result_t redToggle();

  /**
   * Turn the green LED on.
   *
   * @return SUCCESS always.
   *
   */
  command result_t greenOn();

  /**
   * Turn the green LED off.
   *
   * @return SUCCESS always.
   *
   */
  command result_t greenOff();

  /**
   * Toggle the green LED. If it was on, turn it off. If it was off,
   * turn it on.
   *
   * @return SUCCESS always.
   *
   */
  command result_t greenToggle();

  /**
   * Turn the yellow LED on.
   *
   * @return SUCCESS always.
   *
   */
  command result_t yellowOn();

  /**
   * Turn the yellow LED off.
   *
   * @return SUCCESS always.
   *
   */
  command result_t yellowOff();

  /**
   * Toggle the yellow LED. If it was on, turn it off. If it was off,
   * turn it on.
   *
   * @return SUCCESS always.
   *
   */
  command result_t yellowToggle();
  
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
   * @param value ranging from 0 to 7 inclusive
   *
   * @return SUCCESS Always
   *
   */
   command result_t set(uint8_t value);
}
