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


module PinControlM {
	provides {
		interface StdControl[uint8_t id];
	}

}

implementation {

	
	command result_t StdControl.init[uint8_t id]() {
	
		switch(id) {
			case 5:
				// Set power port C pin 5 as output pin
				PTCD_PTCD5 = 0;
				PTCDD_PTCDD5 = 1;
				break;
			case 6:
				// Set power port C pin 6 as output pin
				PTCD_PTCD6 = 0;
				PTCDD_PTCDD6 = 1;
				break;
			case 7:
				// Set power port C pin 7 as output pin
				PTCD_PTCD7 = 0;
				PTCDD_PTCDD7 = 1;
				break;
			default:
				return FAIL;
				break;
		}


		return SUCCESS;
	}

	command result_t StdControl.start[uint8_t id]() {

		switch(id) {
			case 5:
				// Turn on port C pin 5
				PTCD_PTCD5 = 1;
				PTCDD_PTCDD5 = 1;
				break;
			case 6:
				// Turn on port C pin 6
				PTCD_PTCD6 = 1;
				PTCDD_PTCDD6 = 1;
				break;
			case 7:
				// Turn on port C pin 7
				PTCD_PTCD7 = 1;
				PTCDD_PTCDD7 = 1;
				break;
			default:
				return FAIL;
				break;
		}

		return SUCCESS;
	}

	command result_t StdControl.stop[uint8_t id]() {

		switch(id) {
			case 5:
				// Turn off port C pin 5
				PTCD_PTCD5 = 0;
				break;
			case 6:
				// Turn off port C pin 6
				PTCD_PTCD6 = 0;
				break;
			case 7:
				// Turn off port C pin 7
				PTCD_PTCD7 = 0;
				break;
			default:
				return FAIL;
				break;
		}
	
		return SUCCESS;
	}
  
}
