/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 02/02/04
 */

interface RSSIDriver
{
	/**
	 * Disconnects the radio chip from the standard MAC layer,
	 * Resets the radio and brings it to suspend state where it 
	 * can quickly transmit or receive.
	 */
	command result_t acquire();

	/**
	 * Retores the radio chip to its normal state and restarts the
	 * standard MAC layer.
	 */
	command result_t restore();

	/**
	 * Calibrates the radio to transmit within the selected channel.
	 * The representation of the channel value is platform dependent.
	 */
	command result_t calibrateTransmit(int8_t channel);

	/**
	 * Transmits an unmodulated sine wave at the given channel.
	 * The strength and frequency offset representation is platform 
	 * dependent. 
	 */
	async command result_t transmit(uint8_t strength, int16_t tuning);

	/**
	 * Calibrates the radio to receive in the selected channel.
	 * The representation of the channel value is platform dependent.
	 */
	command result_t calibrateReceive(int8_t channel);

	/**
	 * Sets the radio chip to receive state to measure the signal
	 * strength of unmodulated signals in the selected channel.
	 */
	async command result_t receive();

	/**
	 * Returns the radio to suspend state, neither sending nor receiving,
	 * but it can quickly turned to transmit or receive.
	 */
	async command result_t suspend();
}
