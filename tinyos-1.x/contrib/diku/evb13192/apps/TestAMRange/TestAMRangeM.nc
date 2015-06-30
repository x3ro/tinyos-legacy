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

module TestAMRangeM {
	provides {
		interface StdControl;
	}

	uses {
		interface SimpleMac as Mac;
		interface DCF77;
		interface TPMTimer32;

		interface LocalCounter;

		interface Leds;
		interface HPLKBI;

		interface StdControl as ConsoleControl;
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;

		interface StdControl as AMTransmitterControl;
		interface StdControl as AMReceiverControl;
		interface AMTransceiver;
	}
}

implementation {

#define GATEWAY 1000

	task void transmitTask();
	task void printDCF77Task();
	task void roundRobinTask();

	task void printTxDone();
	task void printTxWakeup();
	task void printRx();
	void idle();

	task void handleSwitchTask();
	task void amTask();
	task void fmTask();
	task void amTransmitTask();

	// SimpleMAC packet	
	tx_packet_t tx_packet;
	char tx_buf[29] = "abcdefghijklmnopqrstuvwxyzabc";

	uint32_t receivedData, receivedTimestamp;	
	uint32_t totalReceived = 0, correctReceived = 0;
	uint16_t counter = 0;
	
	uint32_t rx_address, rx_counter, tx_wakeup, tx_done;

	enum
	{	
		IDLE = 0,
		SLEEP = 1,
		SENDWAKEUP = 2,
		TRANSMIT = 3,
		SENDSLEEP = 4,
	};

	uint8_t currentState = IDLE, numberOfMotes = 4;	
	uint16_t activeMote = 0;
	uint32_t msecWindow = 400, secPeriod = 5, delay = 50;
	
	uint8_t theSw;
	uint16_t amTxCounter, amRxCounter, amTotalCounter, fmTxCounter, fmRxCounter, fmTotalCounter;
	
	
	uint16_t rate = 800;
	
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

		call Leds.init();
    		call HPLKBI.init();

		return SUCCESS;
	}


	command result_t StdControl.start()
	{
		//call DCF77.start(1);
		//call DCF77.stop();
				
		call ConsoleControl.start();
		call ConsoleOut.print("\n\r# TestAMRangeM.nc booted\n\r");

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
		
		call Leds.redOn();
		// call Leds.blueOn();
		
		call Mac.enableReceive();

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
		
		return SUCCESS;
	
	}
  
	/////////////////////////////////////////////////////////////////////////
	// AM Radio
	/////////////////////////////////////////////////////////////////////////
	async event result_t AMTransceiver.putDone() {
		uint32_t counter;

		call ConsoleOut.print("# Transmitting done\n\r");		

		if (amTxCounter < 1000) {
			amTxCounter++;
			call Leds.yellowToggle();
			
			post amTransmitTask();
		} else {

			call Leds.yellowOff();
		
		}

		return SUCCESS;
	}
  	
	async event result_t AMTransceiver.get(uint32_t data, uint32_t timestamp) {

		amTotalCounter++;
		
		if (data == 0xff00ff00) {

			amRxCounter++;
			
		}

		post amTask();

		return SUCCESS;
	}

	/////////////////////////////////////////////////////////////////////////
	// SimpleMAC
	/////////////////////////////////////////////////////////////////////////
	event void Mac.sendDone(tx_packet_t * packet) {

		call ConsoleOut.print("# Senddone\n\r");
		
		if (fmTxCounter < 1000) {
			fmTxCounter++;
			
			call Leds.redToggle();
			post transmitTask();
		} else {

			call Leds.redOff();
		
		}
		
	}


	event rx_packet_t * Mac.receive(rx_packet_t * packet) {
		struct Timestamp *pack;

		pack = (struct Timestamp *) (*packet).data;

		if (pack->address != 0) {
		
			fmRxCounter++;
		}

		fmTotalCounter++;
		post fmTask();
		
		call Mac.enableReceive();

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
		
			theSw = 1;
			post handleSwitchTask();
			call ConsoleOut.print("# Switch: 1\n\r");

		} else if (theChar == '2') {

			theSw = 2;
			post handleSwitchTask();
			call ConsoleOut.print("# Switch: 2\n\r");

		} else if (theChar == '3') {

			theSw = 3;
			post handleSwitchTask();
			call ConsoleOut.print("# Switch: 3\n\r");

		} else if (theChar == '4') {

			theSw = 4;
			post handleSwitchTask();
			call ConsoleOut.print("# Switch: 4\n\r");

		} else if (theChar == 'i') {

			call ConsoleOut.print("# TOS_LOCAL_ADDRESS: ");
			call ConsoleOut.printBase10uint16(TOS_LOCAL_ADDRESS);
			call ConsoleOut.print("\n\r");

		} else if (theChar == 'q') {

			call AMTransceiver.setBaudrate(200);
			call ConsoleOut.print("# Baud rate 200\n\r");

		} else if (theChar == 'w') {

			call AMTransceiver.setBaudrate(400);
			call ConsoleOut.print("# Baud rate 400\n\r");

		} else if (theChar == 'e') {

			call AMTransceiver.setBaudrate(600);
			call ConsoleOut.print("# Baud rate 600\n\r");

		} else if (theChar == 'r') {
			
			call AMTransceiver.setBaudrate(800);
			call ConsoleOut.print("# Baud rate 800\n\r");

		} else {
			call ConsoleOut.print(echo);
		}

		return SUCCESS;
	}

	/////////////////////////////////////////////////////////////////////////////////
	// Key Board related
	/////////////////////////////////////////////////////////////////////////////////

	async event result_t HPLKBI.switchDown(uint8_t sw)	{
		theSw = sw;
			
		post handleSwitchTask();
			
		return SUCCESS;
	}
		

	task void handleSwitchTask() {

		switch(theSw) {
			case 1:
				// call Leds.redOn();

				fmTxCounter = 1;
				fmTotalCounter = 0;
				fmRxCounter = 0;

				post transmitTask();

				break;
	
			case 2:
				// call Leds.greenOn();

				amTxCounter = 1;
				amTotalCounter = 0;
				amRxCounter = 0;

				post amTransmitTask();

				break;
					
			case 3:
						
				if (rate == 200) {
					call Leds.redOff();
					call Leds.greenOff();
					call Leds.yellowOn();
					call Leds.blueOff();
				
					rate += 200;
				} else if (rate == 400) {
					call Leds.redOff();
					call Leds.greenOn();
					call Leds.yellowOff();
					call Leds.blueOff();

					rate += 200;
				} else if (rate == 600) {
					call Leds.redOn();
					call Leds.greenOff();
					call Leds.yellowOff();
					call Leds.blueOff();

					rate += 200;
				} else if (rate == 800) {
					call Leds.redOn();
					call Leds.greenOff();
					call Leds.yellowOff();
					call Leds.blueOff();

				}

				call ConsoleOut.print("# Baud rate ");
				call ConsoleOut.printBase10uint16(rate);
				call ConsoleOut.print("\n\r");

				call AMTransceiver.setBaudrate(rate);

				break;
					
			case 4:
				if (rate == 200) {
					call Leds.redOff();
					call Leds.greenOff();
					call Leds.yellowOff();
					call Leds.blueOn();

				} else if (rate == 400) {
					call Leds.redOff();
					call Leds.greenOff();
					call Leds.yellowOff();
					call Leds.blueOn();

					rate -= 200;
				} else if (rate == 600) {
					call Leds.redOff();
					call Leds.greenOff();
					call Leds.yellowOn();
					call Leds.blueOff();

					rate -= 200;
				} else if (rate == 800) {
					call Leds.redOff();
					call Leds.greenOn();
					call Leds.yellowOff();
					call Leds.blueOff();
				
					rate -= 200;

				}

				call ConsoleOut.print("# Baud rate ");
				call ConsoleOut.printBase10uint16(rate);
				call ConsoleOut.print("\n\r");

				call AMTransceiver.setBaudrate(rate);
				
				break;
		}				

	}


	task void amTask() {
		uint32_t tmp;
		
		tmp = amRxCounter;
		tmp *= 1000;
		tmp /= amTotalCounter;
	
		call ConsoleOut.printBase10uint16(amTotalCounter);
		call ConsoleOut.print(" ");
		call ConsoleOut.printBase10uint32(tmp);
		call ConsoleOut.print("\n\r");

	}

	task void fmTask() {
		uint32_t tmp;
		
		tmp = fmRxCounter;
		tmp *= 1000;
		tmp /= fmTotalCounter;
	
		call ConsoleOut.printBase10uint16(fmTotalCounter);
		call ConsoleOut.print(" ");
		call ConsoleOut.printBase10uint32(tmp);
		call ConsoleOut.print("\n\r");

	}

	task void amTransmitTask() {

		call AMTransceiver.put(0xff00ff00);
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


}
