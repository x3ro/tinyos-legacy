/* Copyright (c) 2006, Marcus Chang, Jan Flora
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
				Jan Flora <j@nflora.dk>
	Last modified:	June, 2006
*/


module HPLICGControlM 
{
	provides interface HPLICGControl as ICG;
	uses interface ExternalClockControl as ECG;

}

implementation
{

	result_t setMode(uint8_t desiredMode, uint8_t multiplier, uint8_t divisor, bool range);
//	void enterFEEMode(bool rng, uint8_t multFact, uint8_t divFact);
//	void enterFBEMode(uint8_t divFact);
//	void enterFEIMode(uint8_t multFact, uint8_t divFact);

	// From hcs08hardware.h
	// busClock = 8000000; // We init busClock to be 8 MHz.
	// fIRG = 243000;  // f_IRG is 243 KHz
	
	enum
	{	
		SCM = 0x00,
		FEI = 0x01,
		FBE = 0x02,
		FEE = 0x03
	};


	command result_t ICG.enterFEIMode(uint8_t multiplier, uint8_t divisor) {

		return setMode(FEI, multiplier, divisor, 0);
	}

	command result_t ICG.enterFBEMode(uint8_t divisor, uint8_t externalClock) {

		call ECG.init();
		call ECG.setClockRate(externalClock); 

		return setMode(FBE, 0, divisor, 0);
	}
	
	command result_t ICG.enterFEEMode(bool range, uint8_t multiplier, uint8_t divisor, uint8_t externalClock) {

		call ECG.init();
		call ECG.setClockRate(externalClock); 

		return setMode(FEE, multiplier, divisor, range);
	}


	result_t setMode(uint8_t desiredMode, uint8_t multiplier, uint8_t divisor, bool range)
	{
		uint8_t currentMode = ICGS1_CLKST;

		switch(currentMode) 
		{
			case SCM:
				switch(desiredMode)
				{
					case FEI:
						enterFEIMode(multiplier, divisor); 
						break;
					case FBE:
						enterFBEMode(divisor);
						break;
					case FEE:
						enterFEEMode(range, multiplier, divisor);
						break;
					default:
						return FAIL;
				}
				break;
			case FEI:
				if (desiredMode == FEE) {
					enterFEEMode(range, multiplier, divisor);
				} else {
					return FAIL;
				}
				break;
			case FBE:
				if (desiredMode == FEE) {
					enterFEEMode(range, multiplier, divisor);
				} else {
					return FAIL;
				}
				break;
			default:
				return FAIL;
		}
		
		return SUCCESS;
	}

	command uint8_t ICG.getMode()
	{
		return ICGS1_CLKST;	
	}
	
/*	void enterFEIMode(uint8_t multFact, uint8_t divFact)
	{
		// f_IRG = 243 KHz
		// f_ICGOUT = (f_IRG / 7) * 64 * multFact / divFact
		// 16 MHz = ( 243 kHz / 7) * 64 * 14 / 2
		// multFact : 4, 6, 8, 10, 12, 14, 16,  18
		// divFact  : 1, 2, 4,  8, 16, 32, 64, 128

		uint8_t MFD, RFD = 0;

		// Set busClock variable.
		busClock = (fIRG / 7) * 64 * (multFact / divFact)/2;

		// Calculate MFD bits.
		MFD = (multFact - 4)>>1;
		MFD &= 0x07;

		// Calculate RFD bits.
		while (divFact) {
			divFact = divFact>>1;
			RFD++;
		}
		RFD--;
		RFD &= 0x07;

		// Set clock into FEI mode.	
		ICGC1 = 0x28;  //00101000, REFS = 1, CLKS = 1.
		while (!ICGS2_DCOS); // Wait for DCO to be stable.
		ICGC2_MFD = MFD;
		ICGC2_RFD = RFD;	
		ICGC2_LOLRE = 0;
		ICGC2_LOCRE = 0;
	}

	void enterFBEMode(uint8_t divFact)
	{
		// f_ICGOUT = f_EXT / divFact
		// divFact  : 1, 2, 4,  8, 16, 32, 64, 128

		uint8_t RFD = 0;

		// Set busClock variable.
		busClock = (extClock / divFact)/2;

		// Calculate RFD bits.
		while (divFact) {
			divFact = divFact>>1;
			RFD++;
		}
		RFD--;
		RFD &= 0x07;

		// Set clock into FBE mode.
		ICGC1 = 0x50; // 01010000, RANGE = 1, CLKS = 2.
		while (!ICGS1_ERCS); // Wait for External Clock to be stable.
		ICGC2_RFD = RFD;	
		ICGC2_LOLRE = 0;
		ICGC2_LOCRE = 0;
	}

	void enterFEEMode(bool rng, uint8_t multFact, uint8_t divFact)
	{
		// f_ICGOUT = f_EXT * (64*!rng) * multFact / divFact
		// multFact : 4, 6, 8, 10, 12, 14, 16,  18
		// divFact  : 1, 2, 4,  8, 16, 32, 64, 128

		uint8_t MFD, RFD = 0;


		// Set busClock variable.
		if (rng) {
			busClock = (extClock * (multFact / divFact))/2;
		} else {
			busClock = (extClock * 64 * (multFact / divFact))/2;
		}

		// Calculate MFD bits.
		MFD = (multFact - 4)>>1;
		MFD &= 0x07;

		// Calculate RFD bits.
		while (divFact) {
			divFact = divFact>>1;
			RFD++;
		}
		RFD--;
		RFD &= 0x07;

		// Set clock into FEE mode.
		if (rng) {
			ICGC1 = 0x58; // 01011000
		} else {
			ICGC1 = 0x18; // 00011000
		}

		while (!ICGS2_DCOS && !ICGS1_ERCS); // Wait for DCO and External Clock to be stable.
		ICGC2_MFD = MFD;
		ICGC2_RFD = RFD;	
		ICGC2_LOLRE = 0;
		ICGC2_LOCRE = 0;
		// Wait for frequency loop to lock.
		while (!ICGS1_LOCK);
	}

*/

}
