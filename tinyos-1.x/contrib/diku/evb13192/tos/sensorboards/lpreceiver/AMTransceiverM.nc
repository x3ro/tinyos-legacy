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


module AMTransceiverM {
	provides {
		interface StdControl as AMTransmitterControl;
		interface StdControl as AMReceiverControl;
		interface AMTransceiver;
	}

	uses { 
		interface AMTransmitter;
		interface AMReceiver;
	}
}

implementation {

	uint32_t rx_timestamp;

	///////////////////////////////////////////////////////////////////////
	// Transmitter StdControl
	///////////////////////////////////////////////////////////////////////
	command result_t AMTransmitterControl.init() {

		return call AMTransmitter.init();
	}

	command result_t AMTransmitterControl.start() {

		return call AMTransmitter.start();
	}

	command result_t AMTransmitterControl.stop() {

		return call AMTransmitter.stop();
	}

	///////////////////////////////////////////////////////////////////////
	// Receiver StdControl
	///////////////////////////////////////////////////////////////////////
	command result_t AMReceiverControl.init() {

		return call AMReceiver.init();
	}

	command result_t AMReceiverControl.start() {

		return call AMReceiver.start();
	}

	command result_t AMReceiverControl.stop() {

		return call AMReceiver.stop();
	}

	///////////////////////////////////////////////////////////////////////
	// Transceiver commands
	///////////////////////////////////////////////////////////////////////
	command result_t AMTransceiver.setBaudrate(uint16_t rate) {
	
		call AMTransmitter.setBaudrate(rate);
		
		return SUCCESS;
	}

	command result_t AMTransceiver.put(uint32_t data) {
	
		call AMTransmitter.put(data);
		
		return SUCCESS;
	}

	///////////////////////////////////////////////////////////////////////
	// Transceiver async events
	///////////////////////////////////////////////////////////////////////
	async event result_t AMTransmitter.putDone() {

		signal AMTransceiver.putDone();

		return SUCCESS;
	}
	
	async event result_t AMReceiver.get(uint32_t data, uint32_t timestamp) {
	
		signal AMTransceiver.get(data,timestamp);	
		
		return SUCCESS;
	}
}
