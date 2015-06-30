/* Copyright (c) 2006, Marcus Chang, Klaus Madsen
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
        Author:         Marcus Chang <marcus@diku.dk>
        Klaus S. Madsen <klaussm@diku.dk>
        Last modified:  March, 2007
*/


module DataCollectorMoteM {
	provides {
		interface StdControl;
	}

	uses {
        interface StdControl as ControllerControl;
		interface StdControl as SamplingControl;
		interface StdControl as CompressionControl;
		interface StdControl as FlashManagerControl;
		interface StdControl as ProtocolControl;
        interface StdOut as StdOutInit;
		interface Spi;
	}
}

implementation {


	command result_t StdControl.init() 
	{
		call Spi.init();

        call StdOutInit.init();
        call StdOutInit.print("Data Collector\n\r");
				
        call ControllerControl.init();
        
		call SamplingControl.init();
		call CompressionControl.init();
		call FlashManagerControl.init();
		call ProtocolControl.init();		
		
		LPMode_enable();
	
		return SUCCESS;
	}

	command result_t StdControl.start() 
	{

//		P1OUT &= ~0x40; /* turn off oscillator */

		call ProtocolControl.start();
		call FlashManagerControl.start();
		call CompressionControl.start();
		call SamplingControl.start();
        call ControllerControl.start();
		
		return SUCCESS;
	}

	command result_t StdControl.stop() {
		return SUCCESS;
	}
	
    async event result_t StdOutInit.get(uint8_t data) {

		return SUCCESS;
	}

}
