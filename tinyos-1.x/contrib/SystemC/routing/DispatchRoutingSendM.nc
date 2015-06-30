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
// $Id: DispatchRoutingSendM.nc,v 1.1 2003/10/09 01:14:14 cssharp Exp $

includes Routing;

module DispatchRoutingSendM
{
  provides interface Routing;
  uses interface Routing as BottomRouting[ RoutingMethod_t method ];
}
implementation
{
  event TOS_MsgPtr BottomRouting.receive[ RoutingMethod_t method ](
      TOS_MsgPtr msg )
  {
    return signal Routing.receive( msg );
  }


  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    return call BottomRouting.send[ msg->dispatch.method ]( dest, msg );
  }


  default command result_t BottomRouting.send[ RoutingMethod_t method ](
      RoutingDestination_t dest,
      TOS_MsgPtr msg
    )
  {
    return FAIL;
  }


  event result_t BottomRouting.sendDone[ RoutingMethod_t method ](
      TOS_MsgPtr msg,
      result_t success
    )
  {
    return signal Routing.sendDone( msg, success );
  }
}

