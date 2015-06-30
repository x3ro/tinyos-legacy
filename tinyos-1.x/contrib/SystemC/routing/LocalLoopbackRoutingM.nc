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
// $Id: LocalLoopbackRoutingM.nc,v 1.1 2003/10/09 01:14:14 cssharp Exp $

module LocalLoopbackRoutingM
{
  provides
  {
    interface Routing;
    interface StdControl;
  }
  uses
  {
    interface Routing as BottomRouting;
    interface MsgBuffers;
  }
}
implementation
{
  TOS_MsgPtr m_msg_orig;

  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    m_msg_orig = 0;
    call MsgBuffers.init();
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

  task void loopback()
  {
    TOS_MsgPtr msg_copy = call MsgBuffers_alloc();
    if( msg_copy == 0 )
    {
      m_msg_orig->ack = 0; // ack false
      signal Routing.sendDone( m_msg_orig, FAIL ); // signal sendDone
    }
    else
    {
      TOS_MsgPtr msg_copy_return = 0;
      m_msg_orig->ack = 1; // ack true
      *msg_copy = *m_msg_orig; // required copy, I believe
      signal Routing.sendDone( m_msg_orig, SUCCESS ); // signal sendDone
      msg_copy_return = signal Routing.receive( msg_copy ); // then signal receive
      call MsgBuffers.free_and_swap( msg_copy, msg_copy_return );
    }
    m_msg_orig = 0; // unlock
  }

  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    if( dest.address == TOS_LOCAL_ADDRESS )
    {
      if( m_msg_orig == 0 )
      {
	m_msg_orig = msg; // lock
	if( post loopback() )
	  return SUCCESS;
	m_msg_orig = 0; // unlock
      }
      return FAIL;
    }
    return call BottomRouting.send( dest, msg );
  }

  event result_t BottomRouting.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return signal Routing.sendDone( msg, success );
  }


  event TOS_MsgPtr BottomRouting.receive( TOS_MsgPtr msg )
  {
    return signal Routing.receive( msg );
  }
}

