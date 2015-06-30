/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL)
 * and Shockfish SA, Switzerland.
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   and Shockfish SA, nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
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
 * ========================================================================
 */


/*
 * XE1205 configuration interface specification.
 *
 * @author Remy Blank
 * @author Henri Dubois-Ferriere
 *
 */

interface XE1205Control {
        /**
         * Set a register in the XE1205.
	 * @result SUCCESS if the setting was correctly made.
         */
        async command result_t SetRegister(uint8_t address_, uint8_t value_);

        /**
         * Get the value of a register.
         *
         * Register values are cached, so this call doesn't require communicating
         * with the XE1205.
         */
        command uint8_t GetRegister(uint8_t address_);

        /**
         * Tune the XE1205 to operate on the specified frequency.
         *
         * @param value_ Frequency in Hz
         */
        command result_t TuneManual(uint32_t value_);

        /**
         * Tune the XE1205 to operate on a preset channel.
	 * @param index_ Channel index:
	 * 0 -> 867MHz
	 * 1 -> 868MHz
	 * 2 -> 869Mhz
         */
        command result_t TunePreset(uint8_t index_);

        /**
         * Set the output power of the XE1205.
         *
         * @param index_ Power index as per TXParam_POWER in XE1205 datasheet: 
	 * 0 -> 0dBm
	 * 1 -> 5dBm
	 * 2 -> 10dBm
	 * 3 -> 15dBm
         */
        command result_t SetRFPower(uint8_t index_);

        /**
         * Read the (cached) power setting.
         */
        command uint8_t GetRFPower();

        /**
         * Set the raw communication bitrate. The frequency deviation and receiver 
	 * filter bandwidth are also set to appropriate values for the bitrate. Advanced users 
	 * can still override the freq. dev and bw values with the individual functions below.
	 *
         * @param value_ Bitrate  (min 1190 bps, max 152340 bps)
         */
        command result_t SetBitrate(uint32_t value_);

        /**
         * Set the transmitter frequency deviation.
         *
         * @param value_ Frequency deviation in Hz (max 250Khz).
         */
        command result_t SetFrequencyDeviation(uint32_t value_);

        /**
         * Set the baseband filter bandwidth.
         *
         * @param value_ Filter bandwidth in kHz (max 400).
         */
        command result_t SetBasebandBandwidth(uint16_t value_);

        /**
         * Set LNA amplifier mode.
         *
         * @param value_ 0: Mode A (high sensitivity), 1: Mode B (high linearity)
         */
        command result_t SetLnaMode(uint16_t value_);

        /**
         * Enable / disable buffered mode.
	 * @param mode: 1 for buffered, 0 for continuous
         */
        command result_t SetBufferedMode(bool mode);

        /**
         * Power down the XE1205.
         */
        async command result_t SleepMode();

        /**
         * Set the XE1205 to standby mode, i.e. oscillator running but everything else disabled.
         */
        async command result_t StandbyMode();

        /**
         * Set the XE1205 to receive mode.
         */
        async command result_t RxMode();

        /**
         * Set the XE1205 to transmit mode.
         */
        async command result_t TxMode();

        /**
         * Disconnect the antenna from both receiver and transmitter.
         */
        async command result_t AntennaOff();

        /**
         * Connect the antenna to the receiver.
         */
        async command result_t AntennaRx();
        
        /**
         * Connect the antenna to the transmitter.
         */
        async command result_t AntennaTx();


	/** 
	 * Return the returns the period (in us) between two successive rssi measurements, 
	 * taking into account the current setting of the frequency deviation.
	 */
	async command uint16_t GetRssiMeasurePeriod_us();


	/** 
	 * Returns the time (in us) to send/receive a byte at current bit rate.
	 */
	async command uint16_t GetByteTime_us();

	/** 
	 * The functions below should ONLY BE USED INSIDE THE RADIO DRIVER.
	 * Never use them anywhere else -- it may interfere with the 
	 * proper functioning of the radio stack and/or bus arbitration, and hose your node.
	 */

        /**
         * Clear FIFO overrun flag.
         */
        async command result_t ClearFifoOverrun();

        /**
         * Arm the pattern detector (clear Start_detect flag).
         */
        async command result_t ArmPatternDetector();

	/**
	 * Enable RSSI measurements.
	 *
	 * @param on: 1 to enable, 0 to disable
	 */
	async command result_t SetRssiMode(bool on);

	/**
	 * Set RSSI measurement points to low/high values at 
	 * 
	 * @param high: 1 for high range (-95, -90, -85 dBm)
	 *              0 for low range (-110, -105, -100 dBm)
	 */
	async command result_t SetRssiRange(bool high);

	/**
	 * Get current RSSI measurement range 
	 * 
	 * @result 1 for high range (-95, -90, -85 dBm)
	 *         0 for low range (-110, -105, -100 dBm)
	 */
	async command bool GetRssiRange();



	/** 
	 * Read RSSI value in 2 bits. RSSI block should be enabled before calling this.
	 **/
	async command result_t GetRssi(uint8_t* rssi);



	/** 
	 * Load data pattern (defined in XE1205Const.h) into XE1205 pattern detection register.
	 **/
	async command result_t loadDataPattern();
	/** 
	 * Load LPL pattern (defined in XE1205Const.h) into XE1205 pattern detection register.
	 **/
	async command result_t loadLPLPattern();
	/** 
	 * Load Ack pattern (defined in XE1205Const.h) into XE1205 pattern detection register.
	 **/
	async command result_t loadAckPattern();
}

