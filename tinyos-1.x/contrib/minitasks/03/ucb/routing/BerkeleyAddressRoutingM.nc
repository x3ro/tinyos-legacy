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
// $Id: BerkeleyAddressRoutingM.nc,v 1.3 2003/07/02 10:49:12 cssharp Exp $

// Description: Berkeley's routing component, currently not really
// supporting "routing", per se, as opposed to a bunch of infrastructure.

module BerkeleyAddressRoutingM
{
  provides
  {
    interface Routing;
    interface StdControl;
  }
  uses
  {
    interface Routing as BottomRouting;
    interface Leds;
  }
}
implementation
{
  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }


  // Send

  result_t send( RoutingAddress_t addr, TOS_MsgPtr msg )
  {
    return call BottomRouting.send( (RoutingDestination_t)addr, msg );
  }

  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    return send( dest.address, msg );
  }


  // Send Done

  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return signal Routing.sendDone( msg, success );
  }


  // Receive

  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    // assume the lower layers did address filtering
    return signal Routing.receive( msg );
  }
}

