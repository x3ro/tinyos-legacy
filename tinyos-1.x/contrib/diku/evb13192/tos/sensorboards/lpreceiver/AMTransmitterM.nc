/* Copyright (c) 2006, Marcus Chang
   All rights reserved.

   Redistribution and use in source and binary forms, with or without 
   modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer. 

    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution. 

    * Neither the name of the Dept. of Computer Science, University of 
      Copenhagen nor the names of its contributors may be used to endorse or 
      promote products derived from this software without specific prior 
      written permission. 

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
   POSSIBILITY OF SUCH DAMAGE.
*/  

/*
	Author:		Marcus Chang <marcus@diku.dk>
	Last modified:	June, 2006
*/


module AMTransmitterM {
	provides {
		interface AMTransmitter;
	}

	uses { 
		interface StdControl as AMRadioControl;
		interface StdControl as TPMControl;
		interface TPM;
		interface TPMTimer16 as TPMTimer;
	}
}

implementation {

	uint8_t bitCounter, center, divider;
	uint16_t baudrate = 100;
	uint32_t initBusClock = 1;

	enum
	{	
		IDLE = 0,
		HEADER = 1,
		DATA = 2,
		FOOTER = 3,
		END  = 4,
	};

	uint8_t currentState = IDLE, header = 0;
	uint32_t transmitBuffer;

	
	///////////////////////////////////////////////////////////////////////
	// StdControl
	//
	///////////////////////////////////////////////////////////////////////
	command result_t AMTransmitter.init() {
		result_t result;

		// Initialize radio power pin
		result = call AMRadioControl.init();

		// Initialize timer port
		result *= call TPMControl.init();
		
		PTBD_PTBD2 = 0;
		PTBDD_PTBDD2 = 1;

		return result;
	}

	command result_t AMTransmitter.start() {
		result_t result;
		uint8_t divider, highPrecisionClock;

		// Turn on radio
		result = call AMRadioControl.start();

		// set internal counters
		divider = call TPM.setClockSource(0);
		highPrecisionClock = call TPM.returnClockSource();
		
		if (highPrecisionClock == 1) {
			initBusClock = extClock / (2 * divider);
		} else {
			initBusClock = busClock / divider;
		}

		return result;
	}

	command result_t AMTransmitter.stop() {
		result_t result;

		// Turn off radio
		result = call AMRadioControl.stop();

		return result;
	}

	///////////////////////////////////////////////////////////////////////
	// Set baudrate
	///////////////////////////////////////////////////////////////////////
	command result_t AMTransmitter.setBaudrate(uint16_t rate) {

		baudrate = rate;
		
		return SUCCESS;
	}

	///////////////////////////////////////////////////////////////////////
	// Transmit 32-bit data
	///////////////////////////////////////////////////////////////////////
	command result_t AMTransmitter.put(uint32_t data) {
		uint8_t result, i, tmp, par = 0;
		
		if (currentState == IDLE) {
			transmitBuffer = 0xFFFFFFFF - data;

			for (i = 0; i < 32; i++) {
				par ^= (data >> i) & 0x01;
			}

			header = 0xFF - (par << 7) - (0x01 << 6);
			currentState = HEADER;
			bitCounter = 8;
			center = 0;

			result = call TPMTimer.start(initBusClock / (2 * baudrate));

			return SUCCESS;
		} else {
		
			return FAIL;
		}
	}

	///////////////////////////////////////////////////////////////////////
	// Timer fired - transmit next bit
	///////////////////////////////////////////////////////////////////////
	async event result_t TPMTimer.fired() {
		uint16_t tmp;

		if (currentState == HEADER) {

			// Manchester encoding of a single byte
			if (center == 0) {

				PTBD_PTBD2 = (header & 0x01);
				header = header >> 1;

				bitCounter--;
				center = 1;
			} else {
				// flip signal
				PTBD_PTBD2 ^= 0x01;

				// reset center flag
				center = 0;

				if (bitCounter == 0) {

					currentState = DATA;
					bitCounter = 32;
				}
			}
		
		} else if (currentState == DATA) {

			// Manchester encoding of a single byte
			if (center == 0) {

				PTBD_PTBD2 = (transmitBuffer & 0x01);
				transmitBuffer = transmitBuffer >> 1;

				bitCounter--;
				center = 1;
			} else {

				PTBD_PTBD2 ^= 0x01;
				center = 0;

				if (bitCounter == 0) {

					currentState = FOOTER;
					bitCounter = 8;	
				} 
			}
		
		} else if (currentState == FOOTER) {

			// Manchester encoding of a single byte
			if (center == 0) {

				PTBD_PTBD2 = 0;

				bitCounter--;
				center = 1;
			} else {
				PTBD_PTBD2 ^= 0x01;
				center = 0;

				if (bitCounter == 0) {

					currentState = END;
				}
			}

		} else if (currentState == END) {

			PTBD_PTBD2 = 0;
			call TPMTimer.stop();

			currentState = IDLE;

			signal AMTransmitter.putDone();

		}

		
		return SUCCESS;	
	}

	async event result_t TPM.signalReceived(uint8_t edge, uint32_t counter) { 
		return SUCCESS; 
	}  
}
