/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/* Authors:             Joe Polastre
 * 
 * $Id: TestSnoozeM.nc,v 1.5 2003/10/07 21:45:23 idgay Exp $
 *
 * IMPORTANT!!!!!!!!!!!!
 * NOTE: The Snooze component will ONLY work on the Mica platform with
 * nodes that have the diode bypass to the battery.  If you do not know what
 * this is, check http://webs.cs.berkeley.edu/tos/hardware/diode_html.html
 * That page also has information for how to install the diode.
 */

/**
 * Implementation of the TestSnooze application
 * @author Joe Polastre
 */
module TestSnoozeM {
  provides {
    interface StdControl;
  }
  uses {
    interface Clock;
    interface Leds;
    interface Snooze;
  }
}
implementation {

  /**
   * Keeps track of how many clock events have fired
   **/
  char count;

  /**
   * When the mote awakens, it must perform functions to begin processing again
   **/
  void processing()
  {
     call Leds.redOn();
  }

  /**
   * Invokes the Snooze.snooze() command to put the mote to sleep
   **/
  void sleep()
  {
    call Snooze.snooze(32*4);
  }

  /**
   * Event handled when the Snooze component triggers the application
   * that it has woken up
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  async event result_t Snooze.wakeup() {
    atomic count = 0;
    processing();
    return SUCCESS;
  }

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    atomic count = 0;
    call Leds.init();
    processing();
    return SUCCESS;
  }


  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    return call Clock.setRate(TOS_I1PS, TOS_S1PS);
  }

  command result_t StdControl.stop() {
    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
  }

  /**
   * Toggle the red LED in response to the <code>Clock.fire</code> event.  
   * After 3 clock events, go to sleep.
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  async event result_t Clock.fire() {
    char mycount;

    call Leds.greenToggle();

    atomic
      {
	mycount = ++count;
	if (mycount == 3)
	  count = 0;
      }
    if (mycount == 3)
      sleep();
    return SUCCESS;
  }
}

