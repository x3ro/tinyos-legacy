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
// $Id: DispatchRoutingReceiveM.nc,v 1.1 2003/05/04 03:26:07 cssharp Exp $

includes Routing;

module DispatchRoutingReceiveM
{
  provides interface Routing[ RoutingMethod_t method ];
  uses interface Routing as BottomRouting;
}
implementation
{
  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    return signal Routing.receive[ msg->dispatch.method ]( msg );
  }

  default event TOS_MsgPtr Routing.receive[ RoutingMethod_t method ](
      TOS_MsgPtr msg )
  {

    return msg;
  }

  
  command result_t Routing.send[ RoutingMethod_t method ](
      RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    // Ignore method, it must be bound higher up the stack for 
    // DispatchRoutingM.  We've only parameterized Routing to be able
    // to dispatch in sendDone.
    return call BottomRouting.send( dest, msg );
  }


  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return signal Routing.sendDone[ msg->dispatch.method ]( msg, success );
  }

  default event result_t Routing.sendDone[ RoutingMethod_t method ](
      TOS_MsgPtr msg, result_t success )
  {
    return FAIL;
  }
}

