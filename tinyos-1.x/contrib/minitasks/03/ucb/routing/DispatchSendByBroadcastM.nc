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
// $Id: DispatchSendByBroadcastM.nc,v 1.1 2003/05/04 03:26:07 cssharp Exp $

includes Routing;

module DispatchSendByBroadcastM
{
  provides interface RoutingSendByBroadcast[ RoutingProtocol_t protocol ];
  uses interface RoutingSend as BottomRoutingSend;
}
implementation
{
  command result_t RoutingSendByBroadcast.send[ RoutingProtocol_t protocol ](
      RoutingHopCount_t hops,
      TOS_MsgPtr msg
    )
  {
    msg->dispatch.protocol = protocol;
    return call BottomRoutingSend.send( (RoutingDestination_t)hops, msg );
  }

  event result_t BottomRoutingSend.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return signal RoutingSendByBroadcast.sendDone[ msg->dispatch.protocol ]( msg, success );
  }

  default event result_t RoutingSendByBroadcast.sendDone[ RoutingProtocol_t protocol ](
      TOS_MsgPtr msg,
      result_t success
    )
  {
    return FAIL;
  }
}

