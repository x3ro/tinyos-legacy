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
// $Id: QueuedRoutingSendM.nc,v 1.1 2003/06/02 12:34:17 dlkiskis Exp $

// Description: Maintain an outgoing queue for messages, otherwise a single
// send blocks all other sends until it completes.  This component nicely
// demonstrates the advantages of lightweight, stackable routing component
// architecture, because the behavior of this component is independent of
// the other routing components, and vice versa.

includes cqueue;

module QueuedRoutingM
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
  enum {
    QUEUED_ROUTING_SIZE = 16,
  };

  bool m_is_sending;

  typedef struct {
    RoutingDestination_t dest;
    TOS_MsgPtr msg;
  } queued_routing_t;

  queued_routing_t m_msgs[QUEUED_ROUTING_SIZE];
  cqueue_t m_cq;


  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    m_is_sending = FALSE;
    init_cqueue( &m_cq, QUEUED_ROUTING_SIZE );
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



  void do_send()
  {
    if( m_is_sending == FALSE )
    {
      if( is_empty_cqueue( &m_cq ) == FALSE )
      {
	// if we're not waiting for a sendDone and there's a packet at the
	// front of the queue waiting to be sent, then try sending it.

	if( call BottomRouting.send(
	      m_msgs[m_cq.front].dest, m_msgs[m_cq.front].msg ) == SUCCESS )
	{
	  // sending succeeded, wait for sendDone
	  m_is_sending = TRUE;
	}

	// if it failed, then m_cq.front is untouched and will be reattempted
	// next time do_send() is called.
      }
    }
  }


  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    // if the queue is full, fail

    if( push_back_cqueue( &m_cq ) == FAIL )
      return FAIL;

    // otherwise, put the packet at the back of the queue

    m_msgs[m_cq.back].dest = dest;
    m_msgs[m_cq.back].msg  = msg; 

    do_send();

    return SUCCESS;
  }


  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    result_t rv = FAIL;
    
    // if the sendDone is for the message at the front of the queue, then pop
    // it off the front, record that we're not waiting for sendDone anymore,
    // send sendDone up the chain, and try sending another packet in the queue.
    
    if( is_empty_cqueue( &m_cq ) == FALSE )
    {
      if( msg == m_msgs[m_cq.front].msg )
      {
	pop_front_cqueue( &m_cq );
	m_is_sending = FALSE;
	rv = signal Routing.sendDone( msg, success );
      }
    }

    do_send();
    return rv;
  }


  // Passthrough routing receive

  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    return signal Routing.receive( msg );
  }
}

