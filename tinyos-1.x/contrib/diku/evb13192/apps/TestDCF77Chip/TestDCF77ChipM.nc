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
module TestDCF77ChipM { 
	provides {
		interface StdControl;
	}
	uses {
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;
		
		interface TPM;
		interface StdControl as TPMControl;
		interface StdControl as ConradControl;
		interface LocalCounter;
		interface TPMTimer16;
		interface TPMTimer32;
		
		interface HPLICGControl as ICG;

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

	enum
	{	
		INTERNAL = 0x00,
		EXTERNAL = 0x01,
	};

	uint32_t buffer;

	/////////////////////////////////////////////////////////////////////////////////
	// StdControl related
	/////////////////////////////////////////////////////////////////////////////////
	command result_t StdControl.init() {

		call ICG.enterFEEMode(0,8,1,5);	// 16MHz busClock
		
		// FEE
		// timerClock = 32786;

		
		return SUCCESS;
	}

	command result_t StdControl.start() {
		uint16_t i;

		call TPMControl.init();
		call TPM.setClockSource(EXTERNAL);

		call ConradControl.init();

		call ConsoleOut.print("\n\r\n\r# DCF77 Test program\n\r");

		call ConsoleOut.print("# Current clock mode: ");
		call ConsoleOut.printBase10uint8(ICGS1_CLKST);
		call ConsoleOut.print("\n\r");

		call ConsoleOut.print("# Estimated busClock: ");
		call ConsoleOut.printBase10uint32(busClock);
		call ConsoleOut.print("\n\r");

		call ConsoleOut.print("# Estimated extClock: ");
		call ConsoleOut.printBase10uint32(extClock);
		call ConsoleOut.print("\n\r");

		call ConsoleOut.print("# Timer source: ");
		call ConsoleOut.printBase10uint8(TPM1SC_CLKSB);
		call ConsoleOut.printBase10uint8(TPM1SC_CLKSA);
		call ConsoleOut.print("\n\r");


		// Turn on Conrad Receiver
		call ConradControl.start();
		
		for (i = 1; i <  3200; i++) 
			asm("nop");
			
		call TPMControl.start();
		
//		call TPMTimer32.start(busClock);
		
		return SUCCESS;
	}

	command result_t StdControl.stop() {



		return SUCCESS;
	}
	

	async event result_t TPM.signalReceived(uint8_t edge, uint32_t counter) {

		if (edge == 1) {
			buffer = counter;
		} else {
		
			call ConsoleOut.printBase10uint32(counter+buffer);
			call ConsoleOut.print("\n\r");
		}

		return SUCCESS;
	}


	async event result_t TPMTimer16.fired() {

		return SUCCESS;
	}

	async event result_t TPMTimer32.fired() {

		call ConsoleOut.print("# Timer fired\n\r");
		
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



}
