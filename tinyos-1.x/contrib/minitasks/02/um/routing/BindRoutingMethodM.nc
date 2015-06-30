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
// $Id: BindRoutingMethodM.nc,v 1.1 2003/06/02 12:34:17 dlkiskis Exp $

includes Routing;

module BindRoutingMethodM
{
  provides interface RoutingSend[ RoutingMethod_t method ];
  provides interface RoutingReceive[ RoutingProtocol_t protocol ];

  uses interface Routing as BottomRouting;
}
implementation
{
  command result_t RoutingSend.send[ RoutingMethod_t method ](
      RoutingDestination_t dest,
      TOS_MsgPtr msg
    )
  {
    msg->dispatch.method = method;
    return call BottomRouting.send( dest, msg );
  }

  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return signal RoutingSend.sendDone[ msg->dispatch.method ]( msg, success );
  }

  default event result_t RoutingSend.sendDone[ RoutingMethod_t method ](
      TOS_MsgPtr msg,
      result_t success
    )
  {
    return FAIL;
  }


  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    return signal RoutingReceive.receive[ msg->dispatch.protocol ]( msg );
  }

  default event TOS_MsgPtr RoutingReceive.receive[ RoutingProtocol_t protocol ](
      TOS_MsgPtr msg
    )
  {
    return msg;
  }
}

