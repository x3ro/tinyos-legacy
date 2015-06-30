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

module TestDCF77AgreementM {
  provides {
    interface StdControl;
  }
  uses {
    interface SimpleMac as Mac;
    interface Leds;
    interface DCF77;
    interface StdControl as ConsoleControl;
    interface ConsoleInput as ConsoleIn;
    interface ConsoleOutput as ConsoleOut;
    interface TPMTimer32;
  }
}
implementation {

	task void transmitPacket();
	task void printDCF77Task();
	task void handleGet();


	/** Used to keep the commands the user type in */
	char cmd_input[200];
	char * bufpoint;
	char console_data;

	/** Packet to transmit */
	tx_packet_t tx_packet;
	/** Packet buffer space */
	char tx_buf[29] = "abcdefghijklmnopqrstuvwxyzabc";

	uint16_t serial = 0;
	uint8_t transmit = 0;

	
	/////////////////////////////////////////////////////////////////////////
	// StdControl
	/////////////////////////////////////////////////////////////////////////
	command result_t StdControl.init() {

		call Leds.init();
 		call Leds.redOn();

 		/* init variables */
 		tx_packet.data = tx_buf;
    
		if (call Mac.init()) {
			call Mac.setChannel(0);
		}

		call DCF77.init();
    
		call ConsoleControl.init();
    
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call DCF77.start(1);
		call Mac.enableReceive();
		
		call ConsoleControl.start();
		call ConsoleOut.print("\n\r# TestDCF77AgreementM.nc booted\n\r");

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


		return SUCCESS;
	}

	command result_t StdControl.stop() {
	
		return SUCCESS; 
	}

	/////////////////////////////////////////////////////////////////////////
	// DCF77
	/////////////////////////////////////////////////////////////////////////
	event result_t DCF77.inSync(uint32_t estimatedBusClock) {

		call ConsoleOut.print("# DCF77 in sync\n\r");

		return SUCCESS;
	}

	event result_t DCF77.outSync() {

		call ConsoleOut.print("# DCF77 out of sync\n\r");

		return SUCCESS;
	}

	async event result_t TPMTimer32.fired() {

		post transmitPacket();

		return SUCCESS;
	
	}
  
	/////////////////////////////////////////////////////////////////////////
	// SimpleMAC
	/////////////////////////////////////////////////////////////////////////
	event void Mac.sendDone(tx_packet_t * packet) {

		call ConsoleOut.print("Senddone\n\r");
	}

	event rx_packet_t * Mac.receive(rx_packet_t * packet) {
		struct Timestamp *pack;
		uint32_t time, timestamp;
		uint16_t address;

		time = call DCF77.getTimestampInMilliseconds();

		pack = (struct Timestamp *) (*packet).data;
		address = pack->address;
		
		call ConsoleOut.printBase10uint16(address);
		call ConsoleOut.print(" ");
		call ConsoleOut.printBase10uint32(time);
		call ConsoleOut.print("\n\r");

		call Mac.enableReceive();

		return packet;
	}

	event void Mac.reset() {
	
	}

  
	/////////////////////////////////////////////////////////////////////////
	// Console
	/////////////////////////////////////////////////////////////////////////
	async event result_t ConsoleIn.get(uint8_t uartData) {
		atomic console_data = uartData;
		post handleGet();

		return SUCCESS;
	}


	/** Help function, does string compare */
	int strcmp(const char * a, const char * b)
	{
		while (*a && *b && *a == *b) { ++a; ++b; };
		return *a - *b;
	}
	
	/** Help function, does string compare */
	int strcmp2(const char * a, const char * b, uint8_t num)
	{
		uint8_t i = 1;
		while (*a && *b && *a == *b && i < num) { ++a; ++b; ++i; };
		return *a - *b;
	}
  
	int parseArg(const char* from)
	{
		int i = 1000;
		int num = 0;
		while(*from) {
			num = num + (i * (((unsigned int) *from) - 48));	
			i = i / 10;
			from++;
		} 
		return num;
	} 

	task void handleGet()
	{
		char console_transmit[2];
		atomic console_transmit[0] = console_data;
		console_transmit[1] = 0;
		call ConsoleOut.print(console_transmit); 

		/* Check if enter was pressed */
		if (console_transmit[0] == 10) {
			/* If enter was pressed, "handle" command */
			if (0 == strcmp("", cmd_input)) {

			} else if (0 == strcmp("dcf77", cmd_input)) {

				post printDCF77Task();				
			} else if (0 == strcmp("send", cmd_input)) {

				post transmitPacket();				
			} else if (0 == strcmp("start", cmd_input)) {
			
				call TPMTimer32.start(busClock / 3);
				
			} else if (0 == strcmp("stop", cmd_input)) {

				call TPMTimer32.stop();

			} else {
				call ConsoleOut.print("tosh: ");
				call ConsoleOut.print(cmd_input);
				call ConsoleOut.print(": command not found\n\r");
			}
			/* Get ready for a new command */
			bufpoint = cmd_input;
			*bufpoint = 0;

		} else {
			/* Store character in buffer */
			if (bufpoint < (cmd_input + sizeof(cmd_input))) {
				*bufpoint = console_transmit[0];
				++bufpoint;
				*bufpoint = 0;
			}
		}
	}

	/////////////////////////////////////////////////////////////////////////
	// Transmit task
	/////////////////////////////////////////////////////////////////////////
	task void transmitPacket() {
		struct Timestamp *pack;
		uint32_t time;
	
		atomic {
			time = call DCF77.getTimestampInMilliseconds();
      	 
			pack = (struct Timestamp *) tx_buf;
			pack->address = serial;
			pack->timestamp = time;
		}
		
		tx_packet.dataLength = 6;

		if (call Mac.send(&tx_packet)) {

			call ConsoleOut.printBase10uint16(serial);
			call ConsoleOut.print(" ");

			call ConsoleOut.printBase10uint32(time);
			call ConsoleOut.print("\n\r");

		} else {

			call ConsoleOut.print("# Error sending packet\n\r");
		}

		serial++;
	}

	/////////////////////////////////////////////////////////////////////////
	// DCF77 print task
	/////////////////////////////////////////////////////////////////////////
	task void printDCF77Task() {
				
		call ConsoleOut.print("# DCF77 Signal:\n\r");
		call ConsoleOut.print("# Time stamp: ");
		call ConsoleOut.printBase10uint32(call DCF77.getTimestamp());
		call ConsoleOut.print("\n\r");

		call ConsoleOut.print("# Date stamp: ");
		call ConsoleOut.printBase10uint32(call DCF77.getDatestamp());
		call ConsoleOut.print("\n\r");
		
		call ConsoleOut.print("# Day of week: ");
		call ConsoleOut.printBase10uint8(call DCF77.getDayOfWeek());
		call ConsoleOut.print("\n\r");


	}



}
