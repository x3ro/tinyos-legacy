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
// $Id: ReliablePriorityRoutingSendM.nc,v 1.5 2003/01/21 23:05:30 cssharp Exp $

// Description: Maintain an outgoing queue for messages, otherwise a single
// send blocks all other sends until it completes.  This component nicely
// demonstrates the advantages of lightweight, stackable routing component
// architecture, because the behavior of this component is independent of
// the other routing components, and vice versa.

includes cqueue;
includes common_structs;

//!! RoutingMsgExt { uint8_t priority = 0; }
//!! RoutingMsgExt { uint8_t retries = 2; }
//!! RoutingMsgExt { RoutingDestination_t dest = {address : 0}; }

module ReliablePriorityRoutingSendM
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
  enum {
    NUM_PRIORITIES = 2,
    QUEUED_ROUTING_SIZE = 8,
  };

  typedef struct {
    TOS_MsgPtr msg;
  } queued_routing_t;

  typedef struct {
    queued_routing_t msgs[QUEUED_ROUTING_SIZE];
    cqueue_t cq;
  } priority_queue_t;

  priority_queue_t m_pq[NUM_PRIORITIES];
  priority_queue_t* m_sending_pq;


  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    int ii;
    for( ii=0; ii<NUM_PRIORITIES; ii++ )
      init_cqueue( &m_pq[ii].cq, QUEUED_ROUTING_SIZE );
    m_sending_pq = 0;
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


  uint8_t make_valid_priority( uint8_t p )
  {
    return ((p < NUM_PRIORITIES) ? p : NUM_PRIORITIES-1);
  }


  void do_send()
  {
    // Check the queues from back (highest priority) to front (lowest priority)
    priority_queue_t* pq = m_pq + NUM_PRIORITIES - 1;
    priority_queue_t* pq_end = m_pq - 1;

    // If there's a queue that's already sending, then do nothing.
    if( m_sending_pq != 0 )
      return;

    for( ; pq != pq_end; pq-- )
    {
      // If this queue is nonempty ...
      if( is_empty_cqueue( &pq->cq ) == FALSE )
      {
	// ... then try sending the packet at the front of this queue.
	if( call BottomRouting.send(
	      pq->msgs[pq->cq.front].msg->ext.dest,
	      pq->msgs[pq->cq.front].msg ) == SUCCESS )
	{
	  // Sending succeeded, wait for sendDone in this queue.
	  m_sending_pq = pq;
	}

	// If send failed, then no m_sending_pq has been marked.  We return
	// from here though, because we don't want to try sending from other
	// queues.  This queue (or one higher if applicable later) will be
	// reattemped next time do_send() is called.  If send failed here,
	// it probably also doesn't count against the retry count, which seems
	// to probably mean a failed ack, not an internal/local failure.
	return;
      }
    }
  }


  task void task_do_send()
  {
    do_send();
  }


  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    priority_queue_t* pq;

    msg->ext.priority = make_valid_priority( msg->ext.priority );
    pq = m_pq + msg->ext.priority;

    // if the queue is full, fail
    if( push_back_cqueue( &pq->cq ) == FAIL )
      return FAIL;

    // otherwise, put the packet at the back of the queue
    msg->ext.dest = dest;
    pq->msgs[pq->cq.back].msg = msg; 

    do_send();

    return SUCCESS;
  }


  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    result_t rv = FAIL;
    
    // Were we even trying to send a message?  If we don't have a sending queue
    // or if the one we have is empty, then do nothing.
    if( m_sending_pq && (is_empty_cqueue( &m_sending_pq->cq ) == FALSE) )
    {
      queued_routing_t* qq = m_sending_pq->msgs + m_sending_pq->cq.front;

      //call Leds.redToggle();

      // Is this sendDone for the message we were trying to send?  If not, then
      // do nothing.
      if( msg == qq->msg )
      {
	//call Leds.greenToggle();

	if( msg->ack || (msg->ext.retries == 0) )
	//if( (msg->ext.retries == 0) )
	{
	  //if( msg->ack ) call Leds.yellowToggle();

	  // If this message acked or we've run out of retries for it, then
	  // take it off the queue and notify the layer above if the send
	  // succeeded or failed?  (Or maybe we just expose the ack interface
	  // again?  I dunno.)
	  pop_front_cqueue( &m_sending_pq->cq );
	  rv = signal Routing.sendDone( msg, success );
	}
	else
	{
	  // If the message didn't ack and there are retries left to be made,
	  // then decrement the retry count.
	  msg->ext.retries--;
	  rv = SUCCESS;
	}

	// We're no longer sending a message, so clear the flag for do_send to
	// know that it's okay to (re)send messages.
	m_sending_pq = 0;
      }
    }

    // Try forcing a send even if we're not waiting for a send done.  This
    // restarts a stale queue that failed because another app was sending.

    // This sends the highest priority message in the queue, which may be a
    // retry of the message we just tried to send, a higher priority
    // message that has since come in, or the next message in the queue.
    post task_do_send();

    return rv;
  }


  // Passthrough routing receive

  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    // ... kickstart do_send if it happened to stall out
    if( m_sending_pq == 0 )
      post task_do_send();

    return signal Routing.receive( msg );
  }
}

