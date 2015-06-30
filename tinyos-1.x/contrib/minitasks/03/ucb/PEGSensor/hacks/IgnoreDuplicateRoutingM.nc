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
// $Id: IgnoreDuplicateRoutingM.nc,v 1.2 2003/07/10 04:55:04 nksrules Exp $

// NOTES on sequence and origin:
//
//  - An outgoing message with the default, invalid value for sequence
//  and/or origin will have the respective value changed to a valid value
//  (the next sequence number, the local address).
//
//  - An incoming message with an invalid value for EITHER sequence OR
//  origin is treated as a duplicate message.
//
//  - An incoming message with this node's local address as the origin is
//  treated as a duplicate message.
//
//!! RoutingMsgExt { RoutingSequenceNumber_t sequence = 0; }
//!! RoutingMsgExt { RoutingAddress_t origin = 65535u; }

module IgnoreDuplicateRoutingM
{
  provides
  {
    interface Routing;
    interface StdControl;

    interface RoutingGetSourceAddress;
  }
  uses
  {
    interface Routing as BottomRouting;
  }
}
implementation
{
  typedef struct {
    RoutingAddress_t origin;
    RoutingSequenceNumber_t sequence;
  } __attribute__((packed)) message_id_t;

  typedef message_id_t header_t;

  enum {
    NUM_SLOTS = 8,
    INVALID_ORIGIN = 65535u,
    INVALID_SEQUENCE = 0,
  };

  message_id_t m_dupes[ NUM_SLOTS ];
  RoutingSequenceNumber_t m_sequence;
  uint8_t m_dupes_index;


  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    static message_id_t invalid_dupe = {
      origin : INVALID_ORIGIN,
      sequence : INVALID_SEQUENCE,
    };
    int ii;
    for( ii=0; ii<NUM_SLOTS; ii++ )
      m_dupes[ii] = invalid_dupe;
    m_sequence = 0;
    m_dupes_index = 0;
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


  bool is_dupe( const message_id_t* dupe )
  {
    uint8_t ii;

    // A message that appears to have come from me is treated as a dupe.
    if( dupe->origin == TOS_LOCAL_ADDRESS ) {
      dbg(DBG_AM, "Origin matches me. Dupe.\n");
      return TRUE;
   } 
    // Should an incoming invalid address or invalid sequence be categorically
    // a dupe or not dupe?  I guess dupe.
    if( dupe->origin == INVALID_ORIGIN || dupe->sequence == INVALID_SEQUENCE ) {
      	dbg(DBG_AM, "Origin %i:%i, sequence: %i:%i\n", (int)dupe->origin, (int)INVALID_ORIGIN, (int)dupe->sequence, (int)INVALID_SEQUENCE);
	
      return TRUE;
      }
    
    for( ii=0; ii<NUM_SLOTS; ii++ )
    {
      if( (m_dupes[ii].sequence == dupe->sequence)
	  && (m_dupes[ii].origin == dupe->origin)
	)
      {
	return TRUE;
      }
    }

    return FALSE;
  }


  void add_to_dupes( message_id_t* dupe )
  {
    // Increment m_dupes_index first so that it always points to the most
    // recent dupe, not the oldest.  This is useful in RoutingGetSourceAddress.
    if( ++m_dupes_index >= NUM_SLOTS )
      m_dupes_index = 0;
    m_dupes[m_dupes_index] = *dupe;
  }


  void tag_msg( TOS_MsgPtr msg )
  {
    if( msg->ext.origin == INVALID_ORIGIN )
      msg->ext.origin = TOS_LOCAL_ADDRESS;

    if( msg->ext.sequence == INVALID_SEQUENCE )
    {
      if( ++m_sequence == INVALID_SEQUENCE )
	++m_sequence;
      msg->ext.sequence = m_sequence;
    }
  }


  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)pushToRoutingMsg( msg, sizeof(header_t) );
    if( head == NULL ) return FAIL;
    tag_msg( msg );
    head->origin = msg->ext.origin;
    head->sequence = msg->ext.sequence;
    return call BottomRouting.send( dest, msg );
  }


  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    popFromRoutingMsg( msg, sizeof(header_t) );
    return signal Routing.sendDone( msg, success );
  }


  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)popFromRoutingMsg( msg, sizeof(header_t) );
    dbg(DBG_AM, "IgnoreDuplicateRouting received. Sizeof struct: %i.\n", (int)sizeof(header_t));
    if( (head == NULL) || is_dupe(head) ) {
    	dbg(DBG_AM, "DUPLICATE, head: 0x%x\n", head);
    return msg;
    }
    add_to_dupes( head );
    msg->ext.origin = head->origin;
    msg->ext.sequence = head->sequence;
    return signal Routing.receive( msg );
  }


  command RoutingAddress_t RoutingGetSourceAddress.get()
  {
    return m_dupes[m_dupes_index].origin;
  }
}

