//$Id: GlowRadioC.nc,v 1.3 2005/07/29 22:37:49 jpolastre Exp $

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

configuration GlowRadioC
{
}
implementation
{
  components Main, GlowRadioM, LedsIntensityC, TimerC, GenericComm;

  Main.StdControl -> GlowRadioM;
  Main.StdControl -> LedsIntensityC;
  Main.StdControl -> TimerC;
  Main.StdControl -> GenericComm;

  GlowRadioM.LedsIntensity -> LedsIntensityC;
  GlowRadioM.Timer -> TimerC.Timer[unique("Timer")];
  GlowRadioM.SendMsg -> GenericComm.SendMsg[5];
  GlowRadioM.ReceiveMsg -> GenericComm.ReceiveMsg[5];
}

