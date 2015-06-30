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
// $Id: IgnoreDuplicateRoutingM.nc,v 1.2 2003/01/21 23:05:30 cssharp Exp $

//!! RoutingMsgExt { uint16_t sequence = 0; }
//!! RoutingMsgExt { uint16_t origin = 0; }

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
  typedef uint16_t sequence_t;

  typedef struct {
    RoutingAddress_t origin;
    sequence_t sequence;
  } message_id_t;

  typedef message_id_t header_t;

  enum {
    NUM_SLOTS = 8,
    HEADER_LENGTH = sizeof(header_t),
  };

  message_id_t m_dupes[ NUM_SLOTS ];
  sequence_t m_sequence;
  uint8_t m_dupes_index;


  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    int ii;
    for( ii=0; ii<NUM_SLOTS; ii++ )
    {
      m_dupes[ii].origin = 0;
      m_dupes[ii].sequence = 0;
    }
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


  bool is_dupe( message_id_t* dupe )
  {
    message_id_t* ii = m_dupes;
    message_id_t* iiend = m_dupes + NUM_SLOTS;

    if( dupe->origin == TOS_LOCAL_ADDRESS )
      return TRUE;
    
    while( ii != iiend )
    {
      if( (ii->sequence == dupe->sequence) && (ii->origin == dupe->origin) )
	return TRUE;
      ii++;
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
    if( msg->ext.origin == 0 )
      msg->ext.origin = TOS_LOCAL_ADDRESS;

    if( msg->ext.sequence == 0 )
      msg->ext.sequence = (++m_sequence ? m_sequence : (m_sequence=1));
  }


  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)pushToRoutingMsg( msg, HEADER_LENGTH );
    if( head == 0 ) return FAIL;
    tag_msg( msg );
    head->origin   = msg->ext.origin;
    head->sequence = msg->ext.sequence;
    return call BottomRouting.send( dest, msg );
  }


  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    popFromRoutingMsg( msg, HEADER_LENGTH );
    return signal Routing.sendDone( msg, success );
  }


  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)popFromRoutingMsg( msg, HEADER_LENGTH );
    if( (head == 0) || is_dupe(head) ) return msg;
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

