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

interface RSSIEngine
{
	/**
	 * This event is fired after the completion of each command.
	 */
	async event void done(result_t success);
	
	/**
	 * Initiates the synchronization of the current node and its
	 * neighbors. A message is sent, and a common timeline is
	 * established. Works multihop. Forwards TS up to numHops hops away.
	 */
	async command void sendSyncMH(void *data, uint8_t length, uint8_t numHops);

	/**
	 * On the neighbors this event is called when the synchronization
	 * message is received.
	 */
	event result_t receiveSync(uint8_t sender, void *data, uint8_t length); 

	/**
	 * Returns the elapsed time since the last sync point/command.
	 */
	async command int32_t getElapsedTime();

	/**
	 * Resets the elapsed time to zero.
	 */
	async command void resetElapsedTime();

	/**
	 * Schedules the next alarm relative to the previous time
	 * and then the done event is fired.
	 */
	async command void wait(uint32_t delay);

	/**
	 * Acquires the radio, updates the timeline with the expected
	 * execution time and signals the done event.
	 */
	async command void acquire();

	/**
	 * Restores the radio, updates the timeline with the expected
	 * execution time and signals the done event.
	 */
	async command void restore();

	/**
	 * Calibrates the radio and adjusts the timeline with the
	 * nominal required time.
	 */
	async command void calibrateTransmit(int8_t channel);

	/**
	 * Calibrates the radio and adjusts the timeline with the
	 * nominal required time.
	 */
	async command void calibrateReceive(int8_t channel);

	/**
	 * Transmits an unmodulated signal so that the receivers
	 * can sample 64 samples and take the sum of the RSSI values.
	 */
	async command void transmitBlock(uint8_t strength, int16_t tuning);

	/**
	 * Suspends the transmission or reception for the same amount of 
	 * time the transmitBlock takes.
	 */
	async command void suspendBlock();
	
	/**
	 * Samples the channel and computes the signal strength from 64
	 * samples, then stores it at the provided address.
	 */
	async command void rssiBlock(uint8_t *sample);

	/**
	 * Samples the channel and stores 64 samples in the provided
	 * buffer.
	 */
	async command void recordBlock(uint8_t *buffer);

	/**
	 * Samples the channel and computes the frequency and phase offset
	 * of the interference signal based on min/max threshold detection
	 * The buffer will contain the following information:
	 * byte    0.: phase (0=0 rad, 255=2*PI rad)
	 * byte    1.: amplitude (0-255)
	 * bytes 2-3.: frequency (valid range: (0)0Hz - (65535)2048 Hz)
	 */
	async command void ripsBlock(uint8_t *buffer);
}
