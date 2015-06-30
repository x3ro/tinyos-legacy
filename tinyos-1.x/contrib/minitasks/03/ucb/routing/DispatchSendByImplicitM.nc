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
// $Id: DispatchSendByImplicitM.nc,v 1.1 2003/06/27 07:46:30 cssharp Exp $

includes Routing;

module DispatchSendByImplicitM
{
  provides interface RoutingSendByImplicit[ RoutingProtocol_t protocol ];
  uses interface RoutingSend as BottomRoutingSend;
}
implementation
{
  command result_t RoutingSendByImplicit.send[ RoutingProtocol_t protocol ](
      TOS_MsgPtr msg
    )
  {
    RoutingDestination_t dest = { address : 0 };
    msg->dispatch.protocol = protocol;
    return call BottomRoutingSend.send( dest, msg );
  }

  event result_t BottomRoutingSend.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return signal RoutingSendByImplicit.sendDone[ msg->dispatch.protocol ]( msg, success );
  }

  default event result_t RoutingSendByImplicit.sendDone[ RoutingProtocol_t protocol ](
      TOS_MsgPtr msg,
      result_t success
    )
  {
    return FAIL;
  }
}

