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


module AMReceiverM {
	provides {
		interface AMReceiver;
	}

	uses { 
		interface StdControl as AMRadioControl;
		interface StdControl as TPMControl;
		interface TPM;
		interface LocalCounter;
	}
}

implementation {

#define HEADERMASK 0xAAA4
#define FOOTERMASK 0x5555


	enum
	{	
		IDLE = 0,
		INIT = 1,
		HEADER = 2,
		DATA = 3,
	};

	uint8_t turnedOn = 0, currentState = IDLE;

	uint32_t expectedPulseWidth, deviation, timestamp, initBusClock, margin;

	uint16_t footerBuffer = 0, headerBuffer = 0;
	uint32_t firstReceiveBuffer = 0, secondReceiveBuffer = 0;

	
	///////////////////////////////////////////////////////////////////////
	// StdControl
	///////////////////////////////////////////////////////////////////////
	command result_t AMReceiver.init() {
		result_t result;

		// Initialize radio power pin
		result = call AMRadioControl.init();

		// Initialize timer port
		result *= call TPMControl.init();
	
		return result;
	}

	command result_t AMReceiver.start() {
		uint8_t divider, highPrecisionClock;
		result_t result;

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

		// new signal margin
		margin = initBusClock / 50;

		// Turn on timer port
		result *= call TPMControl.start();
		
		atomic turnedOn = 1;

		return result;
	}

	command result_t AMReceiver.stop() {
		result_t result;

		// Turn off radio
		result = call AMRadioControl.stop();

		// Turn off timer port
		result *= call TPMControl.stop();
	
		atomic turnedOn = 0;

		return result;
	}

	///////////////////////////////////////////////////////////////////////
	// Signal edge detected
	//
	// Manchester decode signal
	///////////////////////////////////////////////////////////////////////
	async event result_t TPM.signalReceived(uint8_t edge, uint32_t counter) {
		uint8_t i, par = 0;
		uint32_t result;

		if (turnedOn == 0) {
			return FAIL;
		}


		// new signal received
		if (currentState == IDLE || counter > margin) {

			timestamp = call LocalCounter.getLowCounter();

			headerBuffer = 0;
			firstReceiveBuffer = 0;
			secondReceiveBuffer = 0;

			footerBuffer = (edge ^ 0x01);

			currentState = INIT;
		
		} else if (currentState == INIT) {

			expectedPulseWidth = counter;
			deviation = (counter * 3) / 2;
			
			footerBuffer = (footerBuffer << 1) | (edge ^ 0x01);

			currentState = HEADER;

		} else if (currentState == HEADER) {

			if (counter < deviation) {
			
				expectedPulseWidth += counter;
				expectedPulseWidth /= 2;
				deviation = (expectedPulseWidth * 3) / 2;

				footerBuffer = (footerBuffer << 1) | (edge ^ 0x01);

				if ( (footerBuffer & 0xFFFC) == HEADERMASK) {
					currentState = DATA;
				} 

			} else {
			
				expectedPulseWidth += counter;
				expectedPulseWidth /= 3;
				deviation = (expectedPulseWidth * 3) / 2;

				footerBuffer = (footerBuffer << 1) | (edge ^ 0x01);

				if ( (footerBuffer & 0xFFFC) == HEADERMASK) {

					secondReceiveBuffer = footerBuffer >> 15;
					footerBuffer = (footerBuffer << 1) | (edge ^ 0x01);

					currentState = DATA;
				} else {

					footerBuffer = (footerBuffer << 1) | (edge ^ 0x01);

					if ( (footerBuffer & 0xFFFC) == HEADERMASK) {
						currentState = DATA;
					} 
				}
			} 

		} else if (currentState == DATA) {

			if (counter < deviation) {

				headerBuffer = (headerBuffer << 1) 
					     | (firstReceiveBuffer >> 31);

				firstReceiveBuffer = (firstReceiveBuffer << 1) 
						   | (secondReceiveBuffer >> 31);

				secondReceiveBuffer = (secondReceiveBuffer << 1)
						    | (footerBuffer >> 15);

				footerBuffer = (footerBuffer << 1) | (edge ^ 0x01);

			} else {

				headerBuffer = (headerBuffer << 2) 
					     | (firstReceiveBuffer >> 30);

				firstReceiveBuffer = (firstReceiveBuffer << 2) 
						   | (secondReceiveBuffer >> 30);

				secondReceiveBuffer = (secondReceiveBuffer << 2)
						    | (footerBuffer >> 14);

				footerBuffer = (footerBuffer << 1) | (edge ^ 0x01);
				footerBuffer = (footerBuffer << 1) | (edge ^ 0x01);

			} 

			if ( (headerBuffer & 0xFFFC) == HEADERMASK && footerBuffer == FOOTERMASK) {

				for (i = 0; i < 16; i++) {
					result = (result << 1) 
					| ((secondReceiveBuffer >> (i * 2)) & 0x01);
				}

				for (i = 0; i < 16; i++) {
					result = (result << 1) 
					| ((firstReceiveBuffer >> (i * 2)) & 0x01);
				}

				for (i = 0; i < 32; i++) {
					par ^= (result >> i) & 0x01;
				}

				if (par == (headerBuffer & 0x01) ) {
					signal AMReceiver.get(result, timestamp);
				} else {
					signal AMReceiver.get(0, 0);
				}

				currentState = IDLE;
				
				return SUCCESS;

			}


		} else {
		
			currentState = IDLE;
		
		}


		return SUCCESS;
	}
  
}
