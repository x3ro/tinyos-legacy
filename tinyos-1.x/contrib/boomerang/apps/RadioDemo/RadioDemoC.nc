//$Id: RadioDemoC.nc,v 1.1.1.1 2007/11/05 19:08:59 jpolastre Exp $

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
 *
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 */

/**
 * Run one of three programs: CountRadio, ExchangeRSSI, ExchangeLQI.
 * Node 1 is the server and it allows a Tmote user button to switch
 * between modes.  Other nodes may be other, compatible platforms.
 *
 * @author Cory Sharp <info@moteiv.com>
 */

#include "CountMsg.h"

configuration RadioDemoC
{
}
implementation
{
  components Main
           , RadioDemoM
	   , TimerC
	   , LedsC
	   , GenericComm
	   , DelugeC
	   , UserButtonC
	   ;

  Main.StdControl -> DelugeC;
  Main.StdControl -> TimerC;
  Main.StdControl -> GenericComm;
  Main.StdControl -> RadioDemoM;

  RadioDemoM.Timer -> TimerC.Timer[unique("Timer")];
  RadioDemoM.Leds -> LedsC;
  RadioDemoM.SendMsg -> GenericComm.SendMsg[AM_COUNT_MSG];
  RadioDemoM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_COUNT_MSG];
  RadioDemoM.Button -> UserButtonC;
}

