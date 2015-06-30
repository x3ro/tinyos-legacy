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

interface LocalTime
{
  /**
   * Read current clock.
   * @return Returns the number of ticks on the clock.  Each tick 
   *		 represents 1/32768-th of one second.  That being said,
   *		 the actual precision of the clock is dependent on 
   *		 the granularity of the interval and scale of the 
   *		 Clock.setRate(*,*) that specifies the implied precision
   *		 of the hardware counter keeping time.  Although 32K is
   *		 acheivable, most of the Clock.setRate parameters have
   *		 much lower precision, using 4K or fewer counts per
   *		 second.  However, in all cases, we use the uniform
   *		 units based on 32K. 
   * @author herman@cs.uiowa.edu
   */
  command uint32_t read();

  /**
   * Translates System (CPU) time to clock time.
   * @param time The system time as returned by <code>RadioTiming</code>,
   *		or the <code>time</code> of a <code>TOS_Msg</code>.
   * @return The corresponding local time.
   * @author miklos.maroti@vanderbilt.edu
   */
  command uint32_t systemToLocalTime(uint16_t systemTime);

/**
   * Set clock.
   * @param newClock Assigns the specified value to the clock.  Use this
   *		 to initialize the clock or to adjust it.  Note:  please 
   *		 call this before starting Timer or Alarm components.  
   *		 See readClock.read() for an explanation of clock units.
   * @return Always returns SUCCESS
   * @author herman@cs.uiowa.edu
   */
  command result_t set(uint32_t newClock);

  /**
   * Adjust clock.
   * @param adjustment Increases or decreases the clock by the specified value.
   *		 Note: Setting the clock is not that percise and fast than 
   *		 adjusting it.
   * @return Always returns SUCCESS
   * @author miklos.maroti@vanderbilt.edu
   */
  command result_t adjust(int32_t delta);

}
