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



module DCF77M {
	provides {
		interface DCF77;
	}

	uses { 
		interface StdControl as TPMControl;
		interface StdControl as ConradControl;
		interface TPM;
		interface TPMTimer16;
		interface TPMTimer32;
		interface LocalCounter;
	}
}

implementation {

	task void decodeTask();
	task void inSyncTask();
	task void outSyncTask();

	uint8_t ADC(uint32_t counter);
	uint8_t calculateSeconds(uint32_t counts);
	uint16_t calculateMilliseconds(uint32_t counts); 
	uint32_t calculateUnixTimestamp(); 
	uint32_t unixTimestamp(uint32_t sec, uint32_t min, uint32_t hour, 
				uint32_t dom, uint32_t month, uint32_t year);

	default event result_t DCF77.inSync(uint32_t calculatedBusClock) {return FAIL;}
	default event result_t DCF77.outSync() {return FAIL;}

	/////////////////////////////////////////////////////////////////////////////////
	// DCF77 Signal Encoding Schema
	/////////////////////////////////////////////////////////////////////////////////
	typedef struct {
	
		// uint16_t reserved	: 15;
		uint8_t antenna		: 1; // R - antenna bit 1 when secondary is used
		uint8_t deltaDST	: 1; // A1 - 1 when DST change in the next hour
		uint8_t DST		: 1; // Z1 - timezone bit - 1 when DST is set
		// uint8_t Z2		: 1; // Z2 - 2nd bit - usually opposite Z1
		uint8_t leap_second	: 1; // A2 - 1 when leap second is inserted
		// uint8_t S		: 1; // S - start bit - always 1
		uint8_t minute		: 7; // M - minutes
		// uint8_t P1		: 1; // P1 - even parity for all transmitted bits
		uint8_t hour		: 6; // H - hours
		// uint8_t P2		: 1; // P2 - even parity for all transmitted bits
		uint8_t day_of_month	: 6; // DM - day of month
		uint8_t day_of_week	: 3; // DW - day of week
		uint8_t month		: 5; // MN - month
		uint8_t year		: 8; // Y - year
		// uint8_t P3		: 1; // P3 - even parity for all transmitted bits
	
	} dcf77_t;
	
	/////////////////////////////////////////////////////////////////////////////////
	// Clock Source
	/////////////////////////////////////////////////////////////////////////////////
	enum
	{	
		INTERNAL = 0x00,
		EXTERNAL = 0x01,
	};
	
	uint8_t highPrecisionClock = 0;

	/////////////////////////////////////////////////////////////////////////////////
	// Finite State Machine
	/////////////////////////////////////////////////////////////////////////////////
	enum
	{	
		INIT = 0x00,
		SECONDS = 0x01,
		FRAME = 0x02,
		BITS = 0x03,
	};
	
	uint8_t currentState = 0;
	
	/////////////////////////////////////////////////////////////////////////////////
	// Control variables
	/////////////////////////////////////////////////////////////////////////////////
	uint8_t possibleSignalDetected = 0, frameDetectionRetries = 0;
	uint8_t inSync = 0, lastSync = 0, turnedOn = 0, dcfSeconds;

	// Signal classification variables
	uint32_t lastFalling, estimatedBusClock, estimatedEdge, deviation, initBusClock;

	// DCF struct used for signal reception and decoding
	uint8_t dcf77[2][60];
	dcf77_t this;
	uint8_t listenBank = 0, decodeBank = 1;

	// Status of DCF struct (which variables are synchronized)
	bool dcfDecodedMinutes = 0, dcfDecodedHours = 0, dcfDecodedDate = 0;

	/////////////////////////////////////////////////////////////////////////////////
	// Timing	
	/////////////////////////////////////////////////////////////////////////////////
	uint32_t countsThisMinute = 0, tmpCountsThisMinute = 0, counterBank = 0;
	uint32_t secondsSinceLastSync = 0;
	uint16_t millisecondsAtLastSync = 0;

	
	/////////////////////////////////////////////////////////////////////////////////
	// Modified StdControl
	// Extended start() with estimated counterclock start(counterclock)
	/////////////////////////////////////////////////////////////////////////////////
	command result_t DCF77.init() {
		uint8_t i;
		result_t result;

		// Initialize timer port and prepare power output
		result = call TPMControl.init();
		result *= call ConradControl.init();

		// reset databank
		for (i = 0; i < 59; i++) {
			dcf77[listenBank][i] = 2;
			dcf77[decodeBank][i] = 2;
		}

		// reset dcf77 struct
		this.antenna = 0;
		this.deltaDST = 0;
		this.DST = 0;
		this.leap_second = 0;
		this.minute = 0;
		this.hour = 0;
		this.day_of_month = 0;
		this.day_of_week = 0;
		this.month = 0;
		this.year = 0;

		return result;
	}

	command result_t DCF77.start(uint8_t clockSource) {
		uint8_t divider;
		uint16_t i;
		result_t result;

		// Initialize estimated busclock, edge length and deviation
		// deviation set loosely to increase lock
		// initBusClock = currentBusClock;
		divider = call TPM.setClockSource(clockSource);
		highPrecisionClock = call TPM.returnClockSource();
		
		if (highPrecisionClock == 1) {
			initBusClock = extClock / (2 * divider);
		} else {
			initBusClock = busClock / divider;
		}

		estimatedBusClock = initBusClock;
		estimatedEdge = estimatedBusClock * 10 / 100;
		deviation = estimatedEdge / 2;

		// Turn on Conrad Receiver
		result = call ConradControl.start();
		
		// busy-wait to avoid detecting power-on artifacts
		for (i = 1; i <  3200; i++) 
			asm("nop");
			
		result *= call TPMControl.start();

		currentState = INIT;
		
		atomic turnedOn = 1;

		return result;
	}

	command result_t DCF77.stop() {
		result_t result;

		// Turn off Conrad Receiver
		result = call TPMControl.stop();
		result *= call ConradControl.stop();

		atomic turnedOn = 0;

		post outSyncTask();

		return result;
	}

	command uint32_t DCF77.getEstimatedBusClock() {
	
		return estimatedBusClock;
	}

	/////////////////////////////////////////////////////////////////////////////////
	// Time
	// getMillisecons/Seconds/Minutes/Hours/DayOfMonth/DayOfWeek/Year
	//
	// Commands to format the DCF77 timestamp in different ways.
	// If inSync the DCF-struct is used else the timer based seconds
	/////////////////////////////////////////////////////////////////////////////////
	command uint32_t DCF77.getUnixTimestamp() {
	
		return calculateUnixTimestamp();
	}

	command uint32_t DCF77.getTimestamp() {
		uint32_t msec, sec, min, hour, tmp;
	
		if (inSync == 1) {
			atomic {
				tmp = call LocalCounter.getInteruptCounter();
				tmp += countsThisMinute;

				msec = calculateMilliseconds(tmp);
				sec = calculateSeconds(tmp);
				min = this.minute;
				hour = this.hour;
			}
				
		} else {

			atomic {
				msec = millisecondsAtLastSync;
				sec = secondsSinceLastSync;
				min = this.minute;
				hour = this.hour;
			}
		}



		if (sec > 59) {
			min += sec / 60;
			sec %= 60;
		}

		if (min > 59) {
			hour = (hour + (min / 60)) % 24;
			min %= 60;
		}

		return msec + sec*1000 + min*100000 + hour*10000000;
			
	}

	command uint32_t DCF77.getTimestampInMilliseconds() {
		uint32_t msec, sec, min, hour, tmp;

	
		if (inSync == 1) {
			atomic {
				tmp = call LocalCounter.getInteruptCounter();
				tmp += countsThisMinute;

				msec = calculateMilliseconds(tmp);
				sec = calculateSeconds(tmp);
				min = this.minute;
				hour = this.hour;
			}
		
		} else {

			atomic {
				msec = millisecondsAtLastSync;
				sec = secondsSinceLastSync;
				min = this.minute;
				hour = this.hour;
			}

			if (sec > 59) {
				min += sec / 60;
				sec %= 60;
			}

			if (min > 59) {
				hour = (hour + (min / 60)) % 24;
				min %= 60;
			}
		}

		return msec 
			+ sec*1000 
			+ min*60*1000 
			+ hour*60*60*1000;
	}

	command uint32_t DCF77.getDatestamp() {
		uint32_t dom, month, year;

		atomic {
			dom = this.day_of_month;
			month = this.month;
			year = this.year;
		}
	
		if (inSync == 1) {
		
			return dom + month*100 + year*10000 + 20000000;
		} else {
				
			return dom + month*100 + year*10000 + 20000000;
		}
	}

	command uint16_t DCF77.getMilliseconds() {
		uint32_t tmp;
	
		if (inSync == 1) {
			atomic {
				tmp = call LocalCounter.getInteruptCounter();
				tmp += countsThisMinute;
			}

			return calculateMilliseconds(tmp);
		} else {
			return millisecondsAtLastSync;
		}
	}
	
	command uint8_t DCF77.getSeconds() {
		uint32_t tmp;
	
		if (inSync == 1) {
			atomic {
				tmp = call LocalCounter.getInteruptCounter();
				tmp += countsThisMinute;
			}

			return calculateSeconds(tmp) % 60;
		} else {
			return secondsSinceLastSync % 60;
		}
	}
	
	command uint8_t DCF77.getMinutes() {
		if (inSync) {
			return this.minute;
		} else {
			return (secondsSinceLastSync / 60) % 60;
		}
	}
	
	command uint8_t DCF77.getHours() {
		if (inSync) {
			return this.hour;
		} else {
			return (secondsSinceLastSync / (60*60) ) % 24;
		}
	}
		
	command uint8_t DCF77.getDayOfMonth() {
		if (inSync) {
			return this.day_of_month;
		} else {
			return 0;
		}
	}
	
	command uint8_t DCF77.getDayOfWeek() {
		if (inSync) {
			return this.day_of_week;
		} else {
			return 0;
		}
	}
	
	command uint8_t DCF77.getMonth() {
		if (inSync) {
			return this.month;
		} else {
			return 0;
		}
	}
	
	command uint8_t DCF77.getYear() {
		if (inSync) {
			return this.year;
		} else {
			return 0;
		}
	}

	/////////////////////////////////////////////////////////////////////////////////
	// out-of-sync counting
	//
	// Used to keep track of time, even if the DCF77 signal is lost.
	/////////////////////////////////////////////////////////////////////////////////
	async event result_t TPMTimer16.fired() {

		return SUCCESS;
	}

	async event result_t TPMTimer32.fired() {

		if (turnedOn == 1) {
			secondsSinceLastSync++;
		} 
		
		return SUCCESS;
	}

	
	/////////////////////////////////////////////////////////////////////////////////
	// DCF77 signal reception
	//
	// A 4 step FSM is used to lock on to the DCF77 signal. 
	// Each received bit are used to fill the DCF77 buffer. When done a decoding 
	// task i posted, and the DCF77 buffer swapped.
	/////////////////////////////////////////////////////////////////////////////////
	async event result_t TPM.signalReceived(uint8_t edge, uint32_t counter) {
	
		if (turnedOn == 0) {
			return FAIL;
		}


		if (currentState == INIT) {
		
			// look for pulse with a width of 100-200ms
			if (edge == 1
				&& counter > (estimatedEdge - deviation) 
				&& counter < (2*estimatedEdge + deviation) ) {
				
				// remember when last signal started
				lastFalling = counter;
				
				// advance to next state
				currentState = SECONDS;
			
			}
		
		} else if (currentState == SECONDS) {

		
			if (edge == 0) {
						
				// update time since last signal started
				lastFalling += counter;

				// approximately 1 sec. has passed
				// note: DCF frame indicator is not used
				if (lastFalling > (estimatedBusClock - deviation) 
				&& lastFalling < (estimatedBusClock + deviation) ) {

					// expect a signal wide pulse
					possibleSignalDetected = 1;

				}
				
			} else {

				
				// look for pulse with a width of 100-200ms
				if (counter > (estimatedEdge - deviation) 
				&& counter < (2*estimatedEdge + deviation) ) {
				
					// was signal anticipated
					if (possibleSignalDetected == 1) {
					
						possibleSignalDetected = 0;

						if (highPrecisionClock == 0) {
							// use measured counts as new estimatedBusClock
							estimatedBusClock = lastFalling;
							estimatedEdge = estimatedBusClock * 10 / 100;
							deviation = estimatedEdge / 2;
						}
						
						// advance to next state
						currentState = FRAME;
					} 
					
					// else
					// keep looking for second synchronization
			
					// begin measurement of next second
					lastFalling = counter;
				} else {
				
					// noisy signal - keep measuring
					lastFalling += counter;
				}
			}
			
		} else if (currentState == FRAME) {

		
			// look for pulse with a width of 100-200ms
			if (edge == 1
				&& counter > (estimatedEdge - deviation) 
				&& counter < (2*estimatedEdge + deviation) ) {
				
				// approximately 1 sec. has passed
				if (lastFalling > (estimatedBusClock - deviation) 
				&& lastFalling < (estimatedBusClock + deviation) ) {
				
					// no frame found, but at least in sync
					
					if (highPrecisionClock == 0) {
						// estimate new estimatedBusClock
						estimatedBusClock = (estimatedBusClock + lastFalling) / 2;
						estimatedEdge = estimatedBusClock * 10 / 100;
						deviation = estimatedEdge / 2;
					}

				// approximately 2 secs. has passed
				} else if (lastFalling > (2 * estimatedBusClock - deviation) 
				&& lastFalling < (2 * estimatedBusClock + deviation) ) {

					// DCF frame detected
					dcfSeconds = 0;
					
					// decode bit
					dcf77[listenBank][dcfSeconds] = ADC(counter);

					// increment seconds
					dcfSeconds++;

					// reset timing
					countsThisMinute = counter;
					
					// advance to next state
					currentState = BITS;
					
				} else {
				
					// PANIC! - unexpected signal
					if (highPrecisionClock == 0) {
						atomic estimatedBusClock = initBusClock;
						estimatedEdge = estimatedBusClock * 10 / 100;
						deviation = estimatedEdge / 2;
					}

					// retreat to last state
					currentState = SECONDS;
				
				}

				// remember when last signal started
				lastFalling = counter;

			} else {
				// accumulate timer counts
				lastFalling += counter;
			}

			// count number of signals
			frameDetectionRetries++;

			if ( (lastFalling / 60) > estimatedBusClock 
			|| frameDetectionRetries > 60) {
				// PANIC! - too many retries
				if (highPrecisionClock == 0) {
					atomic estimatedBusClock = initBusClock;
					estimatedEdge = estimatedBusClock * 10 / 100;
					deviation = estimatedEdge / 2;
				}

				// retreat to last state
				currentState = SECONDS;

				frameDetectionRetries = 0;
			}
			
		} else if (currentState == BITS) {

			// accumulate counter counts
			countsThisMinute += counter;

			// look for pulse with a width of 100-200ms
			if (edge == 1
				&& counter > (estimatedEdge - deviation) 
				&& counter < (2 * estimatedEdge + deviation) ) {
				
				// approximately 1 sec. has passed
				if (lastFalling > (estimatedBusClock - deviation) 
				&& lastFalling < (estimatedBusClock + deviation) ) {
				
					// decode bit
					dcf77[listenBank][dcfSeconds] = ADC(counter);
					
					// increment seconds
					dcfSeconds++;
					
				// approximately 2 secs. has passed
				} else if (lastFalling > (2 * estimatedBusClock - deviation) 
				&& lastFalling < (2 * estimatedBusClock + deviation) ) {

					// DCF frame detected
					if (dcfSeconds == 59) {
					
						// still in sync 
						if (highPrecisionClock == 0) {
							// estimate new estimatedBusClock
							estimatedBusClock = (countsThisMinute - counter) / 60;
							estimatedEdge = estimatedBusClock * 10 / 100;
							deviation = estimatedEdge / 2;
						}
					
						// counter to be reset by task
						counterBank = counter;
						
						// reset time counters
						dcfSeconds = 0;
					
						// Switch bank
						listenBank = (listenBank == 1) ? 0 : 1;
						decodeBank = (decodeBank == 1) ? 0 : 1;

						// decode DCF frame
						post decodeTask();
					} else {
						// pulse missed - might be able to recover
						// increment missed second
						dcfSeconds++;
					}

					// decode bit
					dcf77[listenBank][dcfSeconds] = ADC(counter);

					// increment seconds
					dcfSeconds++;
										
				} else {
				
					// PANIC! - unexpected signal
					if (highPrecisionClock == 0) {
						estimatedBusClock = initBusClock;
						estimatedEdge = estimatedBusClock * 10 / 100;
						deviation = estimatedEdge / 2;
					}
					
					// retreat to former state
					currentState = SECONDS;
					
					// save counter
					tmpCountsThisMinute = countsThisMinute;

					post outSyncTask();
				
				}

				// remember when last signal started
				lastFalling = counter;

			} else if (edge == 0 
				&& inSync == 1
				&& ((counter < (estimatedBusClock - estimatedEdge + deviation) 
				    && counter > (estimatedBusClock - 2 * estimatedEdge - deviation))
				|| (counter < (2 * estimatedBusClock - estimatedEdge + deviation) 
				    && counter > (2 * estimatedBusClock - 2 * estimatedEdge - deviation))) ) {


				// accumulate timer counts
				lastFalling += counter;

			} else {
				// accumulate timer counts
				lastFalling += counter;
			}

			if (dcfSeconds > 59 
			|| lastFalling > (2 * estimatedBusClock + deviation) ) {
		
				// PANIC! - too long since last signal
				if (highPrecisionClock == 0) {
					estimatedBusClock = initBusClock;
					estimatedEdge = estimatedBusClock * 10 / 100;
					deviation = estimatedEdge / 2;
				}
				
				// retreat to former state
				currentState = SECONDS;

				// save counter
				tmpCountsThisMinute = countsThisMinute;
		
				post outSyncTask();
			}
		}


		return SUCCESS;
		
	}

	/////////////////////////////////////////////////////////////////////////////////
	// DCF77 decoding task
	//
	// Called at end of each frame
	/////////////////////////////////////////////////////////////////////////////////
	task void decodeTask() {
		uint8_t i, parity = 0;
		int8_t error = -1;
		uint8_t minute, hour, day_of_month, day_of_week, month, year;
		uint32_t oldUnixTimestamp, newUnixTimestamp;

		/////////////////////////////////////////////////////
		// Parity check first third
		/////////////////////////////////////////////////////
		for (i = 0; i < 29; i++) {
			if (dcf77[decodeBank][i] != 2) {
				parity ^= dcf77[decodeBank][i]; 

			} else {
				
				// PANIC! - more than one missing bit
				error = -2;
				break;
			}
		}
		
		/////////////////////////////////////////////////////
		// Decode first third if data is consistent
		/////////////////////////////////////////////////////
		if (parity == 1 || error == -2) {

			// PANIC! - error
			atomic dcfDecodedMinutes = 0;

		} else {
			atomic dcfDecodedMinutes = 1;
		}

		/////////////////////////////////////////////////////
		// Parity check second third
		/////////////////////////////////////////////////////
		parity = 0;
		error = -1;
		
		for (i = 29; i < 36; i++) {
			if (dcf77[decodeBank][i] != 2) {
				parity ^= dcf77[decodeBank][i]; 
			
			} else {
				
				// PANIC! - more than one missing bit
				error = -2;
				break;
			}
		}
				
		/////////////////////////////////////////////////////
		// Decode second third if data is consistent
		/////////////////////////////////////////////////////
		if (parity == 1 || error == -2) {

			// PANIC! - error
			atomic dcfDecodedHours = 0;
		} else {
			atomic dcfDecodedHours = 1;
		}
		
		/////////////////////////////////////////////////////
		// Parity check last third
		/////////////////////////////////////////////////////
		parity = 0;
		error = -1;

		for (i = 36; i < 59; i++) {
			if (dcf77[decodeBank][i] != 2) {
				parity ^= dcf77[decodeBank][i]; 
						
			} else {
				
				// PANIC! - more than one missing bit
				error = -2;
				break;
			}
		}
				
		/////////////////////////////////////////////////////
		// Decode last third if data is consistent
		/////////////////////////////////////////////////////
		if (parity == 1 || error == -2) {

			// PANIC! - bit error
			atomic dcfDecodedDate = 0;
		} else {

			atomic dcfDecodedDate = 1;
		}

		
		/////////////////////////////////////////////////////
		// Fill DCF struct
		/////////////////////////////////////////////////////
		atomic inSync = dcfDecodedMinutes & dcfDecodedHours & dcfDecodedDate;


		if (inSync == 1) {

			minute = 1 * dcf77[decodeBank][21] 
			       + 2 * dcf77[decodeBank][22] 
			       + 4 * dcf77[decodeBank][23] 
			       + 8 * dcf77[decodeBank][24] 
			       + 10 * dcf77[decodeBank][25] 
			       + 20 * dcf77[decodeBank][26] 
			       + 40 * dcf77[decodeBank][27];

			hour = 1 * dcf77[decodeBank][29] 
			     + 2 * dcf77[decodeBank][30] 
			     + 4 * dcf77[decodeBank][31] 
			     + 8 * dcf77[decodeBank][32] 
			     + 10 * dcf77[decodeBank][33] 
			     + 20 * dcf77[decodeBank][34];

			day_of_month = 1 * dcf77[decodeBank][36] 
				     + 2 * dcf77[decodeBank][37] 
				     + 4 * dcf77[decodeBank][38] 
				     + 8 * dcf77[decodeBank][39] 
				     + 10 * dcf77[decodeBank][40] 
				     + 20 * dcf77[decodeBank][41];

			day_of_week = 1 * dcf77[decodeBank][42] 
				    + 2 * dcf77[decodeBank][43] 
				    + 4 * dcf77[decodeBank][44];
	  	
	  		month = 1 * dcf77[decodeBank][45] 
			      + 2 * dcf77[decodeBank][46] 
			      + 4 * dcf77[decodeBank][47] 
			      + 8 * dcf77[decodeBank][48] 
		 	      + 10 * dcf77[decodeBank][49];

			year = 1 * dcf77[decodeBank][50] 
			     + 2 * dcf77[decodeBank][51] 
			     + 4 * dcf77[decodeBank][52] 
			     + 8 * dcf77[decodeBank][53] 
			     + 10 * dcf77[decodeBank][54] 
			     + 20 * dcf77[decodeBank][55] 
			     + 40 * dcf77[decodeBank][56]
			     + 80 * dcf77[decodeBank][57];

			// successive synchronization
			if (lastSync == 1) {

				newUnixTimestamp = unixTimestamp(0, 
							minute, 
							hour, 
							day_of_month, 
							month, 
							year);
				
				oldUnixTimestamp = unixTimestamp(0, 
							this.minute, 
							this.hour, 
							this.day_of_month, 
							this.month, 
							this.year);

				// check for timestamp consistency
				if (newUnixTimestamp == (oldUnixTimestamp + 60) ) {

					atomic {
						this.antenna = dcf77[decodeBank][15];
						this.deltaDST = dcf77[decodeBank][16];
						this.DST = dcf77[decodeBank][17];
						this.leap_second = dcf77[decodeBank][18];

						this.minute = minute;
						this.hour = hour;

						this.day_of_month = day_of_month;
						this.day_of_week = day_of_week;

						this.month = month;
						this.year = year;

						countsThisMinute = counterBank;
					}
				
				} else {

					// reset counter
					countsThisMinute = counterBank;
	
					// timestamp inconsistent - out of sync
					atomic inSync = 0;				
				}
			// new synchronization
			} else {
				atomic {
					this.antenna = dcf77[decodeBank][15];
					this.deltaDST = dcf77[decodeBank][16];
					this.DST = dcf77[decodeBank][17];
					this.leap_second = dcf77[decodeBank][18];

					this.minute = minute;
					this.hour = hour;

					this.day_of_month = day_of_month;
					this.day_of_week = day_of_week;

					this.month = month;
					this.year = year;

					countsThisMinute = counterBank;
				}
			}
		} else {

			countsThisMinute = counterBank;
		}

		// reset databank
		for (i = 0; i < 59; i++) {
			dcf77[decodeBank][i] = 2;
		}
		
		// Signal if DCF synchronization status has changed
		if (inSync == 1 && lastSync == 0) {

			call TPMTimer32.start(estimatedBusClock);
			signal DCF77.inSync(estimatedBusClock);
			
		} else if (inSync == 0 && lastSync == 1) {

			this.minute++;
			millisecondsAtLastSync = 0;
			secondsSinceLastSync = 0;

			signal DCF77.outSync();
		}
		
		lastSync = inSync;

		return;
	}

	/////////////////////////////////////////////////////////////////////////////////
	// Signal DCF is out of sync
	/////////////////////////////////////////////////////////////////////////////////
	task void outSyncTask() {
		uint32_t tmp;
	
		
		if (lastSync == 1) {

			millisecondsAtLastSync = calculateMilliseconds(tmpCountsThisMinute);
			secondsSinceLastSync = calculateSeconds(tmpCountsThisMinute);

			signal DCF77.outSync();
		}
		
		atomic {
			inSync = 0;
			lastSync = 0;
		}

		return;
	}

	
	/////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////
	// Internal functions
	/////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////////////////////////////////////
	// ADC
	// classifies signal based on the actual counts and the estimated signal width
	/////////////////////////////////////////////////////////////////////////////////
	uint8_t ADC(uint32_t counter) {
		////////////////////////////////////////////////////////
		// Divide interval between 100ms - 200ms in three parts
		// First : 0
		// Second: 2 (undetermined)
		// Third : 1
		////////////////////////////////////////////////////////
		if ( counter < (estimatedEdge * 4 / 3) ) {

			return 0;
		} else if ( counter > (estimatedEdge * 5 / 3) ) {

			return 1;
		} else {
			return 2;
		}
	}

	/////////////////////////////////////////////////////////////////////////////////
	// calculateMilliseconds
	// 
	/////////////////////////////////////////////////////////////////////////////////
	uint16_t calculateMilliseconds(uint32_t counts) {  
		uint32_t tmp;
		
		tmp = counts % estimatedBusClock;
		tmp = tmp / (estimatedBusClock / 1000);
		tmp = (tmp > 999) ? 999 : tmp; 
		
		return tmp;
	}

	/////////////////////////////////////////////////////////////////////////////////
	// calculateSeconds
	//
	/////////////////////////////////////////////////////////////////////////////////
	uint8_t calculateSeconds(uint32_t counts) {  
		uint32_t tmp;
		
		tmp = counts / estimatedBusClock;
		
		return tmp;
	}

	/////////////////////////////////////////////////////////////////////////////////
	// calculateUnixTimestamp
	//
	/////////////////////////////////////////////////////////////////////////////////
	uint32_t calculateUnixTimestamp() {  
		uint32_t sec, min, hour, dom, month, year, result, tmp;

		////////////////////////////////////////////////////////////////////////	
		// if inSync print dcf-struct timestamp else use timer-seconds
		////////////////////////////////////////////////////////////////////////	
		if (inSync == 1) {
			atomic {
				tmp = call LocalCounter.getInteruptCounter();
				tmp += countsThisMinute;

				sec = calculateSeconds(tmp);
				min = this.minute;
				hour = this.hour;
				dom = this.day_of_month;
				month = this.month;
				year = this.year;
			}
		} else {
			atomic {
				sec = secondsSinceLastSync;
				min = this.minute;
				hour = this.hour;
				dom = this.day_of_month;
				month = this.month;
				year = this.year;
			}
		}

		return unixTimestamp(sec, min, hour, dom, month, year);
	}


	uint32_t unixTimestamp(uint32_t sec, uint32_t min, uint32_t hour, 
				uint32_t dom, uint32_t month, uint32_t year) {  
		uint8_t i;
		uint32_t result, nod;

		////////////////////////////////////////////////////////////////////////	
		// calculate unix timestamp
		////////////////////////////////////////////////////////////////////////	

		uint8_t numberOfDays[12] = {31,28,31,30,31,30,31,31,30,31,30,31};
		// uint32_t baseOffset = 946702800; // unix timestamp @ 01/01/2000 00:00
		uint32_t baseOffset = 946684800; // unix timestamp @ 01/01/2000 00:00

		// seconds since midnight
		result = sec + min*60 + hour*60*60;

		// seconds since beginning of month
		result += (dom-1)*24*60*60;

		// seconds since beginning of year
		for (i = 0; i < month-1; i++) {
			nod = numberOfDays[i];
			result += nod * 24*60*60;
		}

		// extra seconds caused by leap day
		if (month > 2) {
			if (year % 4 == 0) {
				result += 24*60*60;
			}
		}

		// seconds since base offset (01/01/2000 00:00)
		result += year*365*24*60*60;

		// extra seconds caused by leap year
		result += (year / 4 + 1) * 24*60*60;


		return result + baseOffset;
	}
}


