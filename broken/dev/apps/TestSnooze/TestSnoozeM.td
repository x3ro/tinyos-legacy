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
 *
 * Authors:             Joe Polastre
 * 
 * $Id: TestSnoozeM.td,v 1.5 2002/08/05 21:25:51 scipio Exp $
 *
 * IMPORTANT!!!!!!!!!!!!
 * NOTE: The Snooze component will ONLY work on the Mica platform with
 * nodes that have the diode bypass to the battery.  If you do not know what
 * this is, check www.cs.berkeley.edu/~polastre/nest/diode.html
 * That page also has information for how to install the diode.
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

  char count;

  void processing()
  {
     call Leds.redOn();
  }

  void sleep()
  {
    call Snooze.snooze(32*4);
  }

  event result_t Snooze.wakeup() {
    count = 0;
    processing();
    return SUCCESS;
  }

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    count = 0;
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
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Clock.fire()
  {
    count++;
    call Leds.greenToggle();
    if (count == 3)
    {
      count = 0;
      sleep();
    }
    return SUCCESS;
  }
}

