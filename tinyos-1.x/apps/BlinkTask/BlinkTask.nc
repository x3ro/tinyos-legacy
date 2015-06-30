// $Id: BlinkTask.nc,v 1.4 2003/10/07 21:44:45 idgay Exp $

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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* Authors:  SU Ping  <sping@intel-research.net>
 *           Intel Research Berkeley Lab
 *
 */

/**
 * BlinkTask is a basic application that toggles the leds on the mote
 * one every timer firing. 
 *
 * The difference between Blink and BlinkTask is how the Timer.fired()
 * event is handled.  BlinkTask offloads processing to a task which
 * controls the LEDs.  Blink controls the LEDs directly in the event
 * handler, not returning from the event until the LEDs have been
 * toggled.  The timer fires at 1Hz.  The initialization of the Timer
 * can be seen in the Blink initialization function,
 * StdControl.start().
 * 
 * See also: apps/Blink
 *
 * @author tinyos-help@millennium.berkeley.edu
 *
 * @author SU Ping <sping@intel-research.net>
 * @author Intel Research Berkeley Lab
 **/
configuration BlinkTask {
}
implementation {
  components Main, BlinkTaskM, SingleTimer, LedsC;

  Main.StdControl -> BlinkTaskM.StdControl;
  Main.StdControl -> SingleTimer;
  
  BlinkTaskM.Timer -> SingleTimer;
  BlinkTaskM.Leds -> LedsC;
}
