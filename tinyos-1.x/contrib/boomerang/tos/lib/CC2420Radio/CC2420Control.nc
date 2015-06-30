/*
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
 */

/**
 * CC2420 Radio Control interface.
 * Interface for CC2420 specific controls and signals
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface CC2420Control
{
  /**
   * Tune the radio to one of the 802.15.4 present channels.
   * Valid channel values are 11 through 26.
   * The channels are calculated by:
   *  Freq = 2405 + 5(k-11) MHz for k = 11,12,...,26
   * 
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   * @param freq requested 802.15.4 channel
   * 
   * @return Status of the tune operation
   */
  command result_t TunePreset( uint8_t rh, uint8_t channel );

  /**
   * Tune the radio to a given frequency. Frequencies may be set in
   * 1 MHz steps between 2400 MHz and 2483 MHz
   * 
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   * @param freq The desired channel frequency, in MHz.
   * 
   * @return Status of the tune operation
   */
  command result_t TuneManual( uint8_t rh, uint16_t freq );

  /**
   * Get the current channel of the radio
   *
   * WARNING: If running the CC2420 on a non-standard IEEE 802.15.4
   * frequency, this function will return the closest possible 
   * valid IEEE 802.15.4 channel even if the current frequency in use is not
   * a valid IEEE 802.15.4 frequency
   *
   * @return The current CC2420 channel (k=11..26)
   */
  command uint8_t GetPreset();

  /**
   * Get the current frequency of the radio
   *
   * @return The current CC2420 frequency in MHz
   */
  command uint16_t GetFrequency();

  /**
   * Turns on the 1.8V references on the CC2420.
   *
   * @return SUCCESS if the VREF has been turned on
   */
  async command result_t VREFOn();

  /**
   * Turns off the 1.8V references on the CC2420.
   *
   * @return SUCCESS if the VREF has been turned on
   */
  async command result_t VREFOff();

  /**
   * Turn on the crystal oscillator.
   *
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   *
   * @return SUCCESS if the request for the crystal to start has been accepted
   */
  async command result_t OscillatorOn( uint8_t rh );

  /**
   * Turn off the crystal oscillator.
   *
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   *
   * @return SUCCESS when the oscillator has started up
   */
  async command result_t OscillatorOff( uint8_t rh );

  /**
   * Shift the CC2420 Radio into transmit mode.
   *
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   *
   * @return SUCCESS if the radio was successfully switched to TX mode.
   */
  async command result_t TxMode( uint8_t rh );

  /**
   * Shift the CC2420 Radio into transmit mode when the next clear channel
   * is detected.
   *
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   *
   * @return SUCCESS if the transmit request has been accepted
   */
  async command result_t TxModeOnCCA( uint8_t rh );

  /**
   * Shift the CC2420 Radio in receive mode.
   *
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   *
   * @return SUCCESS if the radio was successfully switched to RX mode.
   */
  async command result_t RxMode( uint8_t rh );

  /**
   * Set the transmit RF power value.  
   * The input value is simply an arbitrary
   * index that is programmed into the CC2420 registers.  
   * The output power is set by programming the power amplifier.
   * Valid values are 1 through 31 with power of 1 equal to
   * -25dBm and 31 equal to max power (0dBm)
   *
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   * @param power A power index between 1 and 31
   * 
   * @return SUCCESS if the radio power was adequately set.
   *
   */
  command result_t SetRFPower( uint8_t rh, uint8_t power );

  /**
   * Get the present RF power index.
   *
   * @return The power index value.
   */
  command uint8_t GetRFPower();

  /**
   * Enables auto ack on the CC2420
   * 
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   *
   * @return SUCCESS if the mode of the CC2420 was successfully changed
   */
  async command result_t enableAutoAck( uint8_t rh );

  /**
   * Disables auto ack on the CC2420
   * 
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   *
   * @return SUCCESS if the mode of the CC2420 was successfully changed
   */
  async command result_t disableAutoAck( uint8_t rh );

  /**
   * Enables address decoding on the CC2420
   *
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   *
   * @return SUCCESS if the mode of the CC2420 was successfully changed
   */
  async command result_t enableAddrDecode( uint8_t rh );

  /**
   * Disables address decoding on the CC2420
   *
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   *
   * @return SUCCESS if the mode of the CC2420 was successfully changed
   */
  async command result_t disableAddrDecode( uint8_t rh );

  /**
   * Set the 16-bit short address of the mote
   *
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   * @param addr 16-bit address
   *
   * @return SUCCESS if the request to set the address is being processed
   */
  command result_t setShortAddress( uint8_t rh, uint16_t addr );
}

