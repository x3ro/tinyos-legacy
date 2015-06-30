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
 * $Id: TestSnooze.td,v 1.5 2002/08/05 21:25:51 scipio Exp $
 *
 * IMPORTANT!!!!!!!!!!!!
 * NOTE: The Snooze component will ONLY work on the Mica platform with
 * nodes that have the diode bypass to the battery.  If you do not know what
 * this is, check www.cs.berkeley.edu/~polastre/nest/diode.html
 * That page also has information for how to install the diode.
 *
 */

configuration TestSnooze {
}
implementation {
  components Main, TestSnoozeM, ClockC, LedsC, SnoozeC;

  Main.StdControl -> TestSnoozeM.StdControl;
  TestSnoozeM.Clock -> ClockC;
  TestSnoozeM.Leds -> LedsC;
  TestSnoozeM.Snooze -> SnoozeC;
}
