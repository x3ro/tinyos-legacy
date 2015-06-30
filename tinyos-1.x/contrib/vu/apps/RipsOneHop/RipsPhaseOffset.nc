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
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @modified 11/21/05
 */

/**
 * This interface is implemented by the RipsPhaseOffsetC component whose main
 * task is to perform a single ranging measurement. One measurement consists of
 * 
 * (1) sending out a synchronization message and do calibration (called tuning)
 * (2) collecting the tuning data and reporting calibration params to the master 
 * (3) sending out another synchronization message for the actual phase measurements
 * (4) each slave records its absolute phase for each channel
 * 
 * A header file acompanies this interface that describes the unit of channel,
 * frequency and amplitude reported by this interface.
 */
interface RipsPhaseOffset
{
	/**
	 * Must be called on the master node (A) to initiate the ranging procedure.
	 * The node ID of the assistant (B) - some node in the neighborhood of the
	 * master, must be specified. The caller must ensure that other nodes
	 * in an at least 2-3 hops range do not range simultaneously. The ranging 
	 * procedure might last up to a couple of seconds. Returns FAIL if the operation 
	 * cannot be initiated for some reason.
	 */
	command result_t startRanging(uint8_t seqNumber, uint16_t assistant);

	/**
	 * This event will be fired on the receiver nodes when the ranging begins.
	 * This should not post tasks, but just clear the state of the component.
	 * PhaseOffset component will reset the buffer of RSSILogger and will
	 * store data there, acknowledging the end of measurement by reportPhaseOffset
	 * event...
	 */
	event void measurementStarted(uint8_t seqNumber, uint16_t master, uint16_t assistant);

    /**
     * Fired on all nodes: master, assistant and receivers, to allow state-clearup.
     */
    async event void measurementEnded(result_t res);

	/**
	 * This event is fired on each slave node to report the frequency and 
	 * absolute phase offsets of the interference signal.
	 * The possible multiple phase measurements are buffered by RipsPhaseOffset
	 * componenet, stored in the buffer and reported when measurement ended.
	 * The format of the data depends on the type of the data collection, for
	 * RIPS type, uint8_t amplitude, uint8_t phaseOffset, uint16_t frequency
	 *are reported.

	 * The meaning of channel is user defined. 
	 * On the CC1000 chip we use channel 0 for 430.105543 MHz, and the channel
	 * separation is 526.6285 kHz. The absolute phase offset is measured in 
	 * modulo 256, i.e. 2*pi = 256. The frequency is measured in 1 Hz
	 * units. The amplitude is the amplitude of the envelope signal, the unit
	 * used here is implementation dependent. 

	 * Event is called on the nodes participating as receivers. NULL pointer 
	 * passed in buffer and 0 length indicate 
	 * that this node was not able to perform its role in the measurement and
	 * the whole measurement should be considered corrupted. A 
	 * task,  performing the data fusion, should be posted from this event.
	 */
	async event void reportPhaseOffsets(void *buffer, uint16_t length);

}
