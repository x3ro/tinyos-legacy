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



module DCF77HibernationM {
	provides {
		interface DCF77Hibernation;
	}

	uses { 
		interface DCF77;
		interface TPMTimer32;
	}
}

implementation {

	uint32_t compensateDrift(uint32_t sleep);

	/////////////////////////////////////////////////////////////////////////////////
	// Mode of operation
	/////////////////////////////////////////////////////////////////////////////////
	enum
	{	
		OFF = 0x00,
		TIMER = 0x01,
		DCF = 0x02,
	};
	
	uint8_t currentMode = 0;

	// control
	uint8_t inSync = 0, hibernating = 0;
	uint32_t estimatedBusClock = 1, maxSleepSeconds, estimatedSyncTime = 180;

	// wake-up
	uint16_t msecOffset = 0;
	uint32_t wakeUpTime = 0, secondsLeft = 0;


	/////////////////////////////////////////////////////////////////////////////////
	// Mutators
	/////////////////////////////////////////////////////////////////////////////////
	command result_t DCF77Hibernation.start() {
	
		estimatedBusClock = call DCF77.getEstimatedBusClock();
		
		return SUCCESS;
	}

	command uint32_t DCF77Hibernation.getWakeUpTime() {
	
		return wakeUpTime;
	}
	
	command result_t DCF77Hibernation.setOffset(uint16_t offset) {

		// msecOffset = (offset < 1000) ? offset : 999;
		msecOffset = offset;
		
		return SUCCESS;
	}
	
	command uint16_t DCF77Hibernation.getOffset() {
	
		return msecOffset;
	}
	
	/////////////////////////////////////////////////////////////////////////////////
	// Hibernation entry point
	//
	// Wake-up at the specified time - formatted as a UNIX timestamp 
	/////////////////////////////////////////////////////////////////////////////////
	command result_t DCF77Hibernation.hibernateUntil(uint32_t time) {
		uint32_t now, sleep, msec;

		// stop timer 
		call TPMTimer32.stop();

		// calculate sleep time
		now = call DCF77.getUnixTimestamp();
		wakeUpTime = time;
		secondsLeft = wakeUpTime - now; 

		maxSleepSeconds = 0xFFFF0000 / estimatedBusClock;

		//////////////////////////////////////////////////////////////////////////
		// CASE 1 
		// wakeUpTime is not in the future - no need to hibernate
		//////////////////////////////////////////////////////////////////////////
		if (wakeUpTime <= now) {

			return FAIL;

		//////////////////////////////////////////////////////////////////////////
		// CASE 2 
		// Sleeptime two seconds or less 
		// - set timer with msec accuracy 
		// - sleep with DCF77 turned on
		//////////////////////////////////////////////////////////////////////////
		} else if (secondsLeft <= 2) {
		
			msec = (secondsLeft * 1000) - call DCF77.getMilliseconds() + msecOffset;
			
			call TPMTimer32.start( (msec * estimatedBusClock) / 1000);
			secondsLeft = 0;

		//////////////////////////////////////////////////////////////////////////
		// CASE 3 
		// Sleeptime less than the synchronization time 
		// - set timer to 2 seconds before wakeUpTime 
		// - sleep with DCF77 turned on
		//////////////////////////////////////////////////////////////////////////
		} else if (secondsLeft <= estimatedSyncTime) {
		
			msec = (call DCF77.getMilliseconds() * estimatedBusClock) / 2000;

			call TPMTimer32.start( (secondsLeft - 2) * estimatedBusClock - msec);
			secondsLeft = 2;
			
		//////////////////////////////////////////////////////////////////////////
		// CASE 4 
		// Sleeptime less than the maximal sleep interval 
		// - set timer to wakeUpTime minus time needed for synchronization
		// - sleep with DCF77 turned off
		//////////////////////////////////////////////////////////////////////////
		} else if (secondsLeft <= maxSleepSeconds) {
		
			sleep = secondsLeft - estimatedSyncTime;
			secondsLeft -= sleep;
			
			// compensate for 0.5% clock drift and 5% chip deviation
			sleep = compensateDrift(sleep);
			
			call TPMTimer32.start(sleep * estimatedBusClock);

			call DCF77.stop();
			
		//////////////////////////////////////////////////////////////////////////
		// CASE 4 
		// Sleeptime greater than the maximal sleep interval 
		// - set timer to the maximal sleep interval
		// - sleep with DCF77 turned off
		// - allow enough time for DCF77 synchronization
		//////////////////////////////////////////////////////////////////////////
		} else if (secondsLeft > maxSleepSeconds) {


			if (secondsLeft < (estimatedSyncTime + maxSleepSeconds) ) {

				sleep = secondsLeft - estimatedSyncTime;
				secondsLeft = estimatedSyncTime;
			} else {

				sleep = maxSleepSeconds;
				secondsLeft -= maxSleepSeconds;
			}

			// compensate for 0.5% clock drift and 5% chip deviation
			sleep = compensateDrift(sleep);

			call TPMTimer32.start(sleep * estimatedBusClock);

			call DCF77.stop();
		}

				
		atomic inSync = 0;
		currentMode = TIMER;

		return SUCCESS;
	}

	/////////////////////////////////////////////////////////////////////////////////
	// Synchronization complete
	//
	// Decide whether to continue hibernating or prepare to wake-up 
	/////////////////////////////////////////////////////////////////////////////////
	event result_t DCF77.inSync(uint32_t clock) {
		uint32_t now, sleep, msec;
	
		atomic inSync = 1;
		estimatedBusClock = clock;

		if (currentMode != DCF) {

			return SUCCESS;
		} else {

			call TPMTimer32.stop();

			now = call DCF77.getUnixTimestamp();

			if (now < wakeUpTime) {

				currentMode = TIMER;
				secondsLeft = wakeUpTime - now; 
			
				//////////////////////////////////////////////////////////////////////////
				// CASE 2 
				//////////////////////////////////////////////////////////////////////////
				if (secondsLeft <= 2) {
		
					msec = (secondsLeft * 1000) - call DCF77.getMilliseconds() + msecOffset;

					call TPMTimer32.start( (msec * estimatedBusClock) / 1000);
					secondsLeft = 0;

				//////////////////////////////////////////////////////////////////////////
				// CASE 3 
				//////////////////////////////////////////////////////////////////////////
				} else if (secondsLeft <= estimatedSyncTime) {

					msec = (call DCF77.getMilliseconds() * estimatedBusClock) / 2000;

					call TPMTimer32.start( (secondsLeft - 2) * estimatedBusClock - msec);
					secondsLeft = 2;

				//////////////////////////////////////////////////////////////////////////
				// CASE 4 
				//////////////////////////////////////////////////////////////////////////
				} else if (secondsLeft <= maxSleepSeconds) {

					sleep = secondsLeft - estimatedSyncTime;
					secondsLeft -= sleep;

					// compensate for 0.5% clock drift and 0.5% chip deviation
					sleep = compensateDrift(sleep);
					
					call TPMTimer32.start(sleep * estimatedBusClock);

					call DCF77.stop();

				//////////////////////////////////////////////////////////////////////////
				// CASE 5 
				//////////////////////////////////////////////////////////////////////////
				} else if (secondsLeft > maxSleepSeconds) {

					if (secondsLeft < (estimatedSyncTime + maxSleepSeconds) ) {

						sleep = secondsLeft - estimatedSyncTime;
						secondsLeft = estimatedSyncTime;
					} else {

						sleep = maxSleepSeconds;
						secondsLeft -= maxSleepSeconds;
					}

					// compensate for 0.5% clock drift and 5% chip deviation
					sleep = compensateDrift(sleep);

					call TPMTimer32.start(sleep * estimatedBusClock);

					call DCF77.stop();

				}
			} else {
				//////////////////////////////////////////////////////////////////////////
				// CASE 1 
				//////////////////////////////////////////////////////////////////////////

				currentMode = OFF;

				call TPMTimer32.start(estimatedBusClock);
				signal DCF77Hibernation.wakeUp(now - wakeUpTime);
			}
		}

		return SUCCESS;
	}

	event result_t DCF77.outSync() {

		atomic inSync = 0;

		return SUCCESS;
	}


	/////////////////////////////////////////////////////////////////////////////////
	// Timer fired
	//
	// Decide whether to wake-up or see what time it is 
	/////////////////////////////////////////////////////////////////////////////////
	async event result_t TPMTimer32.fired() {
		uint32_t sleep, msec, now;
	
		if (currentMode == TIMER) {

			//////////////////////////////////////////////////////////////////////////
			// CASE 1 
			//////////////////////////////////////////////////////////////////////////
			if (secondsLeft == 0) {

				currentMode = OFF;

				now = call DCF77.getUnixTimestamp();

				call TPMTimer32.start(estimatedBusClock);
				signal DCF77Hibernation.wakeUp(now - wakeUpTime);

			//////////////////////////////////////////////////////////////////////////
			// CASE 2 
			//////////////////////////////////////////////////////////////////////////
			} else if (secondsLeft <= 2) {

				currentMode = TIMER;

				msec = (secondsLeft * 1000) - call DCF77.getMilliseconds() + msecOffset;
				call TPMTimer32.start( (msec * estimatedBusClock) / 1000);
				secondsLeft = 0;

			//////////////////////////////////////////////////////////////////////////
			// CASE 3 & 4 
			//////////////////////////////////////////////////////////////////////////
			} else if (secondsLeft <= maxSleepSeconds) {

				currentMode = DCF;

				call TPMTimer32.start(estimatedSyncTime * estimatedBusClock);
				call DCF77.start(1);

			//////////////////////////////////////////////////////////////////////////
			// CASE 5 
			//////////////////////////////////////////////////////////////////////////
			} else if (secondsLeft > maxSleepSeconds) {

				currentMode = TIMER;

				if (secondsLeft < (estimatedSyncTime + maxSleepSeconds) ) {

					sleep = secondsLeft - estimatedSyncTime;
					secondsLeft = estimatedSyncTime;
				} else {

					sleep = maxSleepSeconds;
					secondsLeft -= maxSleepSeconds;
				}

				// compensate for 0.5% clock drift and 5% chip deviation
				sleep = compensateDrift(sleep);

				call TPMTimer32.start(sleep * estimatedBusClock);

				call DCF77.stop();

			}

		} else if (currentMode == DCF) {
		
			// panic!
			// DCF77 could not synchronize within allocated time
			// set wake-up solely on timer
			call DCF77.stop();

			if (secondsLeft == estimatedSyncTime) {
				currentMode = OFF;

				call TPMTimer32.start(estimatedBusClock);
				signal DCF77Hibernation.wakeUp(wakeUpTime);
				
			} else {

				currentMode = TIMER;

				secondsLeft -= estimatedSyncTime;

				call TPMTimer32.start(secondsLeft * estimatedBusClock);
				secondsLeft = 0;
			}

		} 


		return SUCCESS;
	}


	/////////////////////////////////////////////////////////////////////////////////
	// Internal function
	//
	// Reduces sleep with 1% 
	/////////////////////////////////////////////////////////////////////////////////
	uint32_t compensateDrift(uint32_t sleep) {
		uint32_t result;
	
		if (sleep < 1000) {

			result = (sleep * 990) / 1000;
		} else {

			result = (sleep / 1000) * 990;
		}

		return (result == 0) ? 1 : result;
	}
}


