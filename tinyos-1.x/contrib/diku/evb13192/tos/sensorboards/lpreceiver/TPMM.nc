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


module TPMM {
	provides {
		interface StdControl;
		interface TPM;
		interface TPMTimer16;
		interface TPMTimer32;
		interface LocalCounter;
	}
}

implementation {

	void bigTimerFired();
	
	default async event result_t TPM.signalReceived(uint8_t edge, uint32_t counter) { return FAIL; }
	default async event result_t TPMTimer16.fired() {return FAIL;}
	default async event result_t TPMTimer32.fired() {return FAIL;}

	enum
	{	
		SCM = 0x00,
		FEI = 0x01,
		FBE = 0x02,
		FEE = 0x03
	};

	uint8_t init = 1, bigAlarmEnable = 0;
	uint16_t carryCounter = 0;
	uint32_t highCounter = 0, lowCounter = 0, interuptCounter = 0;
	uint32_t bigAlarmInterval, bigAlarm, smallAlarmInterval;

	command result_t StdControl.init() 
	{

		/////////////////////////////////////////////////
		// allow only ONE call to init()
		/////////////////////////////////////////////////
		if (init == 1) {
			init = 0;
		} else {
			return FAIL;
		}

		///////////////////////////
		// Set timers correctly
		///////////////////////////
		
		// enable software pull-up
		PTDDD_PTDDD2 = 0;
		PTDPE_PTDPE2 = 1;
		

		// When CPWMS = 0:
		// MS2B:MS2A = 00 : Input Capture
		// MS2B:MS2A = 01 : Output Compare
		// MS2B:MS2A = 1x : Edge aligned PWM
		// ELS2B:ELS2A = 01: Rising Edge 
		// ELS2B:ELS2A = 10: Falling Edge 
		// ELS2B:ELS2A = 11: Both Rising and Falling Edges

		// set timer 1 channel 0 to output compare
		atomic {
			TPM1C0SC_CH0IE = 0;
			TPM1C0SC_MS0B = 0;
			TPM1C0SC_MS0A = 1;
			TPM1C0SC_ELS0B = 0;
			TPM1C0SC_ELS0A = 0;
		}

		// set timer 1 channel 1 to output compare
		atomic {
			TPM1C1SC_CH1IE = 0;
			TPM1C1SC_MS1B = 0;
			TPM1C1SC_MS1A = 1;
			TPM1C1SC_ELS1B = 0;
			TPM1C1SC_ELS1A = 0;
		}

		// set timer 1 channel 2 to input capture on both edges
		atomic {
			TPM1C2SC_CH2IE = 0;
			TPM1C2SC_MS2B = 0;
			TPM1C2SC_MS2A = 0;
			TPM1C2SC_ELS2B = 1;
			TPM1C2SC_ELS2A = 1;
		}
		
		return SUCCESS;
	}

	command result_t StdControl.start() {
		
		// enable interupt on input pin
		atomic {
			TPM1C2SC_CH2F = 0;
			TPM1C2SC_CH2IE = 1;
		}

		return SUCCESS;
	}
	
	command result_t StdControl.stop() {

		// disable interupt on input pin
		atomic {
			TPM1C2SC_CH2IE = 0;
		}
		
		return SUCCESS;
	}

	/////////////////////////////////////////////////////////////////////////////
	// 
	/////////////////////////////////////////////////////////////////////////////
	command uint8_t TPM.returnClockSource() {

		if (TPM1SC_CLKSB == 1 || TPM1SC_CLKSA == 0) {
			return 1;
		} else if (TPM1SC_CLKSB == 0 || TPM1SC_CLKSA == 1) {
			return 0;
		} else {
			return 2;
		}
	}

	command uint8_t TPM.setClockSource(uint8_t source) {

		// Timer x Status and Control Register (TPMxSC)
		// Bit 7 6 5 4 3 2 1 0
		// TOF TOIE CPWMS CLKSB CLKSA PS2 PS1 PS0

		// external source available - use fixed system clock
		if ( (ICGS1_CLKST == FBE || ICGS1_CLKST == FEE) && source == 1) {

			// set divider to assure at least 1ms resolution		
			if ( (extClock / 2) > 128000) {

				atomic {
					TPM1SC_TOIE = 1;
					TPM1SC_CPWMS = 0;
					TPM1SC_CLKSB = 1;
					TPM1SC_CLKSA = 0;
					TPM1SC_PS2 = 1;
					TPM1SC_PS1 = 1;
					TPM1SC_PS0 = 1;
				}

				return 128;

			} else {

				atomic {
					TPM1SC_TOIE = 1;
					TPM1SC_CPWMS = 0;
					TPM1SC_CLKSB = 1;
					TPM1SC_CLKSA = 0;
					TPM1SC_PS2 = 0;
					TPM1SC_PS1 = 0;
					TPM1SC_PS0 = 0;
				}

				return 1;
			}


		// use internal clock (busclock) as source
		} else {

			// set divider to assure at least 1ms resolution		
			if (busClock > 128000) {
		
				atomic {
					TPM1SC_TOIE = 1;
					TPM1SC_CPWMS = 0;
					TPM1SC_CLKSB = 0;
					TPM1SC_CLKSA = 1;
					TPM1SC_PS2 = 1;
					TPM1SC_PS1 = 1;
					TPM1SC_PS0 = 1;
				}

				return 128;

			} else {
				atomic {
					TPM1SC_TOIE = 1;
					TPM1SC_CPWMS = 0;
					TPM1SC_CLKSB = 0;
					TPM1SC_CLKSA = 1;
					TPM1SC_PS2 = 0;
					TPM1SC_PS1 = 0;
					TPM1SC_PS0 = 0;
				}
			
				return 1;
			}

		}
		
	}


	/////////////////////////////////////////////////////////////////////////////
	// Timer 16 bit
	/////////////////////////////////////////////////////////////////////////////
	command result_t TPMTimer16.start(uint16_t interval) {
		uint16_t smallCounter;
		
		smallAlarmInterval = interval;
		
		atomic {
			smallCounter = TPM1CNTH;
			smallCounter = (smallCounter << 8) + TPM1CNTL;
			
			smallCounter += interval;
		
			// set timer
			TPM1C1VH = smallCounter >> 8;
			TPM1C1VL = smallCounter;

			// enable interupt
			TPM1C1SC_CH1F = 0;
			TPM1C1SC_CH1IE = 1;
		}

		return SUCCESS;
	}

	command result_t TPMTimer16.stop() {

		atomic {
			smallAlarmInterval = 0;

			// disable interupt
			TPM1C1SC_CH1IE = 0;
			TPM1C1SC_CH1F = 0;
		}

		return SUCCESS;
	}

	/////////////////////////////////////////////////////////////////////////////
	// Timer 32 bit
	/////////////////////////////////////////////////////////////////////////////
	command result_t TPMTimer32.start(uint32_t interval) {
		uint32_t sum;
		uint16_t smallCounter;

		bigAlarmInterval = interval;
		
		atomic {
			smallCounter = TPM1CNTH;
			smallCounter = (smallCounter << 8) + TPM1CNTL;
		
			sum = bigAlarmInterval + smallCounter;

			// check for overflow
			if (sum < bigAlarmInterval) {
			
				return FAIL;
			
			} else if (sum < 0x00010000) {

				// set timer
				TPM1C0VH = sum >> 8;
				TPM1C0VL = sum;

				// enable interupt
				TPM1C0SC_CH0F = 0;
				TPM1C0SC_CH0IE = 1;
			} else {

				bigAlarm = sum;
			}

			bigAlarmEnable = 1;
		}

		return SUCCESS;
	}


	command result_t TPMTimer32.stop() {
	
		// disable big timer interupt
		atomic {
			TPM1C0SC_CH0IE = 0;
			TPM1C0SC_CH0F = 0;
			bigAlarmEnable = 0;
		}

		return SUCCESS;
	}


	/////////////////////////////////////////////////////////////////////////////
	// Get low-32bit, high-32bit and interupt-counters
	/////////////////////////////////////////////////////////////////////////////
	command uint32_t LocalCounter.getHighCounter() {

		return highCounter;
	}

	command uint32_t LocalCounter.getLowCounter() {
		uint32_t smallCounter;

		atomic {
			smallCounter = TPM1CNTH;
			smallCounter = (smallCounter << 8) + TPM1CNTL;
			smallCounter += lowCounter;
			
			// check if timer overflew during command call
			smallCounter += (TPM1SC_TOF * 0x00010000);
		}

		return smallCounter;
	}

	command uint32_t LocalCounter.getInteruptCounter() {
		uint32_t smallCounter;

		atomic {		
			smallCounter = TPM1CNTH;
			smallCounter = (smallCounter << 8) + TPM1CNTL;
			smallCounter += interuptCounter - carryCounter;
		}

		return smallCounter;
	}

	/////////////////////////////////////////////////////////////////////////////
	// Interupt handlers
	/////////////////////////////////////////////////////////////////////////////

	// Main Timer 1 overflow
	TOSH_SIGNAL(TPM1OVF) {
		uint16_t TOF;
		
		// update big alarm
		if (bigAlarmEnable == 1) {
			// count down
			bigAlarm -= 0x00010000;

			// is remaining time less than 16bit
			if (bigAlarm < 0x00010000) {
				atomic {
					// set timer
					TPM1C0VH = bigAlarm >> 8;
					TPM1C0VL = bigAlarm;

					// enable interupt
					TPM1C0SC_CH0F = 0;
					TPM1C0SC_CH0IE = 1;
				}
			}
		}


		// update counters
		if (lowCounter == 0xffff0000) {
			highCounter++; 
		}

		lowCounter += 0x00010000;

		if (interuptCounter < 0xffff0000) {
			interuptCounter += 0x00010000;
		}

		// clear interupt
		TOF = TPM1SC_TOF;
		TPM1SC_TOF = 0;
	}


	// big alarm fired
	TOSH_SIGNAL(TPM1CH0) {

		bigTimerFired();
		
	}

	// small alarm fired
	TOSH_SIGNAL(TPM1CH1) {
		uint16_t smallCounter;

		atomic {
			if (smallAlarmInterval > 0 ) {
				smallCounter = TPM1C1VH;
				smallCounter = (smallCounter << 8) + TPM1C1VL;
	
				smallCounter += smallAlarmInterval;
			
				// set timer
				TPM1C1VH = smallCounter >> 8;
				TPM1C1VL = smallCounter;

				// clear and enable interupt
				TPM1C1SC_CH1F = 0;
				TPM1C1SC_CH1IE = 1;
			}
		}

		signal TPMTimer16.fired();
	}

	// interupt from timer input pin
	TOSH_SIGNAL(TPM1CH2) {
		uint8_t edge;
		uint16_t smallCounter;
		uint32_t totalCounts;
		
		smallCounter = TPM1C2VH;
		smallCounter = (smallCounter << 8) + TPM1C2VL;

		totalCounts = interuptCounter + smallCounter - carryCounter;


		// clear counters
		interuptCounter = 0;
		carryCounter = smallCounter;

		// clear interupt
		TPM1C2SC_CH2F = 0;
		TPM1C2SC_CH2IE = 1;

		edge = PTDD_PTDD2;	
		signal TPM.signalReceived(edge, totalCounts);
	}
	
	
	void bigTimerFired() {
		uint32_t sum;
		uint16_t smallCounter;

		atomic {
			smallCounter = TPM1C0VH;
			smallCounter = (smallCounter << 8) + TPM1C0VL;
		}


		atomic {		
			sum = bigAlarmInterval + smallCounter;
			
			if (sum < 0x00010000) {

				// set timer
				TPM1C0VH = sum >> 8;
				TPM1C0VL = sum;

				// clear and enable interupt
				TPM1C0SC_CH0F = 0;
				TPM1C0SC_CH0IE = 1;

			} else {
				bigAlarm = sum;

				// clear and disable interupt
				TPM1C0SC_CH0F = 0;
				TPM1C0SC_CH0IE = 0;
			}
		}

		signal TPMTimer32.fired();
	}

}
