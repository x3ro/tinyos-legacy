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



