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


/**
 * This is a test module for the DCF77 receiver
 * 
 **/
module TestDCF77HibernationM { 
	provides {
		interface StdControl;
	}
	uses {
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;
		interface DCF77;
		interface DCF77Hibernation;
		
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
	uint32_t timerClock, hibernation;
	
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
		// call TPMTimer32.start(calculatedBusClock);

		post printDCF77Task();

//		call ConsoleOut.printBase10uint32(calculatedBusClock);
//		call ConsoleOut.print("\n\r");
		
		return SUCCESS;
	}

	event result_t DCF77.outSync() {

		atomic inSync = 0;

		call ConsoleOut.print("# DCF77 out of sync\n\r");
		// call TPMTimer32.stop();

		return SUCCESS;
	}

	task void hibernateTask() {
		uint32_t time;
	
		time = call DCF77.getTimestamp();

		call ConsoleOut.print("Re-entering hibernation at ");
		call ConsoleOut.printBase10uint32(time);
		call ConsoleOut.print("\n\r");

		time = call DCF77.getUnixTimestamp();
		call DCF77Hibernation.hibernateUntil(hibernation + time);
	}
	
	async event result_t DCF77Hibernation.wakeUp(int32_t error) {
		uint32_t time;

		time = call DCF77.getTimestamp();

		call ConsoleOut.print("Exited hibernation at ");
		call ConsoleOut.printBase10uint32(time);
		call ConsoleOut.print("\n\r");

		call ConsoleOut.print("Late: ");
		call ConsoleOut.printBase10int32(error);
		call ConsoleOut.print("\n\r");

		post hibernateTask();
		
		return SUCCESS;	
	}
	

	/////////////////////////////////////////////////////////////////////////////////
	// Timer related
	/////////////////////////////////////////////////////////////////////////////////
	async event result_t TPMTimer16.fired() {

		return SUCCESS;
	}

	async event result_t TPMTimer32.fired() {

		// call ConsoleOut.print("Tick\n\r");
		
		// post printDCF77Task();
		
		return SUCCESS;
	}

	/////////////////////////////////////////////////////////////////////////////////
	// Console related
	/////////////////////////////////////////////////////////////////////////////////

	async event result_t ConsoleIn.get(uint8_t theChar) {
		uint32_t time;
		char echo[2];
		char * ptr;
		
		ptr = echo;
		echo[1] = 0;

		*ptr = theChar;
		
		if (theChar == '\r') {

			call ConsoleOut.print("\n\r");

		} else if (theChar == 'a') {
			call ConsoleOut.print("Starting DCF77\n\r");
			call DCF77.start(busClock / 128);

		} else if (theChar == 's') {
			call ConsoleOut.print("Stopping DCF77\n\r");
			call TPMTimer32.stop();
			call DCF77.stop();

		} else if (theChar == 'd') {

			call TPMTimer32.start(busClock / 128);

		} else if (theChar == 't') {

			post printDCF77Task();

		} else if (theChar == 'q') {

			call ConsoleOut.print("TPM1C0SC_CH0IE: ");
			call ConsoleOut.printBase10uint8(TPM1C0SC_CH0IE);
			call ConsoleOut.print("\n\r");

			call ConsoleOut.print("TPM1MOD: ");
			call ConsoleOut.printBase10uint8(TPM1MODH);
			call ConsoleOut.print(":");
			call ConsoleOut.printBase10uint8(TPM1MODL);
			call ConsoleOut.print("\n\r");

		} else if (theChar == 'h') {
		
			time = call DCF77.getTimestamp();
			call ConsoleOut.print("Entering hibernation (10 sek) at ");
			call ConsoleOut.printBase10uint32(time);
			call ConsoleOut.print("\n\r");

			time = call DCF77.getUnixTimestamp();
			hibernation = 10;
			call DCF77Hibernation.setOffset(442);
			call DCF77Hibernation.hibernateUntil(hibernation + time);

		} else if (theChar == 'i') {

			time = call DCF77.getTimestamp();
			call ConsoleOut.print("Entering hibernation (30 sek) at ");
			call ConsoleOut.printBase10uint32(time);
			call ConsoleOut.print("\n\r");

			time = call DCF77.getUnixTimestamp();
			hibernation = 30;
			call DCF77Hibernation.hibernateUntil(hibernation + time);

		} else if (theChar == 'j') {

			time = call DCF77.getTimestamp();
			call ConsoleOut.print("Entering hibernation (180 sek) at ");
			call ConsoleOut.printBase10uint32(time);
			call ConsoleOut.print("\n\r");

			time = call DCF77.getUnixTimestamp();
			hibernation = 180;
			call DCF77Hibernation.hibernateUntil(hibernation + time);

		} else if (theChar == 'k') {

			time = call DCF77.getTimestamp();
			call ConsoleOut.print("Entering hibernation (190 sek) at ");
			call ConsoleOut.printBase10uint32(time);
			call ConsoleOut.print("\n\r");

			time = call DCF77.getUnixTimestamp();
			hibernation = 190;
			call DCF77Hibernation.hibernateUntil(hibernation + time);

		} else if (theChar == 'l') {

			time = call DCF77.getTimestamp();
			call ConsoleOut.print("Entering hibernation (72000 sek) at ");
			call ConsoleOut.printBase10uint32(time);
			call ConsoleOut.print("\n\r");

			time = call DCF77.getUnixTimestamp();
			hibernation = 72000;
			call DCF77Hibernation.hibernateUntil(hibernation + time);

		} else {
			call ConsoleOut.print(echo);
		}

		return SUCCESS;
	}
	
	
	/////////////////////////////////////////////////////////////////////////////////
	// Time output related
	/////////////////////////////////////////////////////////////////////////////////
	task void printDCF77Task() {
		uint8_t hours, minutes, seconds;
		uint16_t milliseconds;
		uint32_t timestamp,counter;
	
		// timestamp = call DCF77.getTimestamp();
		// hours = timestamp / 10000000;
		// timestamp %= 10000000;
		// minutes = timestamp / 100000;
		// timestamp %= 100000;
		// seconds = timestamp / 1000;
		// timestamp %= 1000;
		// milliseconds = timestamp;

atomic{		timestamp = call DCF77.getTimestampInMilliseconds();
		counter = call LocalCounter.getLowCounter();
}
		milliseconds = timestamp % 1000;
		timestamp /= 1000;

		seconds = timestamp % 60;
		timestamp /= 60;

		minutes = timestamp % 60;
		hours = timestamp / 60;
		
		if (hours < 10) {
			call ConsoleOut.print(" ");
			call ConsoleOut.printBase10uint8(hours);
		} else {
			call ConsoleOut.printBase10uint8(hours);
		}

		call ConsoleOut.print(":");

		if (minutes < 10) {
			call ConsoleOut.printBase10uint8(0);
			call ConsoleOut.printBase10uint8(minutes);
		} else {
			call ConsoleOut.printBase10uint8(minutes);
		}

		call ConsoleOut.print(":");

		if (seconds < 10) {
			call ConsoleOut.printBase10uint8(0);
			call ConsoleOut.printBase10uint8(seconds);
		} else {
			call ConsoleOut.printBase10uint8(seconds);
		}

		call ConsoleOut.print(".");

		if (milliseconds < 10) {
			call ConsoleOut.printBase10uint8(0);
			call ConsoleOut.printBase10uint8(0);
			call ConsoleOut.printBase10uint32(milliseconds);
		} else if (milliseconds < 100)  {
			call ConsoleOut.printBase10uint8(0);
			call ConsoleOut.printBase10uint32(milliseconds);
		} else {
			call ConsoleOut.printBase10uint32(milliseconds);
		}

		call ConsoleOut.print(" ");

		call ConsoleOut.printBase10uint32(counter);

		call ConsoleOut.print("\n\r");

	}


}
