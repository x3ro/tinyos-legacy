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
// $Id: FailedAckNeighborhoodM.nc,v 1.1 2003/06/02 12:34:17 dlkiskis Exp $

// Description: Translation layer from the NestArch Routing API to TinyOS.
// This component should be at the very bottom of the routing stack.


includes Neighbor;
//!! Neighbor 1 { uint8_t failed_acks = 0; }

module FailedAckNeighborhoodM
{
  provides
  {
    interface Routing;
  }
  uses
  {
    interface Routing as BottomRouting;
    interface Hood;
  }
}
implementation
{
  enum {
    MAX_FAILED_ACKS = 8,
  };

  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    return call BottomRouting.send( dest, msg );
  }

  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    NeighborPtr_t ii = call Hood.find_address( msg->addr );
    if( ii != 0 )
    {
      if( msg->ack )
	ii->failed_acks = 0;
      else if( ii->failed_acks < MAX_FAILED_ACKS )
	ii->failed_acks++;
    }

    return signal Routing.sendDone( msg, success );
  }

  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    return signal Routing.receive( msg );
  }
}

