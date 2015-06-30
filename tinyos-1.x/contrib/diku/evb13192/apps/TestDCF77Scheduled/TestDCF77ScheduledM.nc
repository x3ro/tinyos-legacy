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

module TestDCF77ScheduledM {
	provides {
		interface StdControl;
	}
	
	uses {
		interface SimpleMac as Mac;
		interface DCF77;
		interface DCF77Hibernation;
		interface TPMTimer32;
		interface LocalCounter;

		interface StdControl as ConsoleControl;
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;
	}
}

implementation {

#define GATEWAY 25
#define FRAME	20

	task void printDCF77Task();
	task void hibernateTask();

	// Hibernation
	uint32_t interval = 86400, offset = 0;

	//////////////////////////////////////////////////////////////////
	// Packet
	//////////////////////////////////////////////////////////////////
	tx_packet_t tx_packet;
	char tx_buf[29] = "abcdefghijklmnopqrstuvwxyzabc";


	//////////////////////////////////////////////////////////////////
	// FSM
	//////////////////////////////////////////////////////////////////
	enum
	{	
		IDLE = 0x00,
		AWAKE = 0x01,
		SLEEP = 0x02,
	};

	uint8_t currentState, counter = 0, inSync = 0;
	uint16_t lastMote = 32;
	
	uint32_t t_26, t_27, t_28, t_31, t_32;
	

	task void rx26() {
		// call ConsoleOut.print("# transmit at ");
		call ConsoleOut.print("26 ");
		call ConsoleOut.printBase10uint32(t_26);
		call ConsoleOut.print("\n\r");
	}
	task void rx27() {
		// call ConsoleOut.print("# transmit at ");
		call ConsoleOut.print("27 ");
		call ConsoleOut.printBase10uint32(t_27);
		call ConsoleOut.print("\n\r");
	}
	task void rx28() {
		// call ConsoleOut.print("# transmit at ");
		call ConsoleOut.print("28 ");
		call ConsoleOut.printBase10uint32(t_28);
		call ConsoleOut.print("\n\r");
	}
	task void rx31() {
		// call ConsoleOut.print("# transmit at ");
		call ConsoleOut.print("31 ");
		call ConsoleOut.printBase10uint32(t_31);
		call ConsoleOut.print("\n\r");
	}
	task void rx32() {
		// call ConsoleOut.print("# transmit at ");
		call ConsoleOut.print("32 ");
		call ConsoleOut.printBase10uint32(t_32);
		call ConsoleOut.print("\n\r");
	}


	//////////////////////////////////////////////////////////////////
	// StdControl
	//////////////////////////////////////////////////////////////////
	command result_t StdControl.init() {
		struct Timestamp *pack;

 		tx_packet.data = tx_buf;
		tx_packet.dataLength = 6;
		pack = (struct Timestamp *) tx_buf;
		pack->address = TOS_LOCAL_ADDRESS;
    
		if (call Mac.init()) {
			call Mac.setChannel(7);
		}

		call ConsoleControl.init();
		call DCF77.init();
	        
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		// SMAC sucks
		extClock = 16000000;
		
		call DCF77.start(1);
	        call DCF77Hibernation.start();
		// call Mac.enableReceive();
		
		call ConsoleControl.start();
		call ConsoleOut.print("\n\r# TestDCF77ScheduleM.nc booted\n\r");

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

		if (TOS_LOCAL_ADDRESS == 31) {
			call DCF77Hibernation.setOffset(29 * FRAME);
		} else if (TOS_LOCAL_ADDRESS == 32) {
			call DCF77Hibernation.setOffset(30 * FRAME);
		} else {
			call DCF77Hibernation.setOffset(TOS_LOCAL_ADDRESS * FRAME);
		}
		
		atomic currentState = IDLE;
		
		return SUCCESS;
	}

	command result_t StdControl.stop() {
	
		return SUCCESS; 
	}



	//////////////////////////////////////////////////////////////////
	// DCF77
	//////////////////////////////////////////////////////////////////
	event result_t DCF77.inSync(uint32_t estimatedBusClock) {
		uint32_t time, multiplier;

		atomic inSync = 1;

		call ConsoleOut.print("# DCF77 in sync\n\r");

		post printDCF77Task();

		if (currentState == IDLE) {

			time = call DCF77.getUnixTimestamp();
			multiplier = time / interval + 1;
			time = interval * multiplier + offset;

			call DCF77Hibernation.hibernateUntil(time);

			// time = call DCF77.getTimestamp();
			call ConsoleOut.print("# Entering hibernation until ");
			call ConsoleOut.printBase10uint32(time);
			call ConsoleOut.print("\n\r");

			atomic currentState = SLEEP;
		}


		return SUCCESS;
	}

	event result_t DCF77.outSync() {

		atomic inSync = 0;

		call ConsoleOut.print("# DCF77 out of sync\n\r");

		post printDCF77Task();

		return SUCCESS;
	}

	async event result_t TPMTimer32.fired() {

		if (TOS_LOCAL_ADDRESS == GATEWAY && currentState == AWAKE) {

			if (counter == 1) {
				counter = 0;

				post hibernateTask();
				post printDCF77Task();
			} else {
				counter++;
			}
		}

		return SUCCESS;
	
	}

	async event result_t DCF77Hibernation.wakeUp(int32_t error) {
		uint32_t time;
		
		atomic currentState = AWAKE;
		
		call Mac.enableReceive();
		call Mac.send(&tx_packet);

		time = call DCF77.getTimestamp();
		call ConsoleOut.print("# Exited hibernation at ");
		call ConsoleOut.printBase10uint32(time);
		call ConsoleOut.print("\n\r");
				
		return SUCCESS;	
	}
	
  
	//////////////////////////////////////////////////////////////////
	// SimpleMAC
	//////////////////////////////////////////////////////////////////
	event void Mac.sendDone(tx_packet_t * packet) {

		// call ConsoleOut.print("# Senddone\n\r");

		if (TOS_LOCAL_ADDRESS != GATEWAY) {
			post hibernateTask();
			post printDCF77Task();
		}
	}

	event rx_packet_t * Mac.receive(rx_packet_t * packet) {
		struct Timestamp *pack;
		uint32_t time, multiplier;

		pack = (struct Timestamp *) (*packet).data;

		if (TOS_LOCAL_ADDRESS == GATEWAY) {
		
			if (pack->address == 26) {

				t_26 = call DCF77.getTimestamp();
				post rx26();
			
			} else if (pack->address == 27) {

				t_27 = call DCF77.getTimestamp();
				post rx27();
			
			} else if (pack->address == 28) {

				t_28 = call DCF77.getTimestamp();
				post rx28();
			
			} else if (pack->address == 31) {

				t_31 = call DCF77.getTimestamp();
				post rx31();
			
			} else if (pack->address == 32) {
				t_32 = call DCF77.getTimestamp();
				post rx32();

			}
		
			if (pack->address == lastMote) {
			
				counter = 0;

				post hibernateTask();
				post printDCF77Task();
			} else {
			
				call Mac.enableReceive();
			}
		
		}
				
		// time = call DCF77.getTimestamp();

		// call ConsoleOut.print("# ");
		// call ConsoleOut.printBase10int16(pack->address);
		// call ConsoleOut.print(" ");
		// call ConsoleOut.printBase10int32(time);
		// call ConsoleOut.print(" ");
		// call ConsoleOut.printBase10int32(pack->timestamp);
		// call ConsoleOut.print("\n\r");
		
		return packet;
	}

	event void Mac.reset() {
	
	}

  

	//////////////////////////////////////////////////////////////////
	// Console
	//////////////////////////////////////////////////////////////////
	async event result_t ConsoleIn.get(uint8_t theChar) {
		char echo[2];
		char * ptr;
		struct Timestamp *pack;
		uint32_t time;
		
		ptr = echo;
		echo[1] = 0;
		*ptr = theChar;


		if (theChar == '\r') {

			call ConsoleOut.print("\n\r");

		} else if (theChar == 'p') {
	
			signal DCF77Hibernation.wakeUp(0);
			
/*			atomic {
				baseTime = call DCF77.getUnixTimestamp();
      	 
				pack = (struct Timestamp *) tx_buf;
				pack->address = TOS_LOCAL_ADDRESS;
				pack->timestamp = baseTime;
			}
				
			tx_packet.dataLength = 6;
			call Mac.send(&tx_packet);

			atomic currentState = AWAKE;
*/
		} else if (theChar == 't') {

			post printDCF77Task();

		} else {
			call ConsoleOut.print(echo);
		}

		return SUCCESS;
	}


	//////////////////////////////////////////////////////////////////
	// Hibernate task
	//////////////////////////////////////////////////////////////////
	task void hibernateTask() {
		uint32_t time, multiplier;

		call Mac.disableReceive();

		if (inSync == 1) {		
			time = call DCF77.getUnixTimestamp();
			multiplier = time / interval + 1;
		
			time = interval * multiplier + offset;
		
			call DCF77Hibernation.hibernateUntil(time);

			// time = call DCF77.getTimestamp();

			call ConsoleOut.print("# Re-entering hibernation until ");
			call ConsoleOut.printBase10uint32(time);
			call ConsoleOut.print("\n\r");

			atomic currentState = SLEEP;
		} else {
		
			atomic currentState = IDLE;
		}
	}
	

	//////////////////////////////////////////////////////////////////
	// DCF77 print task
	//////////////////////////////////////////////////////////////////
	task void printDCF77Task() {
				
		// call ConsoleOut.print("# DCF77 Signal:\n\r");
		// call ConsoleOut.print("# Time stamp: ");

		call ConsoleOut.print("# ");
		
		call ConsoleOut.printBase10uint32(call DCF77.getTimestamp());
		// call ConsoleOut.print("\n\r");

		call ConsoleOut.print(" ");

		// call ConsoleOut.print("# Date stamp: ");
		call ConsoleOut.printBase10uint32(call DCF77.getDatestamp());
		// call ConsoleOut.print("\n\r");
		
		// call ConsoleOut.print("# Day of week: ");
		// call ConsoleOut.printBase10uint8(call DCF77.getDayOfWeek());
		call ConsoleOut.print("\n\r");


	}



}
