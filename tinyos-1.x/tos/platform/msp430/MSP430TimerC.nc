//$Id: MSP430TimerC.nc,v 1.4 2004/08/18 01:39:05 jpolastre Exp $

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

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

configuration MSP430TimerC
{
  provides interface MSP430Timer as TimerA;
  provides interface MSP430TimerControl as ControlA0;
  provides interface MSP430TimerControl as ControlA1;
  provides interface MSP430TimerControl as ControlA2;
  provides interface MSP430Compare as CompareA0;
  provides interface MSP430Compare as CompareA1;
  provides interface MSP430Compare as CompareA2;
  provides interface MSP430Capture as CaptureA0;
  provides interface MSP430Capture as CaptureA1;
  provides interface MSP430Capture as CaptureA2;

  provides interface MSP430Timer as TimerB;
  provides interface MSP430TimerControl as ControlB0;
  provides interface MSP430TimerControl as ControlB1;
  provides interface MSP430TimerControl as ControlB2;
  provides interface MSP430TimerControl as ControlB3;
  provides interface MSP430TimerControl as ControlB4;
  provides interface MSP430TimerControl as ControlB5;
  provides interface MSP430TimerControl as ControlB6;
  provides interface MSP430Compare as CompareB0;
  provides interface MSP430Compare as CompareB1;
  provides interface MSP430Compare as CompareB2;
  provides interface MSP430Compare as CompareB3;
  provides interface MSP430Compare as CompareB4;
  provides interface MSP430Compare as CompareB5;
  provides interface MSP430Compare as CompareB6;
  provides interface MSP430Capture as CaptureB0;
  provides interface MSP430Capture as CaptureB1;
  provides interface MSP430Capture as CaptureB2;
  provides interface MSP430Capture as CaptureB3;
  provides interface MSP430Capture as CaptureB4;
  provides interface MSP430Capture as CaptureB5;
  provides interface MSP430Capture as CaptureB6;
}
implementation
{
  components MSP430TimerM;

  TimerA = MSP430TimerM.TimerA;
  ControlA0 = MSP430TimerM.ControlA0;
  ControlA1 = MSP430TimerM.ControlA1;
  ControlA2 = MSP430TimerM.ControlA2;
  CompareA0 = MSP430TimerM.CompareA0;
  CompareA1 = MSP430TimerM.CompareA1;
  CompareA2 = MSP430TimerM.CompareA2;
  CaptureA0 = MSP430TimerM.CaptureA0;
  CaptureA1 = MSP430TimerM.CaptureA1;
  CaptureA2 = MSP430TimerM.CaptureA2;

  TimerB = MSP430TimerM.TimerB;
  ControlB0 = MSP430TimerM.ControlB0;
  ControlB1 = MSP430TimerM.ControlB1;
  ControlB2 = MSP430TimerM.ControlB2;
  ControlB3 = MSP430TimerM.ControlB3;
  ControlB4 = MSP430TimerM.ControlB4;
  ControlB5 = MSP430TimerM.ControlB5;
  ControlB6 = MSP430TimerM.ControlB6;
  CompareB0 = MSP430TimerM.CompareB0;
  CompareB1 = MSP430TimerM.CompareB1;
  CompareB2 = MSP430TimerM.CompareB2;
  CompareB3 = MSP430TimerM.CompareB3;
  CompareB4 = MSP430TimerM.CompareB4;
  CompareB5 = MSP430TimerM.CompareB5;
  CompareB6 = MSP430TimerM.CompareB6;
  CaptureB0 = MSP430TimerM.CaptureB0;
  CaptureB1 = MSP430TimerM.CaptureB1;
  CaptureB2 = MSP430TimerM.CaptureB2;
  CaptureB3 = MSP430TimerM.CaptureB3;
  CaptureB4 = MSP430TimerM.CaptureB4;
  CaptureB5 = MSP430TimerM.CaptureB5;
  CaptureB6 = MSP430TimerM.CaptureB6;
}

