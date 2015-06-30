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

#include "Timestamp.h"

module TestAMChipM {
	provides {
		interface StdControl;
	}

	uses {
		interface StdControl as ConsoleControl;
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;

		interface StdControl as AMRadioControl;		
		interface StdControl as TPMControl;
		interface TPM;
	}
}

implementation {

	/////////////////////////////////////////////////////////////////////////
	// StdControl
	/////////////////////////////////////////////////////////////////////////
	command result_t StdControl.init() {

		call TPMControl.init();
		call AMRadioControl.init();
    
		return SUCCESS;
	}


	command result_t StdControl.start()
	{
		uint16_t i;

		call TPM.setClockSource(0);

    		call ConsoleControl.init();
		call ConsoleControl.start();
		call ConsoleOut.print("\n\r# TestAM booted\n\r");

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


		call AMRadioControl.start();

		for (i = 1; i <  3200; i++) 
			asm("nop");

		call TPMControl.start();	


		return SUCCESS;
	}

	command result_t StdControl.stop() {
	
		return SUCCESS; 
	}


	async event result_t TPM.signalReceived(uint8_t edge, uint32_t counter) {

		if (edge == 1) {
			call ConsoleOut.print("1 ");

			call ConsoleOut.printBase10uint32(counter);
			call ConsoleOut.print("\n\r");
		} else {
			call ConsoleOut.print("0 ");
		
			call ConsoleOut.printBase10uint32(counter);
			call ConsoleOut.print("\n\r");
		}

		return SUCCESS;
	}


	/////////////////////////////////////////////////////////////////////////
	// Console
	/////////////////////////////////////////////////////////////////////////
	async event result_t ConsoleIn.get(uint8_t theChar) {
		char echo[2];
		char * ptr;
		
		ptr = echo;
		echo[1] = 0;
		*ptr = theChar;


		if (theChar == '\r') {

			call ConsoleOut.print("\n\r");

		} else if (theChar == '1') {
		
			TOS_LOCAL_ADDRESS = 1;
			call ConsoleOut.print("# TOS_LOCAL_ADDRESS: 1\n\r");

		} else if (theChar == '2') {

			TOS_LOCAL_ADDRESS = 2;
			call ConsoleOut.print("# TOS_LOCAL_ADDRESS: 2\n\r");

		} else if (theChar == '3') {

			TOS_LOCAL_ADDRESS = 3;
			call ConsoleOut.print("# TOS_LOCAL_ADDRESS: 3\n\r");

		} else if (theChar == '4') {

			TOS_LOCAL_ADDRESS = 4;
			call ConsoleOut.print("# TOS_LOCAL_ADDRESS: 4\n\r");

		} else if (theChar == 'i') {

			call ConsoleOut.print("# TOS_LOCAL_ADDRESS: ");
			call ConsoleOut.printBase10uint16(TOS_LOCAL_ADDRESS);
			call ConsoleOut.print("\n\r");
			
		} else {
			call ConsoleOut.print(echo);
		}

		return SUCCESS;
	}



}
