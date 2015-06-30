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

module TestAMDutyM {
	provides {
		interface StdControl;
	}

	uses {
		interface SimpleMac as Mac;
		interface DCF77;
		interface TPMTimer32;

		interface LocalCounter;

		interface StdControl as ConsoleControl;
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;

		interface StdControl as AMTransmitterControl;
		interface StdControl as AMReceiverControl;
		interface AMTransceiver;
	}
}

implementation {

#define GATEWAY 		27
#define OFFPERIOD		5
#define TRANSMITWINDOW		500
#define WINDOWDELAY		10
#define FIRSTMOTE		25
#define LASTMOTE		32

	task void transmitTask();
	task void printDCF77Task();
	task void roundRobinTask();

	task void printTxDone();
	task void printTxSend();
	task void printRx();
	void idle();


	// SimpleMAC packet	
	tx_packet_t tx_packet;
	char tx_buf[29] = "abcdefghijklmnopqrstuvwxyzabc";

	uint32_t receivedData, receivedTimestamp;	
	uint32_t totalReceived = 0, correctReceived = 0;
	uint16_t counter = 0;
	
	uint32_t rx_address, rx_counter, tx_send, tx_done;

	enum
	{	
		IDLE = 0,
		SLEEP = 1,
		SENDWAKEUP = 2,
		TRANSMIT = 3,
		SENDSLEEP = 4,
		GOTOSLEEP = 5,
	};

	uint8_t currentState = IDLE;	
	uint16_t activeMote = 0;
	uint32_t msecWindow, secPeriod, delay, lastTurnOn = 0;
	
	/////////////////////////////////////////////////////////////////////////
	// StdControl
	/////////////////////////////////////////////////////////////////////////
	command result_t StdControl.init() {
		// SMAC sucks
		extClock = 16000000;

 		tx_packet.data = tx_buf;
    
		if (call Mac.init()) {
			call Mac.setChannel(7);
		}

		call DCF77.init();
		call AMTransmitterControl.init();
		call AMReceiverControl.init();

    		call ConsoleControl.init();

    
		return SUCCESS;
	}


	command result_t StdControl.start()
	{
		//call DCF77.start(1);
		//call DCF77.stop();
				
		call ConsoleControl.start();
		call ConsoleOut.print("\n\r# TestAMDutyM.nc booted\n\r");

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

		call AMTransmitterControl.start();
		call AMReceiverControl.start();
		
		
		call AMTransceiver.setBaudrate(800);
		
		msecWindow = TRANSMITWINDOW * busClock / 128000;
		secPeriod = OFFPERIOD * busClock / 128;
		delay = WINDOWDELAY * secPeriod / 100;
		
		// call Mac.enableReceive();


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

	/////////////////////////////////////////////////////////////////////////
	// TPM Timer
	/////////////////////////////////////////////////////////////////////////
	async event result_t TPMTimer32.fired() {
		uint32_t tmp, counter;
		
		call TPMTimer32.stop();

		if (TOS_LOCAL_ADDRESS == GATEWAY) {

			if (currentState == IDLE) {

				idle();

			} else if (currentState == TRANSMIT) {

				// if (rx_address != activeMote) {
				// 	call ConsoleOut.print("# No respond from mote ");
				// 	call ConsoleOut.printBase10uint16(activeMote);
				// 	call ConsoleOut.print("\n\r");
				// }

				currentState = IDLE;
				idle();

			} else if (currentState == SLEEP) {

				call ConsoleOut.print("# Gateway wake-up\n\r");

				currentState = IDLE;
				idle();
			}

		} else {

			if (currentState == IDLE) {

				call Mac.disableReceive();
				call AMReceiverControl.stop();

				// if missed sync signal - reset counter
				tmp = call LocalCounter.getLowCounter();
				if (lastTurnOn + secPeriod < tmp) {
				
					lastTurnOn = 0;
				}

				call TPMTimer32.start(secPeriod - msecWindow - delay);
				currentState = SLEEP;

				call ConsoleOut.print("# Turn off low-power listener\n\r");
			
			} else if (currentState == SLEEP) {
			
				currentState = IDLE;
				call AMReceiverControl.start();
				call TPMTimer32.start(msecWindow + delay);

				call ConsoleOut.print("# Turn on low-power listener\n\r");

			}
		
		}
				
		return SUCCESS;
	
	}
  
	/////////////////////////////////////////////////////////////////////////
	// AM Radio
	/////////////////////////////////////////////////////////////////////////
	async event result_t AMTransceiver.putDone() {
		uint32_t counter;

		// call ConsoleOut.print("# Transmitting done\n\r");		

		// tx_done = call LocalCounter.getLowCounter();
		// post printTxDone();

		if (currentState == IDLE) {
		
			idle();
					
		} else if (currentState == SENDWAKEUP) {

			call Mac.enableReceive();
			
			currentState = TRANSMIT;

		} 

		return SUCCESS;
	}
  	
	async event result_t AMTransceiver.get(uint32_t data, uint32_t timestamp) {
		uint16_t address, code;
		uint32_t tmp;

		// call ConsoleOut.printBase10uint32(receivedData);
		// call ConsoleOut.print(" ");
		// call ConsoleOut.printBase10uint32(receivedTimestamp);
		// call ConsoleOut.print("\n\r");

		address = (data & 0xffff0000) >> 16;
		code = (data & 0x0000ffff);

		if (address == TOS_LOCAL_ADDRESS) {

			if (code == 0) {
				// call TPMTimer32.stop();

				call Mac.disableReceive();
				call ConsoleOut.print("# Goto sleep \n\r");
			
			} else {

				call Mac.enableReceive();
				
				if (lastTurnOn != 0) {

					tmp = call LocalCounter.getLowCounter();
					secPeriod = tmp - lastTurnOn;
					lastTurnOn = tmp;
					
					call TPMTimer32.start(msecWindow);

				} else {
				
					lastTurnOn = call LocalCounter.getLowCounter();
				}
				

				post transmitTask();

				call ConsoleOut.print("# Wake-up received \n\r");

			}
		}

		return SUCCESS;
	}

	/////////////////////////////////////////////////////////////////////////
	// SimpleMAC
	/////////////////////////////////////////////////////////////////////////
	event void Mac.sendDone(tx_packet_t * packet) {

		call ConsoleOut.print("# Senddone\n\r");
	}


	event rx_packet_t * Mac.receive(rx_packet_t * packet) {
		struct Timestamp *pack;
		uint32_t message;

		pack = (struct Timestamp *) (*packet).data;
		
		rx_counter = call LocalCounter.getLowCounter();
		rx_address = pack->address;

		post printRx();

		if (TOS_LOCAL_ADDRESS == GATEWAY) {
		
			if (currentState == TRANSMIT) {
			
				message = pack->address;
				message = message << 16;
			
				call AMTransceiver.put(message);

				// call ConsoleOut.print("# Goto sleep mote ");
				// call ConsoleOut.printBase10uint16(pack->address);
				// call ConsoleOut.print("\n\r");
			}

		}

		// call Mac.enableReceive();

		return packet;
	}

	event void Mac.reset() {
	
	}

  
	/////////////////////////////////////////////////////////////////////////
	// Console
	/////////////////////////////////////////////////////////////////////////
	async event result_t ConsoleIn.get(uint8_t theChar) {
		char echo[2];
		char * ptr;
		uint32_t tmp;
		
		ptr = echo;
		echo[1] = 0;
		*ptr = theChar;


		if (theChar == '\r') {

			call ConsoleOut.print("\n\r");

		} else if (theChar == 'p') {
	
			post printDCF77Task();

		} else if (theChar == 't') {

			post transmitTask();

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

		} else if (theChar == 'w') {

			TOS_LOCAL_ADDRESS = GATEWAY;
			
			currentState = SENDWAKEUP;
			activeMote = FIRSTMOTE;		
			tmp = activeMote * 0x00010000 + 1;
			call AMTransceiver.put(tmp);

			call TPMTimer32.start(msecWindow);
			call ConsoleOut.print("# Start\n\r");

		} else if (theChar == 's') {

			call ConsoleOut.print("# Stop timer\n\r");
			call TPMTimer32.stop();

			currentState = SLEEP;
			
		} else {
			call ConsoleOut.print(echo);
		}

		return SUCCESS;
	}

	/////////////////////////////////////////////////////////////////////////
	// Transmit Task
	/////////////////////////////////////////////////////////////////////////
	task void transmitTask() {
		struct Timestamp *pack;
		uint32_t time;
	
		atomic {
			time = call DCF77.getTimestampInMilliseconds();
      	 
			pack = (struct Timestamp *) tx_buf;
			pack->address = TOS_LOCAL_ADDRESS;
			pack->timestamp = time;
		}
		
		tx_packet.dataLength = 6;

		call Mac.send(&tx_packet);
	}


	/////////////////////////////////////////////////////////////////////////
	// Print DCF77 Task
	/////////////////////////////////////////////////////////////////////////
	task void printDCF77Task() {
				
		// call ConsoleOut.print("# DCF77 Signal:\n\r");
		// call ConsoleOut.print("# Time stamp: ");
		call ConsoleOut.print("# ");
		call ConsoleOut.printBase10uint32(call DCF77.getTimestamp());
		call ConsoleOut.print("\n\r");

		// call ConsoleOut.print("# Date stamp: ");
		// call ConsoleOut.printBase10uint32(call DCF77.getDatestamp());
		// call ConsoleOut.print("\n\r");
		
		// call ConsoleOut.print("# Day of week: ");
		// call ConsoleOut.printBase10uint8(call DCF77.getDayOfWeek());
		// call ConsoleOut.print("\n\r");


	}

	task void printTxDone() {
		call ConsoleOut.print("# tx_done");
		call ConsoleOut.printBase10uint32(tx_done);
		call ConsoleOut.print("\n\r");
	}
	
	task void printTxSend() {
		call ConsoleOut.print("# tx_send");
		call ConsoleOut.printBase10uint32(tx_send);
		call ConsoleOut.print("\n\r");
	}

	task void printRx() {
		call ConsoleOut.printBase10uint32(rx_counter);
		call ConsoleOut.print(" ");
		call ConsoleOut.printBase10uint16(rx_address);
		call ConsoleOut.print("\n\r");
	
	}

	/////////////////////////////////////////////////////////////////////////
	// idle function
	/////////////////////////////////////////////////////////////////////////
	void idle() {
		uint32_t counter;
	
		if (activeMote < LASTMOTE) {

			if (activeMote == 26) {
				activeMote = 28;
			} else if (activeMote == 28) {
				activeMote = 31;
			} else {
				activeMote++;
			}
			
			// call ConsoleOut.print("# Wake-up mote ");
			// call ConsoleOut.printBase10uint16(activeMote);
			// call ConsoleOut.print("\n\r");

			currentState = SENDWAKEUP;

			// tx_send = call LocalCounter.getLowCounter();
			// post printTxSend();

			call AMTransceiver.put(activeMote * 0x00010000 + 1);
			call TPMTimer32.start(msecWindow);

		} else {

			call Mac.disableReceive();
			call TPMTimer32.start(secPeriod);
			activeMote = FIRSTMOTE - 1;
			currentState = SLEEP;

			call ConsoleOut.print("# Gateway sleep\n\r");
		}

	}

}
