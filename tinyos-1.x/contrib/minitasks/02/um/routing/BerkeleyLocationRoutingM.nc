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
// $Id: BerkeleyLocationRoutingM.nc,v 1.1 2003/06/02 12:34:17 dlkiskis Exp $

//!! RoutingMsgExt { uint8_t hack_parent_index = -1; }
//!! RoutingMsgExt { bool forward = FALSE; }

includes forward_buffers;

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
  }
}
implementation
{
  typedef Pair_int16_t berkeley_location_t;
  typedef berkeley_location_t header_t;

  enum {
    HEADER_LENGTH = sizeof(header_t),
    MAX_PARENTS = 5,
    FORWARD_QUEUE_SIZE = 4,
  };

  RoutingAddress_t m_parent[ MAX_PARENTS ];
  bool m_parents_wrapped_around;

  berkeley_location_t m_my_location;


  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    // Hack for TOSSIM
    //TOS_LOCAL_ADDRESS += 0x201;

    // prep fake location lookup
    m_parent[0] = TOS_LOCAL_ADDRESS - 0x10;
    m_parent[1] = TOS_LOCAL_ADDRESS - 0x01;
    m_parent[2] = TOS_LOCAL_ADDRESS - 0x11;
    m_parent[3] = TOS_LOCAL_ADDRESS - 0x20;
    m_parent[4] = TOS_LOCAL_ADDRESS - 0x02;
    //if(TOS_LOCAL_ADDRESS == 0x200) m_parent[0] = TOS_UART_ADDR;
    m_parents_wrapped_around = FALSE;

    m_my_location.x = (TOS_LOCAL_ADDRESS >> 4) & 0x0f;
    m_my_location.y = (TOS_LOCAL_ADDRESS >> 0) & 0x0f;

    // initialize the forwarding buffers
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


  // ---
  // --- Location
  // ---

  // Function to switch parent.
  uint8_t advance_parent( uint8_t parent_index )
  {
    // don't try other parents if the current parent is the uart
    //bool retry = (m_parent[parent_index] != TOS_UART_ADDR);
    bool retry = TRUE;
    m_parents_wrapped_around = FALSE;

    while( retry )
    {
      if( ++parent_index >= MAX_PARENTS )
      {
	parent_index = 0;

	// If we already wrapped around once, shit, get out of here.
	if( m_parents_wrapped_around )
	  break;

	m_parents_wrapped_around = TRUE;
      }

      // ??? wtf? some sorry ass overflow detection for the border cases?
      // please, let's be more convoluted and uncommented, and also not
      // even work correctly and stuff.
      //retry = ((m_parent[parent_index] ^ TOS_LOCAL_ADDRESS) & 0x88);
      retry = (m_parent[parent_index] & 0x88);
    }

    return parent_index;
  }


  // return a mote ID closest to the given geographic location
  RoutingAddress_t xlateLocationToAddress( berkeley_location_t* location, TOS_MsgPtr msg )
  {
    if( (location->x == m_my_location.x) && (location->y == m_my_location.y) )
      return TOS_LOCAL_ADDRESS;

    msg->ext.hack_parent_index = advance_parent( msg->ext.hack_parent_index );
    return m_parent[ msg->ext.hack_parent_index ];
  }


  // ---
  // --- Dispatch send and receive
  // ---

  result_t send( berkeley_location_t* location, TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)pushToRoutingMsg( msg, HEADER_LENGTH );
    RoutingAddress_t dest;

    if( head == 0 ) return FAIL;

    dest = xlateLocationToAddress( location, msg );

    if( m_parents_wrapped_around == TRUE )
      return FAIL;
    
    *head = *location;
    msg->ext.retries = 2;
    return call BottomRouting.send( (RoutingDestination_t)dest, msg );
  }

  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    berkeley_location_t location = { x:dest.location->pos.x, y:dest.location->pos.y };
    return send( &location, msg );
  }


  result_t sendDone( TOS_MsgPtr msg, result_t success )
  {
    popFromRoutingMsg( msg, HEADER_LENGTH );

    if( msg->ext.forward )
    {
      free_forward_buffer( msg );

      // clear the forward flag, defensive programming
      msg->ext.forward = FALSE;

      return SUCCESS;
    }

    return signal Routing.sendDone( msg, success );
  }


  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    header_t* head = (header_t*)popFromRoutingMsg( msg, HEADER_LENGTH );;
    if( head == 0 ) return FAIL;

    // If ack, then signal sendDone
    if( msg->ack )
      return sendDone( msg, success );

    if( send( head, msg ) == FAIL )
      return sendDone( msg, FAIL );

    return SUCCESS;
  }


  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)popFromRoutingMsg( msg, HEADER_LENGTH );
    RoutingAddress_t dest;

    if( head == 0 ) return msg;

    // translate the geographic destination to an address
    dest = xlateLocationToAddress( head, msg );

    // if the destination address isn't local, then forward
    if( dest != TOS_LOCAL_ADDRESS )
    {
      // Get a replacement buffer so we can hold on to this buffer.  If none
      // are available, then we can't forward, so abort.
      TOS_MsgPtr tmp = alloc_forward_buffer( msg );
      if( tmp == 0 ) return msg;

      // Remember this is a forwarded msg to prevent propagation of sendDone
      // and to call free_forward_buffer only when necessary.
      msg->ext.forward = TRUE;  

      pushToRoutingMsg( msg, HEADER_LENGTH ); // restore the old header
      if( call BottomRouting.send( (RoutingDestination_t)dest, msg ) == FAIL )
	free_forward_buffer( msg );
      return tmp;
    }

    // otherwise, local delivery
    return signal Routing.receive( msg );
  }
}

