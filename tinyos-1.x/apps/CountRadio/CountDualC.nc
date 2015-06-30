// $Id: CountDualC.nc,v 1.3 2005/09/15 00:37:10 jpolastre Exp $

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

// CountDual:
//   If the mote id is 1, count to the leds and send it over the radio.
//   Otherwise, receive the count from the radio and display it on the leds.

includes CountMsg;

configuration CountDualC
{
}
implementation
{
  components Main
           , CountDualM
	   , TimerC
	   , GenericComm
	   , LedsC
	   ;
  
  Main.StdControl -> CountDualM;
  Main.StdControl -> GenericComm;
  Main.StdControl -> TimerC;

  CountDualM.Timer -> TimerC.Timer[unique("Timer")];
  CountDualM.SendMsg -> GenericComm.SendMsg[AM_COUNTMSG];
  CountDualM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_COUNTMSG];
  CountDualM.Leds -> LedsC.Leds;
}

