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


/**
 * This is a test module for the DCF77 receiver
 * 
 **/
module TestDCF77ClockM { 
	provides {
		interface StdControl;
	}
	uses {
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;
		interface DCF77;
		
		interface TPMTimer16;
		interface TPMTimer32;
		
		interface LocalCounter;
	}
}
implementation {

	enum
	{	
		SCM = 0x00,
		FEI = 0x01,
		FBE = 0x02,
		FEE = 0x03
	};

	task void printDCF77Task();

	uint8_t inSync = 0;
	uint32_t timerClock;
	
	uint8_t dcf77;

	/////////////////////////////////////////////////////////////////////////////////
	// StdControl related
	/////////////////////////////////////////////////////////////////////////////////
	command result_t StdControl.init() {

		call DCF77.init();
		
		return SUCCESS;
	}

	command result_t StdControl.start() {

		call ConsoleOut.print("\n\r\n\r# DCF77 Test program\n\r");

		call ConsoleOut.print("# Current clock mode: ");
		call ConsoleOut.printBase10uint8(ICGS1_CLKST);
		call ConsoleOut.print("\n\r");

		call ConsoleOut.print("# Estimated busClock: ");
		call ConsoleOut.printBase10uint32(busClock);
		call ConsoleOut.print("\n\r");

		call ConsoleOut.print("# Timer source: ");
		call ConsoleOut.printBase10uint8(TPM1SC_CLKSB);
		call ConsoleOut.printBase10uint8(TPM1SC_CLKSA);
		call ConsoleOut.print("\n\r");

		call ConsoleOut.print("#\n\r# Please wait 1-2 minutes for DCF frame reception\n\r");
		
		call DCF77.start(1);
		dcf77 = 1;
		
	
		return SUCCESS;
	}

	command result_t StdControl.stop() {

		call DCF77.stop();

		return SUCCESS;
	}
	

	/////////////////////////////////////////////////////////////////////////////////
	// DCF77 related
	/////////////////////////////////////////////////////////////////////////////////
	event result_t DCF77.inSync(uint32_t calculatedBusClock) {
	
		atomic inSync = 1;

		call ConsoleOut.print("# DCF77 in sync\n\r");

		post printDCF77Task();
		
		return SUCCESS;
	}

	event result_t DCF77.outSync() {

		atomic inSync = 0;

		call ConsoleOut.print("# DCF77 out of sync\n\r");

		post printDCF77Task();

		return SUCCESS;
	}
	

	/////////////////////////////////////////////////////////////////////////////////
	// Timer related
	/////////////////////////////////////////////////////////////////////////////////
	async event result_t TPMTimer16.fired() {

		return SUCCESS;
	}

	async event result_t TPMTimer32.fired() {
		
		post printDCF77Task();
		
		return SUCCESS;
	}

	/////////////////////////////////////////////////////////////////////////////////
	// Console related
	/////////////////////////////////////////////////////////////////////////////////

	async event result_t ConsoleIn.get(uint8_t theChar) {
		char echo[2];
		char * ptr;
		
		ptr = echo;
		echo[1] = 0;

		*ptr = theChar;
		
		if (theChar == '\r') {

			call ConsoleOut.print("\n\r");

		} else {
			call ConsoleOut.print(echo);
		}

		return SUCCESS;
	}
	
	
	/////////////////////////////////////////////////////////////////////////////////
	// Time output related
	/////////////////////////////////////////////////////////////////////////////////
	task void printDCF77Task() {
		uint32_t timestamp, datestamp, millistamp;
	
		atomic{		
			timestamp = call DCF77.getTimestamp();
			datestamp = call DCF77.getDatestamp();

			// millistamp = call DCF77.getTimestampInMilliseconds();
		}

		call ConsoleOut.printBase10uint32(timestamp);
		call ConsoleOut.print(" ");
		call ConsoleOut.printBase10uint32(datestamp);
		call ConsoleOut.print("\n\r");

		// call ConsoleOut.printBase10uint32(millistamp);
		// call ConsoleOut.print("\n\r");
	}


}
