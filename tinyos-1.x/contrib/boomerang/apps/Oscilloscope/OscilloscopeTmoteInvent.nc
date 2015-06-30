// $Id: OscilloscopeTmoteInvent.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

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
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 */

/**
 * This configuration describes the Oscilloscope application,
 * a simple TinyOS app that periodically takes sensor readings
 * and sends a group of readings over the radio. 
 * <p>
 * See README.TmoteInvent for more information
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration OscilloscopeTmoteInvent { }
implementation
{
  components Main
           , OscilloscopeTmoteInventM as OscilloscopeM
           , TimerC
           , LedsC
           , new MainControlC() as PhotoControl
           , new MainControlC() as AccelControl
           , InternalTempC
           , VoltageC
           , PhotoDriverC
           , AccelDriverC
           , OscopeC
           , GenericComm as Comm
           ;
  components DelugeC;

  Main.StdControl -> TimerC;
  Main.StdControl -> Comm;
  Main.StdControl -> OscopeC;
  Main.StdControl -> InternalTempC;
  Main.StdControl -> VoltageC;
  Main.StdControl -> OscilloscopeM;

  PhotoControl.SplitControl -> PhotoDriverC;
  AccelControl.SplitControl -> AccelDriverC;
  
  OscilloscopeM.Timer -> TimerC.Timer[unique("Timer")];

  OscilloscopeM.Leds -> LedsC;

  OscilloscopeM.AccelX -> AccelDriverC.AccelX;
  OscilloscopeM.AccelY -> AccelDriverC.AccelY;
  OscilloscopeM.Photo -> PhotoDriverC;
  OscilloscopeM.InternalTemperature -> InternalTempC;
  OscilloscopeM.InternalVoltage -> VoltageC;

  OscilloscopeM.OPhoto -> OscopeC.Oscope[0];
  OscilloscopeM.OAccelX -> OscopeC.Oscope[1];
  OscilloscopeM.OAccelY -> OscopeC.Oscope[2];
  OscilloscopeM.OInternalTemperature -> OscopeC.Oscope[4];
  OscilloscopeM.OInternalVoltage -> OscopeC.Oscope[5];

}
