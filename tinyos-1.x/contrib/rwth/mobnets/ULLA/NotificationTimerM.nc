/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
/**
 *
 * Notification Timer - 
 <p>
 <p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
 
#define    MAX_RN_TABLE    10

includes UllaQuery;

module NotificationTimerM {
  provides {
    interface StdControl as RNControl;
    interface RNTimer;
  }
	
	uses {
	  interface Timer as PeriodicTimer;
	  interface Timer as EventTimer;
		interface UqpIf; 
	}
}

implementation {

  typedef struct RNTable {
    uint8_t active;
		uint8_t rnId;
		uint16_t max_count;
		uint16_t counter;
		uint16_t gcdCnt;
		uint32_t interval;
  } RNTable, *RNTablePtr;
	
	RNTable rnBuffer[MAX_RN_TABLE];
	//RNTablePtr rnBufferPtr;
	
	uint32_t gcdAll;
	uint32_t gcdOld;
	
	Query testQuery;
  
	bool hasManyRN();
	uint32_t gcd(uint32_t m, uint32_t n);
	void CalculateGCD();
	void ResetRNTimer();
	uint8_t ActiveBuffer(uint16_t count, uint32_t interval);
	
	command result_t RNControl.init() {
	  atomic {
			gcdAll = 0;
			gcdOld = 0;
		}
		return SUCCESS;
	}
	
	command result_t RNControl.start() {
		return SUCCESS;
	}
	
	command result_t RNControl.stop() {
		return SUCCESS;
	}
	
	event result_t UqpIf.requestInfoDone(ResultTuple *result, uint8_t numBytes) {
    return SUCCESS;
  }
	
	event result_t EventTimer.fired() {
		
		uint8_t i;
		
		if (!hasManyRN()) call EventTimer.stop();
		
		for (i=0; i<MAX_RN_TABLE; i++) {
			if (rnBuffer[i].active) {
			
			  atomic rnBuffer[i].gcdCnt--;
				if (rnBuffer[i].gcdCnt == 0) {
				  atomic rnBuffer[i].counter++;
					dbg(DBG_USR1, "counter%d = %d max_counter = %d\n",i, rnBuffer[i].counter, rnBuffer[i].max_count);
					signal RNTimer.fired(rnBuffer[i].rnId);
					call UqpIf.requestInfo(&testQuery, &i);
					
					if (rnBuffer[i].counter == rnBuffer[i].max_count) {
						
						// FIXME: remove this RN from the table without changing (again) GCD (to make this simple we only 
						// change when there is a new RN) 	
						//call PeriodicTimer.stop();
						rnBuffer[i].active = 0; // disable this column
						memset(&rnBuffer[i], 0, sizeof(RNTable));
						signal RNTimer.stop(rnBuffer[i].rnId);
						dbg(DBG_USR1, "RNTimer.stop\n");
					}
			
					// Reset gcdCnt
					atomic {
						rnBuffer[i].gcdCnt = rnBuffer[i].interval / gcdAll;
					}
					dbg(DBG_USR1, "RNTimer.fired gcdCnt%d = %d\n",i, rnBuffer[i].gcdCnt);
				}
			}
		}
		return SUCCESS;
	}
	
	event result_t PeriodicTimer.fired() {
	  
		uint8_t i;
		//dbg(DBG_USR1, "NotificationTimer: PeriodicTimer.fired\n");
		
		// if 
		if (!hasManyRN()) call PeriodicTimer.stop();
		
		for (i=0; i<MAX_RN_TABLE; i++) {
			if (rnBuffer[i].active) {
			
			  atomic rnBuffer[i].gcdCnt--;
				if (rnBuffer[i].gcdCnt == 0) {
				  atomic rnBuffer[i].counter++;
					dbg(DBG_USR1, "counter%d = %d max_counter = %d\n",i, rnBuffer[i].counter, rnBuffer[i].max_count);
					signal RNTimer.fired(rnBuffer[i].rnId);
					call UqpIf.requestInfo(&testQuery, &i);
					
					if (rnBuffer[i].counter == rnBuffer[i].max_count) {
						
						// FIXME: remove this RN from the table without changing (again) GCD (to make this simple we only 
						// change when there is a new RN) 	
						//call PeriodicTimer.stop();
						rnBuffer[i].active = 0; // disable this column
						memset(&rnBuffer[i], 0, sizeof(RNTable));
						signal RNTimer.stop(rnBuffer[i].rnId);
						dbg(DBG_USR1, "RNTimer.stop\n");
					}
			
					// Reset gcdCnt
					atomic {
						rnBuffer[i].gcdCnt = rnBuffer[i].interval / gcdAll;
					}
					dbg(DBG_USR1, "RNTimer.fired gcdCnt%d = %d\n",i, rnBuffer[i].gcdCnt);
				}
			}
		}

		return SUCCESS;
	}
	
	command result_t RNTimer.startPeriodic(RnId_t rnId, uint16_t count, uint16_t interval, QueryPtr pCurQuery) {
		// FIXME: introduce a way to handle rnId here
		// FIXME: check if there are more than one notification requests. If so, GCD must be calculated and 
		// the Timer will stop and start with a new time interval.
		
		uint8_t activeRN;
		
		memcpy(&testQuery, pCurQuery, sizeof(Query));
		
		if (hasManyRN()) {
				dbg(DBG_USR1, "RNTimer: hasManyRN %d %d rnId %d\n",count,interval, rnId);
				dbg(DBG_USR1, "RNTimer: Calculate GCD\n");
				activeRN = ActiveBuffer(count, interval);
				dbg(DBG_USR1, "Buffer is actived\n");
				CalculateGCD();
				rnBuffer[activeRN].gcdCnt = rnBuffer[activeRN].interval / gcdAll;
				rnBuffer[activeRN].rnId = rnId;
				
				
				if (activeRN >= 2) {
					ResetRNTimer();
				}
		}
		else { // only one RN
		  dbg(DBG_USR1, "RNTimer: has only one RN with count %d interval %d\n",count,interval);
			atomic {
				rnBuffer[0].max_count = count;
				rnBuffer[0].interval = interval;
				rnBuffer[0].active = 1;
				rnBuffer[0].gcdCnt = count;
				rnBuffer[0].rnId = rnId;
				gcdAll = interval;
			}
			dbg(DBG_USR1, "GCD = %d\n",gcd(10,gcd(20,50)));
			call PeriodicTimer.start(TIMER_REPEAT, interval);
		}
		
		return SUCCESS;
	}
	
	command result_t RNTimer.startEvent(RnId_t rnId, uint16_t count, uint16_t fixedInterval, QueryPtr pCurQuery){
		uint8_t activeRN;
		
		memcpy(&testQuery, pCurQuery, sizeof(Query));
		
		if (hasManyRN()) {
				dbg(DBG_USR1, "RNTimer: hasManyRN %d %d rnId %d\n",count,interval, rnId);
				dbg(DBG_USR1, "RNTimer: Calculate GCD\n");
				activeRN = ActiveBuffer(count, fixedInterval);
				dbg(DBG_USR1, "Buffer is actived\n");
				CalculateGCD();
				rnBuffer[activeRN].gcdCnt = rnBuffer[activeRN].interval / gcdAll;
				rnBuffer[activeRN].rnId = rnId;
				
				if (activeRN >= 2) {
					ResetRNTimer();
				}
		}
		else { // only one RN
		  dbg(DBG_USR1, "RNTimer: has only one RN with count %d interval %d\n",count,interval);
			atomic {
				rnBuffer[0].max_count = count;
				rnBuffer[0].interval = fixedInterval;
				rnBuffer[0].active = 1;
				rnBuffer[0].gcdCnt = count;
				rnBuffer[0].rnId = rnId;
				gcdAll = fixedInterval;
			}
			dbg(DBG_USR1, "GCD = %d\n",gcd(10,gcd(20,50)));
			call EventTimer.start(TIMER_REPEAT, fixedInterval);
		}
		
	
		return SUCCESS;
	}
	
		
	bool hasManyRN() {
		/*
		 * Check if there are more than one RNs. 
		 */
		uint8_t i, hit=0;
		
		for (i=0; i<MAX_RN_TABLE; i++) {
			if (rnBuffer[i].active == 1) {
			 hit++;
			}
		}
		if (hit > 0) return TRUE;
		
    return FALSE;
	}
	
	uint8_t ActiveBuffer(uint16_t count, uint32_t interval) {
		uint8_t i;
		
		dbg(DBG_USR1, "ActiveBuffer count %d  interval %d\n",count, interval);
		for (i=0; i<MAX_RN_TABLE; i++) {
			if (rnBuffer[i].active == 0) {
			  rnBuffer[i].max_count = count;
				rnBuffer[i].interval = interval;
				rnBuffer[i].active = 1;
				dbg(DBG_USR1, "Buffer has a free slot %d\n", i);
			  break;
			}
		}
		
		return i;
	}
	
	/*
	 * This is used when more RN is registered (can't directly use this if RN is removed)
	 */
	void ResetRNTimer() {
	
	  /*
		 *  1. Recalculate gcdCnt
		 *  2. Restart the RNTimer
		 */
		 
		uint8_t i; 
		
		for (i=0; i<MAX_RN_TABLE; i++) {
			if (rnBuffer[i].active) {
			  dbg(DBG_USR1, "new gcdCnt111 = %d   GCD old=%d  new=%d\n", rnBuffer[i].gcdCnt, gcdOld, gcdAll);
			  rnBuffer[i].gcdCnt *= (gcdOld / gcdAll);
				dbg(DBG_USR1, "new gcdCnt = %d   GCD old=%d  new=%d\n", rnBuffer[i].gcdCnt, gcdOld, gcdAll);
			}
		}
		
		dbg(DBG_USR1, "Restart RNTimer with a new GCD %d\n",gcdAll);
		call PeriodicTimer.stop();
		call PeriodicTimer.start(TIMER_REPEAT, gcdAll);
	}
	
	void CalculateGCD() {
		uint8_t i;
		uint32_t gcd_temp;
		
		atomic gcd_temp = rnBuffer[0].interval;
		
		gcdOld = gcdAll;
		
		for (i=0; i<MAX_RN_TABLE; i++) {
		 	if (rnBuffer[i].active) {
				gcd_temp = gcd(gcd_temp, rnBuffer[i].interval);
			}
		}
		
		atomic {
			gcdAll = gcd_temp;
		}
	  dbg(DBG_USR1, "GCD = %d\n", gcdAll);
	}
	
	uint32_t gcd(uint32_t m, uint32_t n) {

		uint32_t t, r;
	
		if (m < n) {
			t = m;
			m = n;
			n = t;
		}
	
		r = m % n;
	
		if (r == 0) {
			return n;
		} else {
			return gcd(n, r);
		}

}
}
