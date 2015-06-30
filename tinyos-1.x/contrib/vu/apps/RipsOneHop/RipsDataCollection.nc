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
 * This interface is implemented by the RipsDataCollectionC component whose main
 * task is to perform an interference data collection in a setup described by 
 * RipsPhaseOffset component. Data is collected only by the slaves; 
 * different *data* types can be collected: 
 *      RAW_DATA    - raw RSSI samples (NUMBER_SAMPLES samples, each sample is 1 byte)
 *      RSSI_DATA   - averaged RSSI sample over NUMBER_SAMPLES (2 bytes)
 *      RIPS_DATA - amplitude(1 byte), phase(1 byte), frequency(2 bytes)
 * The types are set through DataCollectionParams(DCP) variable DCP.algorithmType and 
 * can be changed using remote data command.
 *
 * Also different *data collection* types are available:
 *      NO_HOP      - single data will be taken with the radio set to DCP.initialChannel, 
                      and DCP.initialTuning
 *      TUNE(_B)_HOP- a channel is fixed to DCP.channelA(B) and tuning being changed from
 *                    DCP.initialTuning to DCP.initialTuning + DCP.numTuneHops*DCP.tuningOffset
 *                    in DCP.TuningOffset steps. Data of type described above is collected
 *                    and reported via reportData event for each step.
 *      FREQ_HOP    - both channel and tuning are being changed: 
 *                    channel = DCP.initialChannel; channel += DCP.channelOffset;
 *                    tuning = calibratedTuning; tuning += calibratedTuningSkew; 
 *                           where calibrated* values are calculated during the TUNE_HOP stepping.
 *                    DCP.numChanHops steps are taken.
 *                    Data is reported via reportData() event for each step.
 *      EXACT_FREQS - exact frequencies are used
 *
 */
interface RipsDataCollection
{

    /**
     * Method for passing calibration parameters to the master node, so that it can set
     * is radio to transmit at a frequency close to the assistant's frequency.
     * 1.calibOffset is a tuning parameter for the master to transmit at the same frequency as
     *      assistant at DataCollectionParams.channelA frequency channel
     * 2.calibSkew specifies the change of tuning for different frequencies 
     * These two parameters must be calculated by the higher level component, for instance by
     * using TUNE_HOP data collection type, or provided from an external source (e.g. if motes
     * were precalibrated and the calibration data are stored in a database).
     */
     command void calibrationParamsSet(float calibSkew, int16_t calibOffset);
    
	/**
	 * Must be called on the master node (A) to initiate the data collection procedure.
	 * The node ID of the assistant (B, some node in the neighborhood of the
	 * master) must be specified. Returns FAIL if the operation 
	 * cannot be initiated for some reason. Parameters for transmission (remote command)
	 * need to be set before startCollection is called.
	 */
	command result_t startCollection(uint8_t seqNum, uint16_t assistant, uint8_t collectionType);

	/**
	 * This event will be fired on each participating node except for the master, 
	 * when the data collection begins.
	 * The slave nodes should return a buffer pointer where they want to store the 
	 * data. If 0 is returned, no data will be recorded. For the assistant it doesn't
	 * matter what it returns, since it does not collect data.
	 * (type&0x0F) is *data collection* type
	 * (type&0xF0) is *data* type
	 */
	event void *collectionStarted(uint8_t seqNumber, uint16_t master, uint16_t assistant, uint8_t type);

	/**
	 * This event is fired on each slave node to report the data that was
	 * collected.
	 * It is fired multiple times, depending on the number of data collection hops as defined
	 * in the current parameter set (DataCollectionParams).
	 * The buffer uses memory provided in collectionStarted() event, the buffer will be 
	 * reused in consequtive reportData() event  therefore the values need to be
	 * stored in the higher level component in the reportData() event handler.
	 * If buffer is 0, no data is reported.
	 * No tasks should be posted from this event.
	 */
	async event void reportData(void* buffer);

	/**
	 * Called on each of the participating nodes, including the master and 
	 * the assistant when the data collection terminated. FAIL indicates that this
	 * node was not able to perform its role in the data collection. 
	 */
	async event void collectionEnded(result_t success);
	
}
