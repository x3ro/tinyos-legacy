/* "Copyright (c) 2000-2002 The Regents of the University of
 * California.  All rights reserved.
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
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."  */

// Authors: Cory Sharp
// $Id: BerkeleyLocationRoutingM.nc,v 1.1 2003/10/09 01:14:14 cssharp Exp $

//!! RoutingMsgExt { uint8_t location_retries = 4; }
//!! RoutingMsgExt { bool forward = FALSE; }

//!! UCBLocationRoutingHood = CreateNeighborhood( 8, BerkeleyLocationRouting, BroadcastBackend, 23 );
//!! UCBLocationRoutingAttr = CreateAttribute( UCBLocation_t = { x:0, y:0 } );
//!! UCBLocationRoutingRefl = CreateReflection( UCBLocationRoutingHood, UCBLocationRoutingAttr, FALSE, 24, 25 );
//!! UCBLocationRoutingNAKAttr = CreateAttribute( bool = FALSE );
//!! UCBLocationRoutingNAKRefl = CreateReflection( UCBLocationRoutingHood, UCBLocationRoutingNAKAttr, FALSE, 26, 27 );

module BerkeleyLocationRoutingM
{
  provides
  {
    interface Routing;
    interface StdControl;
  }
  uses
  {
    interface Routing as BottomRouting;
    interface TupleStore;
    interface Neighbor_ucb_location_nak;
    interface Neighbor_location;
    interface TimedLeds;
    interface MsgBuffers;
  }
}
implementation
{
  typedef Pair_int16_t berkeley_location_t;
  typedef berkeley_location_t header_t;

  enum {
    HEADER_LENGTH = sizeof(header_t),
  };

  berkeley_location_t m_my_location;


  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    // Hack for TOSSIM
    //TOS_LOCAL_ADDRESS += 0x201;

    call MsgBuffers.init();

    m_my_location.x = (TOS_LOCAL_ADDRESS >> 4) & 0x0f;
    m_my_location.y = (TOS_LOCAL_ADDRESS >> 0) & 0x0f;

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


  // ---
  // --- Location
  // ---

  uint16_t distsq( const location_t* a, const location_t* b )
  {
    if( a->coordinate_system == b->coordinate_system )
    {
      int16_t dx = a->pos.x - b->pos.x;
      int16_t dy = a->pos.y - b->pos.y;
      return dx*dx + dy*dy;
    }

    return (~(uint16_t)0); // max value
  }


  const Neighbor_t* get_closest( location_t* loc, bool clear_naks )
  {
    const Neighbor_t* me = call TupleStore.getByAddress( TOS_LOCAL_ADDRESS );
    const Neighbor_t* min_neighbor = 0;
    uint8_t candidate_count = 0;
    uint8_t nak_count = 0;

    // Check that the local tuple exists and it has a valid coordinate system.
    if( (me != 0) 
        && ((loc->coordinate_system = me->location.coordinate_system) != 0)
      )
    {
      // Initialize a tuple iterator, and calculate the distance from the
      // local mote to the destination.
      TupleIterator_t ii = call TupleStore.initIterator();
      uint16_t my_dist = distsq( &me->location, loc );
      uint16_t min_dist = my_dist;

      // Return now if the distance between us and the destination is zero.
      if( my_dist == 0 )
	return me;

      // Iterate over all valid tuples in the tuple store.
      while( call TupleStore.getNext(&ii) == TRUE )
      {
	// Check that this tuple is not the local tuple.
	if( ii.tuple->address != TOS_LOCAL_ADDRESS )
	{
	  // Calculate the distance from this tuple to the destination, and
	  // check that it's closer than the local tuple.
	  uint16_t dd = distsq( &ii.tuple->location, loc );
	  if( dd < my_dist )
	  {
	    // This tuple is a candidate destination, increment the count.
	    candidate_count++;

	    if( clear_naks == TRUE )
	    {
	      // If we came in here with the intent to clear naks, then clear
	      // its nak if set, and pick the closest tuple.

	      if( ii.tuple->ucb_location_nak == TRUE )
	      {
		bool nak = FALSE;
		call Neighbor_ucb_location_nak.set( ii.tuple->address, &nak );
	      }

	      if( dd < min_dist )
	      {
		min_dist = dd;
		min_neighbor = ii.tuple;
	      }
	    }
	    else
	    {
	      // Otherwise, pick the closest non-naking tuple, or increment the
	      // nak count.

	      if( ii.tuple->ucb_location_nak == TRUE )
	      {
		nak_count++;
	      }
	      else
	      {
		if( dd < min_dist )
		{
		  min_dist = dd;
		  min_neighbor = ii.tuple;
		}
	      }
	    }
	  }
	}
      }
    }

    // If we have candidates but they all naked, then recurse with clear_naks
    // enabled.  With clear_naks enabled, nak_count is guaranteed to be zero.
    if( (candidate_count != 0) && (candidate_count == nak_count) )
      min_neighbor = get_closest( loc, TRUE );

    return min_neighbor;
  }


  // return a mote ID closest to the given geographic location
  RoutingAddress_t xlateLocationToAddress( RoutingLocation_t* location )
  {
    location_t loc = { pos:location->pos, stdv:{x:0,y:0,z:0} };
    const Neighbor_t* min_neighbor = get_closest( &loc, FALSE );
    return ((min_neighbor == 0) ? 0xadde : min_neighbor->address);
  }


  // ---
  // --- Dispatch send and receive
  // ---

  result_t send( RoutingLocation_t* location, TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)pushToRoutingMsg( msg, HEADER_LENGTH );
    RoutingAddress_t dest;

    if( head == 0 ) return FAIL;

    dest = xlateLocationToAddress( location );
    head->x = location->pos.x;
    head->y = location->pos.y;

    return call BottomRouting.send( (RoutingDestination_t)dest, msg );
  }

  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    return send( dest.location, msg );
  }


  result_t sendDone( TOS_MsgPtr msg, result_t success )
  {
    popFromRoutingMsg( msg, HEADER_LENGTH );

    if( msg->ext.forward )
    {
      call MsgBuffers.free( msg );
      // clear the forward flag, defensive programming
      msg->ext.forward = FALSE;
      return SUCCESS;
    }

    return signal Routing.sendDone( msg, success );
  }


  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    header_t* head = (header_t*)popFromRoutingMsg( msg, HEADER_LENGTH );
    bool nak = (msg->ack ? FALSE : TRUE);
    if( head == 0 ) return FAIL;

    // set the nak field for this neighbor
    call Neighbor_ucb_location_nak.set( msg->addr, &nak );

    // If ack, then signal sendDone
    if( msg->ack )
      return sendDone( msg, success );

    {
      RoutingLocation_t loc = { pos:{x:0, y:0, z:0}, radius:{x:0, y:0, z:0} };
      if( (msg->ext.location_retries == 0) || (send( &loc, msg ) == FAIL) )
	return sendDone( msg, FAIL );
    }

    msg->ext.location_retries--;
    return SUCCESS;
  }


  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)popFromRoutingMsg( msg, HEADER_LENGTH );
    RoutingAddress_t dest;

    if( head == 0 )
      return msg;

    // translate the geographic destination to an address
    {
      RoutingLocation_t loc = { pos:{x:head->x, y:head->y, z:0}, radius:{x:0, y:0, z:0} };
      dest = xlateLocationToAddress( &loc );
    }

    // if the destination address isn't local, then forward
    if( dest != TOS_LOCAL_ADDRESS )
    {
      // Get a replacement buffer so we can hold on to this buffer.  If none
      // are available, then we can't forward, so abort.
      TOS_MsgPtr tmp = call MsgBuffers_alloc_for_swap( msg );
      if( tmp == 0 ) return msg;

      // Remember this is a forwarded msg to prevent propagation of sendDone
      // and to call free_forward_buffer only when necessary.
      msg->ext.forward = TRUE;  
      call TimedLeds.greenOn( 500 );

      pushToRoutingMsg( msg, HEADER_LENGTH ); // restore the old header
      if( call BottomRouting.send( (RoutingDestination_t)dest, msg ) == FAIL )
	call MsgBuffers.free( msg );
      return tmp;
    }

    // otherwise, local delivery
    return signal Routing.receive( msg );
  }


  event void Neighbor_ucb_location_nak.updatedFromRemote( uint16_t address )
  {
  }


  event void Neighbor_location.updatedFromRemote( uint16_t address )
  {
    bool nak = FALSE;
    call Neighbor_ucb_location_nak.set( address, &nak );
  }
}

