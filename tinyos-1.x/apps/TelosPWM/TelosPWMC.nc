// $Id: TelosPWMC.nc,v 1.4 2005/05/10 05:16:48 johnyb_4 Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Cory Sharp <cssharp@eecs.berkeley.edu>

// revised by John Breneman - 5/9/05 <johnyb_4@berkeley.edu>

configuration TelosPWMC
{
  provides interface StdControl;
  provides interface TelosPWM;
}
implementation
{
  components TelosPWMM
           , MSP430TimerC
	   , MSP430GeneralIOC
	   ;

  StdControl = TelosPWMM;
  TelosPWM = TelosPWMM;

  TelosPWMM.High0Alarm -> MSP430TimerC.CompareB2;
  TelosPWMM.High1Alarm -> MSP430TimerC.CompareB5;
  TelosPWMM.High2Alarm -> MSP430TimerC.CompareB6;
  TelosPWMM.High3Alarm -> MSP430TimerC.CompareB0;
  TelosPWMM.High0AlarmControl -> MSP430TimerC.ControlB2;
  TelosPWMM.High1AlarmControl -> MSP430TimerC.ControlB5;
  TelosPWMM.High2AlarmControl -> MSP430TimerC.ControlB6;
  TelosPWMM.High3AlarmControl -> MSP430TimerC.ControlB0;
  TelosPWMM.PWMPort0 -> MSP430GeneralIOC.Port35;
  TelosPWMM.PWMPort1 -> MSP430GeneralIOC.Port23;
  TelosPWMM.PWMPort2 -> MSP430GeneralIOC.Port26;
  TelosPWMM.PWMPort3 -> MSP430GeneralIOC.Port34;
}

