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
 * $Id: TestSnooze.nc,v 1.4 2003/10/07 21:45:23 idgay Exp $
 *
 * IMPORTANT!!!!!!!!!!!!
 * NOTE: The Snooze component will ONLY work on the Mica platform with
 * nodes that have the diode bypass to the battery.  If you do not know what
 * this is, check http://webs.cs.berkeley.edu/tos/hardware/diode_html.html
 * That page also has information for how to install the diode.
 *
 */

/**
 * TestSnooze is a basic application that illustrates the use of
 * the Snooze component to put the mote into a low power state
 * for a user-defined period.  The mote will be on, wait for
 * three Clock.fire() events, and then enter the low power state.
 * The soft state (variables, etc) of the application are preserved
 * in SRAM on the microprocessor.  One can notice the internal
 * private sleep() function causes the mote to sleep for 
 * 4 seconds.
 * <p>
 * Requirements:
 * <p>
 * Motes must be physically modified in order to Snooze.  Information
 * about the modification is available at:
 * <a href="http://webs.cs.berkeley.edu/tos/hardware/diode_html.html">
 * http://webs.cs.berkeley.edu/tos/hardware/diode_html.html</a>
 * <p>
 * Platforms:
 * <p>
 * This application will only work on the Mica and Mica128 platforms.
 *
 * @author Joe Polastre
 **/
configuration TestSnooze {
}
implementation {
  components Main, TestSnoozeM, ClockC, LedsC, SnoozeC;

  Main.StdControl -> TestSnoozeM.StdControl;
  TestSnoozeM.Clock -> ClockC;
  TestSnoozeM.Leds -> LedsC;
  TestSnoozeM.Snooze -> SnoozeC;
}
