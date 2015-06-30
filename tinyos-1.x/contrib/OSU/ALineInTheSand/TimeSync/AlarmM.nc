/**
 * Copyright (c) 2003 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Ted Herman (herman@cs.uiowa.edu)
 *
 */

includes Alarm;

module AlarmM 
{
  provides { 
    interface Alarm[uint8_t id];
    interface StdControl;
    }
  uses {
    interface Timer;
    interface StdControl as TimerControl;
    }
}

implementation

{
  uint32_t nextCheck;
  uint32_t theClock;
  uint16_t subClock;
  sched_list schedList[sched_list_size];
  bool lockAlarm;
  bool reqLock;

  void reNext() {
     uint32_t smallTime = 0xffffffff;
     uint8_t i;
     for (i=0; i<sched_list_size; i++) 
        if ((schedList+i)->wake_time < smallTime) 
        	smallTime = (schedList+i)->wake_time;  
     nextCheck = smallTime;
     }

  /**
   * Initializes the Alarm and Timer components.
   * @author herman@cs.uiowa.edu
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.init() {
     uint8_t i;
     for(i=0;i<sched_list_size;i++) 
       (schedList+i)->wake_time = 0xffffffff; 
     nextCheck = 0xffffffff;
     theClock = 0;
     subClock = 0;
     lockAlarm = reqLock = FALSE;
     call TimerControl.init();
     return SUCCESS;
     }

  /**
   * (Re)-Starts the Alarm and Timer components;
   * also kicks off the Timer with one second wait.
   * @author herman@cs.uiowa.edu
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.start() {
     call TimerControl.start();
     // set INTER_RATE to 1000 for low overhead of interrupt processing
     // set INTER_RATE to 2    for highest possible accuracy of components
     //                        such as Tsync that rely on Timer/Clock 
     //			       granularity
     call Timer.start( TIMER_REPEAT, INTER_RATE ); 
     return SUCCESS;
     }

  /**
   * Stops and reinitializes the Alarm; stops the Timer.
   * @author herman@cs.uiowa.edu
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.stop() {
     uint8_t i;
     for (i=0; i<sched_list_size; i++) 
   	(schedList+i)->wake_time = 0xffffffff;
     call Timer.stop(); 
     call TimerControl.stop();
     return SUCCESS;
     }

  /**
   * Clears out the list of Alarm events (intended mainly
   * for failure/reset).
   * @author herman@cs.uiowa.edu
   * @return Always returns SUCCESS.
   */
  command result_t Alarm.clear[uint8_t id]() {
     uint8_t i;
     lockAlarm = TRUE;
     while (reqLock) {};  // yes, spin-lock makes no 
     			  // sense in TinyOS, but at 
			  // least this is safe
     for (i=0; i<sched_list_size; i++)  
        if ((schedList+i)->wake_time != 0xffffffff &&
	    (schedList+i)->id == id)
   	    (schedList+i)->wake_time = 0xffffffff;
     lockAlarm = FALSE;
     return SUCCESS;
     }

  /**
   * Reads the current Alarm "clock" (seconds since initialized). 
   * @author herman@cs.uiowa.edu
   * @return Always returns current Alarm time (in seconds) 
   */
  command uint32_t Alarm.clock[uint8_t id]() {
     return theClock;
     }

  /**
   * Subroutine: sets the Alarm to fire at a specified Alarm time. 
   * @author herman@cs.uiowa.edu
   * @return Returns SUCCESS if alarm scheduled, otherwise FAIL 
   */
  result_t setAlarm ( uint8_t id, uint8_t indx, uint32_t wake_time) {
     uint8_t i;
     reqLock = TRUE;
     if (lockAlarm) { reqLock = FALSE; return FAIL; }
     for (i=0; i<sched_list_size; i++) 
       if ((schedList+i)->wake_time == 0xffffffff) {
          (schedList+i)->wake_time = wake_time;
	  (schedList+i)->indx = indx;
	  (schedList+i)->id = id;
	  reNext();
	  reqLock = FALSE;
	  return SUCCESS;
          }
     reqLock = FALSE;
     return FAIL;  // did not find empty slot
     }

  /**
   * Sets the Alarm to fire at a specified Alarm time. 
   * @author herman@cs.uiowa.edu
   * @return Returns SUCCESS if alarm scheduled, otherwise FAIL 
   */
  command result_t Alarm.schedule[uint8_t id] ( uint8_t indx, 
     uint32_t wake_time) {
     return setAlarm(id,indx,wake_time);
     }

  /**
   * Sets the Alarm to fire at a specified delay with respect 
   * to the current Alarm time (ie seconds since initialization). 
   * @author herman@cs.uiowa.edu
   * @return Returns SUCCESS if alarm scheduled, otherwise FAIL 
   */
  command result_t Alarm.set[uint8_t id] ( uint8_t indx, 
     uint16_t delay_time) {
     return setAlarm(id,indx,(theClock+delay_time));
     }

  default event result_t Alarm.wakeup[uint8_t id](uint8_t indx,
     uint32_t wake_time) {
     return SUCCESS;
     }

  /**
   * Periodic firing of Timer so Alarm can check for scheduled
   * events (mostly done once per second, unless Alarm gets behind
   * in its scheduling -- then it fires more often).  This event
   * signals possibly one scheduled Alarm.wakeup event, and also
   * calls Timer.start for the next firing. 
   * @author herman@cs.uiowa.edu
   * @return Always returns SUCCESS.
   */
  event result_t Timer.fired() {
     uint8_t i, id, indx;

     // return ASAP if firing rate is more frequent than
     // once per second;  this is tunable in Alarm.h
     if (INTER_RATE < 1000) {
        subClock += INTER_RATE;  // add # milliseconds
        if (subClock < 1000) return SUCCESS;
        subClock = 0;
	}

//     dbg(DBG_USR1, "*** Alarm wakeup by Timer @ %d ***\n",theClock);

     id = 255;
     indx = 255;

     if (++theClock < nextCheck) return SUCCESS; 

     // find all candidates to signal
     for (i=0; i<sched_list_size; i++) 
       if ((schedList+i)->wake_time != 0xffffffff &&
           (schedList+i)->wake_time <= theClock) {
	       (schedList+i)->wake_time = 0xffffffff;
	       id = (schedList+i)->id;
	       indx = (schedList+i)->indx;
	       signal Alarm.wakeup[id](indx,theClock);
               }
     reNext();
     return SUCCESS;
     }

}
