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
// $Id: MagMHopRpt.nc,v 1.2 2005/04/15 20:10:06 phoebusc Exp $
/**
 * MagMHopRpt is an application.  Look at the documentation for
 * MagMHopRptM for operation details.
 *  
 * @author Phoebus Chen
 * @modified 12/1/2004 Created
 */


includes MagSNMhopMsgs;

configuration MagMHopRpt {
}

implementation {
  components Main, 
             MagMHopRptM,
             HDMagMagC as MagC,
             HDMagC, //for pulseSetReset
             GenericCommPromiscuous as Comm,
             Bcast,
             WMEWMAMultiHopRouter as MHopRouter,
             TimerC,
             LedsC;

  Main.StdControl -> MagMHopRptM;
  Main.StdControl -> MagC;
  Main.StdControl -> MHopRouter;
  Main.StdControl -> Comm; //probably optional, since initialized by BCast
  Main.StdControl -> Bcast; //Not sure why, but Bcast gives
  //warning: `result' might be used uninitialized in this function
  //during compilation
  Main.StdControl -> TimerC;

  MagMHopRptM.Leds -> LedsC;
  MagMHopRptM.SenseTimer -> TimerC.Timer[unique("Timer")];
  MagMHopRptM.FadeTimer -> TimerC.Timer[unique("Timer")];

  MagMHopRptM.MagControl -> MagC;
  MagMHopRptM.MagSensor -> MagC;
  MagMHopRptM.MagAxesSpecific -> MagC;

  MagMHopRptM.pulseSetReset -> HDMagC;


  //For receiving/forwarding commands
  MagMHopRptM.ReceiveQueryConfig -> Bcast.Receive[AM_MAGQUERYCONFIGBCASTMSG];
  Bcast.ReceiveMsg[AM_MAGQUERYCONFIGBCASTMSG] -> Comm.ReceiveMsg[AM_MAGQUERYCONFIGBCASTMSG];

  //For sending reports
  MagMHopRptM.SendQueryReport -> MHopRouter.Send[AM_MAGQUERYRPTMHOPMSG];
  MagMHopRptM.SendMagReport -> MHopRouter.Send[AM_MAGREPORTMHOPMSG];

  //For testing
  MagMHopRptM.RouteControl -> MHopRouter;
  MagMHopRptM.SendMagDebugMsg -> Comm.SendMsg[AM_MAGDEBUGMSG]; // should send over UART so no confusion
}
