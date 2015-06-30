/*									
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * Author: August Joki <august@berkeley.edu>
 *
 *
 *
 */

configuration LandmarkRoutingC {
}
implementation {
  components Main, LandmarkRoutingM, LandmarkRouteC, /*PursuerNodeC,*/ TimerC, GenericComm as Comm, LedsC;

  Main.StdControl -> LandmarkRouteC.StdControl;
  Main.StdControl -> LandmarkRoutingM.StdControl;
  Main.StdControl -> Comm.Control;

  //LandmarkRoutingM.PursuerControl -> PursuerNodeC.StdControl;
  LandmarkRoutingM.Timer -> TimerC.Timer[unique("Timer")];
  LandmarkRoutingM.LRoute -> LandmarkRouteC.LRoute;
  LandmarkRoutingM.Receive -> Comm.ReceiveMsg[99];
  LandmarkRoutingM.TimerBlink -> TimerC.Timer[unique("Timer")]; //TOSSIM hack
  LandmarkRoutingM.Leds -> LedsC; //TOSSIM hack
}
