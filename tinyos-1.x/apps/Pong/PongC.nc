// $Id: PongC.nc,v 1.1 2004/06/21 20:00:49 jpolastre Exp $

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

includes PongMsg;

configuration PongC
{
}
implementation
{
  components Main
           , PongM
	   , TimerC
	   , GenericComm
	   , LedsC
	   ;
  
  Main.StdControl -> GenericComm;
  Main.StdControl -> TimerC;
  Main.StdControl -> PongM;

  PongM.Timer -> TimerC.Timer[unique("Timer")];
  PongM.SendMsg -> GenericComm.SendMsg[AM_PONGMSG];
  PongM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_PONGMSG];
  PongM.PingMsg -> GenericComm.ReceiveMsg[AM_PINGMSG];
  PongM.Leds -> LedsC.Leds;
}

