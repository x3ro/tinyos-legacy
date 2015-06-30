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
 * Date last modified:  8/20/02
 */

/**
 * The Pot interface allows users to adjust the potentiometer on the input
 * to the RFM radio which controls the RF transmit power or connectivity range.
 * The interface controls the potentiometer, rather than the signal strength,
 * so the settings may be a bit counterintuitive: the low potentiometer
 * settings correspond to high transmission power, and high potentiometer
 * settings correspond to low transmission power. Valid range depends on the
 * platform being used:  
 * <ul>
 * <li> <bold>Mica</bold> -- parameters range from 0 to 99; the actual
 * transmission range is heavily dependent on the antenna. With the built-in
 * antenna one can generally expect the range from 1 inch to 15 feet; with the
 * external antenna the range is from  1 foot to 100 feet.
 * <li> <bold>Rene</bold> -- parameters range from 20 to 77, though the exact
 * upper bound depends heavily on battery voltage. The exact range achieved
 * depends heavily on the battery used, but covers roughly the same range as
 * Mica (from 1 to 100 feet). <em> Let us emphasize this again: The exact low
 * transmission power bound for the Rene is dependent on battery voltage; it
 * is VERY difficult to get a reliable short range communication over an
 * extended time period without active control of the potentiometer. </em>
 * </ul> 
 * <em>Note:</em> the transmission power is NOT linear with respect to the
 * potentiometer setting; see mote schematics and RFM TR1000 manual for more
 * information. </p>
 * <em>Note:</em> any change to the potentiometer value will cause LEDs to
 * blink. This behavior is normal, expected, and unavoidable; at the end of
 * a potentiometer setting operation you may be left with an inconsistent LED
 * state, though the functions provided by the LED component will continue to
 * work correctly. 
 */

interface Pot {
    /** 
     * Initialize the potentiometer and set it to a specified value. 
     * @param initialSetting The initial value for setting of the signal
     * strength; see above for valid ranges and communication radii achieved
     * with them. 
     * @return Returns SUCCESS upon successful initialization. 
     */
  command result_t init(uint8_t initialSetting);

    /**
     * Set the potentiometer value
     * @param setting The new value of the potentiometer. 
     * @return Returns SUCCESS if the setting was successful.  The operation
     * returns FAIL if the component has not been initialized or the desired
     * setting is outside of the valid range. 
     */ 
  command result_t set(uint8_t setting);

    /** 
     * Increment the potentiometer value by 1. This function proves to be
     * quite useful in active potentiometer control scenarios.
     * @return Returns SUCCESS if the increment was successful. Returns FAIL
     * if the component has not been initialized or if the potentiometer
     * cannot be incremented further. 
     */ 
  command result_t increase();

    /** 
     * Decrement the potentiometer value by 1. This function proves to be
     * quite useful in active potentiometer control scenarios.
     * @return Returns SUCCESS if the decrement was successful. Returns FAIL
     * if the component has not been initialized or if the potentiometer
     * cannot be decremented further. 
     */ 
  command result_t decrease();

    /**
     * Return the current setting of the potentiometer. 
     * @return An unsigned 8-bit value denoting the current setting of the
     * potentiometer. 
     */
  command uint8_t get();
}

