/*
 * Copyright Ted Herman, 2003, All Rights Reserved.
 * To the user: Ted Herman does not and cannot warrant the
 * product, information, documentation, or software (including
 * any fixes and updates) included in this package or the
 * performance or results obtained by using this product,
 * information, documentation, or software. This product,
 * information, documentation, and software is provided
 * "as is". Ted Herman makes no warranties of any kind,
 * either express or implied, including but not limited to,
 * non infringement of third party rights, merchantability,
 * or fitness for a particular purpose with respect to the
 * product and the accompanying written materials. To the
 * extent you use or implement this product, information,
 * documentation, or software in your own setting, you do so
 * at your own risk. In no event will Ted Herman be liable
 * to you for any damages arising from your use or, your
 * inability to use this product, information, documentation,
 * or software, including any lost profits, lost savings,
 * or other incidental or consequential damages, even if
 * Ted Herman has been advised of the possibility of such
 * damages, or for any claim by another party. All product
 * names are trademarks or registered trademarks of their
 * respective holders. Any resemblance to real persons, living
 * or dead is purely coincidental. Contains no peanuts. Void
 * where prohibited. Batteries not included. Contents may
 * settle during shipment. Use only as directed. No other
 * warranty expressed or implied. Do not use while operating a
 * motor vehicle or heavy equipment. This is not an offer to
 * sell securities. Apply only to affected area. May be too
 * intense for some viewers. Do not stamp. Use other side
 * for additional listings. For recreational use only. Do
 * not disturb. All models over 18 years of age. If condition
 * persists, consult your physician. No user-serviceable parts
 * inside. Freshest if eaten before date on carton. Subject
 * to change without notice. Times approximate. Simulated
 * picture. Children under 12 must wear a helmet. May cause
 * oily discharge. Contents under pressure. Pay before pumping
 * after dark. Paba free. Please remain seated until the ride
 * has come to a complete stop. Breaking seal constitutes
 * acceptance of agreement. For off-road use only. As seen on
 * TV. One size fits all. Many suitcases look alike. Contains
 * a substantial amount of non-tobacco ingredients. Colors
 * may, in time, fade. Slippery when wet. Not affiliated with
 * the American Red Cross. Drop in any mailbox. Edited for
 * television. Keep cool; process promptly. Post office will
 * not deliver without postage. List was current at time of
 * printing. Not responsible for direct, indirect, incidental
 * or consequential damages resulting from any defect,
 * error or failure to perform. At participating locations
 * only. Not the Beatles. See label for sequence. Substantial
 * penalty for early withdrawal. Do not write below this
 * line. Falling rock. Lost ticket pays maximum rate. Your
 * canceled check is your receipt. Add toner. Avoid
 * contact with skin. Sanitized for your protection. Be
 * sure each item is properly endorsed. Sign here without
 * admitting guilt. Employees and their families are not
 * eligible. Beware of dog. Contestants have been briefed
 * on some questions before the show. You must be present
 * to win. No passes accepted for this engagement. Shading
 * within a garment may occur. Use only in a well-ventilated
 * area. Keep away from fire or flames. Replace with same
 * type. Approved for veterans. Booths for two or more. Check
 * if tax deductible. Some equipment shown is optional. No
 * Canadian coins. Not recommended for children. Prerecorded
 * for this time zone. Reproduction strictly prohibited. No
 * solicitors. No alcohol, dogs or horses. No anchovies
 * unless otherwise specified. Restaurant package, not for
 * resale. List at least two alternate dates. First pull up,
 * then pull down. Call before digging. Driver does not carry
 * cash. Some of the trademarks mentioned in this product
 * appear for identification purposes only. Objects in
 * mirror may be closer than they appear. Record additional
 * transactions on back of previous stub. Do not fold,
 * spindle or mutilate. No transfers issued until the bus
 * comes to a complete stop. Package sold by weight, not
 * volume. Your mileage may vary. Parental discretion is
 * advised. Warranty void if this seal is broken. Employees
 * do not know combination to safe. Do not expose to rain
 * or moisture. To prevent fire hazard, do not exceed listed
 * wattage. Do not use with any other power source. May cause
 * radio and television interference. Consult your doctor
 * before starting this, or any other program. Drain fully
 * before recharging.
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
    interface Leds;
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

     //call Leds.redToggle();

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
