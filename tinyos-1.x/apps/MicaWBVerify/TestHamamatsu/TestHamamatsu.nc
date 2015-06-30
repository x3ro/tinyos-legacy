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

/* Authors:  Joe Polastre
 * 
 * $Id: TestHamamatsu.nc,v 1.2 2003/10/07 21:44:54 idgay Exp $
 */

configuration TestHamamatsu { 
// this module does not provide any interface
}

implementation
{
  components Main, TestHamamatsuM, GenericComm as Comm, LedsC, Hamamatsu, TimerC;

  Main.StdControl -> TimerC;
  Main.StdControl -> TestHamamatsuM;
  TestHamamatsuM.CommControl->Comm;
  TestHamamatsuM.Send->Comm.SendMsg[14];

  TestHamamatsuM.Leds -> LedsC;

  TestHamamatsuM.ADCControl -> Hamamatsu;
  TestHamamatsuM.Channel1 -> Hamamatsu.ADC[1];
  TestHamamatsuM.Channel2 -> Hamamatsu.ADC[2];

  TestHamamatsuM.Timer -> TimerC.Timer[unique("Timer")];
}

