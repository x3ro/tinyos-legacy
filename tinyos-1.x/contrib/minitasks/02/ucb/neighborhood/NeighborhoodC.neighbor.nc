/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: NeighborhoodC.neighbor.nc,v 1.1 2003/01/21 23:06:01 cssharp Exp $

includes Routing;

configuration NeighborhoodC
{
  provides
  {
    interface TupleStore;
${provides}
    interface StdControl;
  }
}
implementation
{
  components TupleStoreM
           , TuplePublisherM
	   , TupleManagerM
	   , LedsC
	   , CommandInterpreterC
	   , RoutingC
	   , TimerC
	   , RandomLFSR
	   ;

  StdControl = TupleStoreM.StdControl;
  StdControl = TuplePublisherM.StdControl;
  StdControl = TupleManagerM.StdControl;

  TupleStore = TupleStoreM.TupleStore;
${wiring}
  TuplePublisherM -> TupleStoreM.TupleStore;
  TuplePublisherM -> LedsC.Leds;
  TuplePublisherM -> TupleManagerM.TupleManager;
  TuplePublisherM.RoutingSendByBroadcast -> RoutingC.RoutingSendByBroadcast[98];
  TuplePublisherM.RoutingReceive -> RoutingC.RoutingReceive[98];
  TuplePublisherM.CommandBroadcast -> CommandInterpreterC.CommandBroadcast;
  TuplePublisherM.CommandControl -> CommandInterpreterC;
  TuplePublisherM.Publish -> CommandInterpreterC.Cmd[unique("Command")];
  TuplePublisherM.Timer->TimerC.Timer[unique("Timer")];
  TuplePublisherM.Random->RandomLFSR;

  TupleManagerM -> TupleStoreM.TupleStore;
}


