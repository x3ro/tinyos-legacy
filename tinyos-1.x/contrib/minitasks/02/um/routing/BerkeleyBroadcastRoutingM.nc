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
// $Id: BerkeleyBroadcastRoutingM.nc,v 1.1 2003/06/02 12:34:17 dlkiskis Exp $

// Description: Berkeley's routing component, currently not really
// supporting "routing", per se, as opposed to a bunch of infrastructure.

//!! RoutingMsgExt { bool forward = FALSE; }

includes forward_buffers;

module BerkeleyBroadcastRoutingM
{
  provides
  {
    interface Routing;
    interface StdControl;
  }
  uses
  {
    interface Routing as BottomRouting;
  }
}
implementation
{
  typedef RoutingHopCount_t header_t;

  enum {
    HEADER_LENGTH = sizeof(header_t),
  };


  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    init_forward_buffers();
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

  result_t send( RoutingHopCount_t hops, TOS_MsgPtr msg )
  {
    RoutingAddress_t addr = TOS_BCAST_ADDR;
    header_t* head = (header_t*)pushToRoutingMsg( msg, HEADER_LENGTH );
    if( head == 0 ) return FAIL;
    *head = hops;
    return call BottomRouting.send( (RoutingDestination_t)addr, msg );
  }

  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    return send( dest.hops, msg );
  }


  // Send Done

  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    popFromRoutingMsg( msg, HEADER_LENGTH );

    if( msg->ext.forward == TRUE )
    {
      free_forward_buffer( msg );
      msg->ext.forward = FALSE;
      return SUCCESS;
    }

    return signal Routing.sendDone( msg, success );
  }


  // Receive

  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    TOS_MsgPtr tmp;
    header_t* head = (header_t*)popFromRoutingMsg( msg, HEADER_LENGTH );
    RoutingHopCount_t hops_left;
    if( head == 0 ) return msg;

    if( (hops_left = *head) > 0 )
    {
      // Broadcast, is there a way to not have to copy the message for
      // forwarding?  The problem is, of course, that the message must be both
      // delivered and forwarded.  Hence, two distinct messages are needed.

      if( (tmp = alloc_forward_buffer( msg )) != 0 )
      {
	*tmp = *msg;
	msg->ext.forward = TRUE;
	if( send( hops_left-1, msg ) == FAIL )
	  free_forward_buffer( msg );
	msg = tmp;
      }
    }

    return signal Routing.receive( msg );
  }
}

