/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
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
 */
// $Id: TimeStampClockC.nc,v 1.1.1.1 2004/10/15 01:34:08 phoebusc Exp $
/**
 * Builds on top of the Timer interface to provide a rudimentary
 * counter/clock for time stamping. The difference with traditional
 * clocks is that this clock fires an event when it is halfway through
 * it's lifecycle (counter is halfway to wrapping around because of
 * overflow) so that the user of this module can write "management
 * code" triggered by the event to update the timestamps derived from
 * this counter.
 * 
 * @author Phoebus Chen
 * @modified 9/13/2004 First Implementation
 */



configuration TimeStampClockC {
  provides {
    interface StdControl;
    interface TimeStamp;
    interface ConfigTimeStamp;
  }
}

implementation {
  components TimeStampClockM, TimerC;

  StdControl = TimeStampClockM;
  TimeStamp = TimeStampClockM;
  ConfigTimeStamp = TimeStampClockM;

  TimeStampClockM.Timer -> TimerC.Timer[unique("Timer")];
  TimeStampClockM.TimerControl -> TimerC;
}
