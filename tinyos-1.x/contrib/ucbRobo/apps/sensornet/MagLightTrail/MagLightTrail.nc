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
// $Id: MagLightTrail.nc,v 1.1.1.1 2004/10/15 01:34:08 phoebusc Exp $
/**
 * MagLightTrail is an application.  Look at the documentation for
 * MagLightTrailM for operation details.
 *  
 * @author Phoebus Chen
 * @modified 7/28/2004
 */


includes MagMsg;

configuration MagLightTrail {
}

implementation {
  components Main, 
             MagLightTrailM,
             HDMagMagC as MagC,
             HDMagC, //for pulseSetReset
             GenericComm as Comm,
             TimerC,
             LedsC;

  Main.StdControl -> MagLightTrailM;
  Main.StdControl -> MagC;
  Main.StdControl -> Comm;
  Main.StdControl -> TimerC;

  MagLightTrailM.Leds -> LedsC;
  MagLightTrailM.SenseTimer -> TimerC.Timer[unique("Timer")];
  MagLightTrailM.FadeTimer -> TimerC.Timer[unique("Timer")];

  MagLightTrailM.MagControl -> MagC;
  MagLightTrailM.MagSensor -> MagC;
  MagLightTrailM.MagAxesSpecific -> MagC;

  MagLightTrailM.pulseSetReset -> HDMagC;

  MagLightTrailM.ReceiveQueryConfigMsg -> Comm.ReceiveMsg[AM_MAGQUERYCONFIGMSG];
  MagLightTrailM.SendQueryReportMsg -> Comm.SendMsg[AM_MAGQUERYCONFIGMSG];
  MagLightTrailM.SendMagReportMsg -> Comm.SendMsg[AM_MAGREPORTMSG];
}
