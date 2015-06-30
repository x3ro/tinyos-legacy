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

/**
 * This interface provides a generic wakeup service that generates
 * events at specified times or after specified delays.
 */
includes Alarm;

interface Alarm 
{
  /**
   * Schedule a wakeup at a specified Alarm time (where Alarm time
   * is approximately the number of seconds since the Alarm component
   * was first started using StdControl.start).
   * @param indx A user-defined index, handy for bookkeeping in
   *             your application, so when a wakeup fires, you can
   *             easily see which scheduled wakeup this one is. 
   * @param wake_time Specifies the Alarm time for the wakeup.  If
   *             multiple wakeups are scheduled for the same time,
   *             then Alarm will try to fire them at about the same
   *             time (sequentially, by waiting a tenth of a second
   *		 between the duplicates).  If you are crazy enough
   *		 to schedule a wakeup for the "past", ie a value less
   *		 than the current Alarm time, that will work.  The
   *		 wakeups are processed in order, from earliest up to
   *		 the current time. 
   * @return Returns SUCCESS if the alarm could be scheduled.  But
   *             the implementation uses a finite table (see Alarm.h 
   *		 for sched_list_size), and if the table is full, then
   *	         schedule Returns FAIL.
   * @author herman@cs.uiowa.edu
   */
  command result_t schedule (uint8_t indx, uint32_t wake_time);

  /**
   * Schedule a wakeup for a specified delay, in seconds, following the
   * current Alarm time (where Alarm time is approximately the number 
   * of seconds since the Alarm component was first started using 
   * StdControl.start).
   * @param indx A user-defined index, handy for bookkeeping in
   *             your application, so when a wakeup fires, you can
   *             easily see which scheduled wakeup this one is. 
   * @param delay_time Specifies the delay for the wakeup.  If
   *             multiple wakeups are scheduled for the same time,
   *             then Alarm will try to fire them at about the same
   *             time (sequentially, by waiting a tenth of a second
   *		 between the duplicates).  
   * @return Returns SUCCESS if the alarm could be scheduled.  But
   *             the implementation uses a finite table (see Alarm.h 
   *		 for sched_list_size), and if the table is full, then
   *	         schedule Returns FAIL.
   * @author herman@cs.uiowa.edu
   */
  command result_t set (uint8_t indx, uint16_t delay_time);

  /**
   * Clear all scheduled wakeups.  Mainly intended for a failure/restart
   * purpose, this is a less drastic measure than "StdControl.stop(); 
   * StdControl.start()".  Why?  Because only the wakeups associated
   * with the id of the calling component are cleared (keep in mind that
   * the Alarm interface is parametrized). 
   * @return Returns SUCCESS.
   * @author herman@cs.uiowa.edu
   */
  command result_t clear();

  /**
   * Read the current Alarm time, where Alarm time is approximately 
   * the number of seconds since the Alarm component was first started using 
   * StdControl.start).
   * @return Returns alarm time.
   * @author herman@cs.uiowa.edu
   */
  command uint32_t clock();

  /**
   * Wakeup event.  It is signalled by Alarm to notify the application
   * of a previously scheduled alarm.  It provides the application the
   * user-defined index of the wakeup.
   * @see  Alarm.set and Alarm.schedule
   * @param indx A user-defined index, handy for bookkeeping in
   *             your application, so when a wakeup fires, you can
   *             easily see which scheduled wakeup this one is. 
   * @param wake_time This is the Alarm time at the instant of signalling, 
   *             which could actually be later than the scheduled time.
   * @return Return SUCCESS or FAIL, as appropriate.
   * @author herman@cs.uiowa.edu
   */
  event result_t wakeup (uint8_t indx, uint32_t wake_time);

}



