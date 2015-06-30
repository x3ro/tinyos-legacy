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


configuration RouteDiscoveryC {
  provides interface RouteDiscovery;
}

implementation {
  components RouteDiscoveryM, LinkQMessageC as Comm, TimerC, MutationHoodC, LinkQHoodC, RandomLFSR;

  RouteDiscovery = RouteDiscoveryM;

  RouteDiscoveryM.LinkQHood -> LinkQHoodC;
  RouteDiscoveryM.MutationHood -> MutationHoodC;
  RouteDiscoveryM.RcvRREQ -> Comm.ReceiveMsg[MUTATION_RREQ];
  RouteDiscoveryM.RcvRREP -> Comm.ReceiveMsg[MUTATION_RREP];
  RouteDiscoveryM.SndRREQ -> Comm.SendMsg[MUTATION_RREQ];
  RouteDiscoveryM.SndRREP -> Comm.SendMsg[MUTATION_RREP];
  RouteDiscoveryM.RcvRoute -> Comm.ReceiveMsg[MUTATION_ROUTE];

  RouteDiscoveryM.TimerReset -> TimerC.Timer[unique("Timer")];
  RouteDiscoveryM.TimerRoute -> TimerC.Timer[unique("Timer")];
  RouteDiscoveryM.TimerPSend -> TimerC.Timer[unique("Timer")];
  RouteDiscoveryM.TimerQSend -> TimerC.Timer[unique("Timer")];

  RouteDiscoveryM.Random -> RandomLFSR;
}
