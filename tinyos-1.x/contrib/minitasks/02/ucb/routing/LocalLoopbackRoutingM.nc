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
// $Id: LocalLoopbackRoutingM.nc,v 1.3 2003/01/21 23:05:30 cssharp Exp $

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
  }
}
implementation
{
  TOS_Msg m_msgdata;
  TOS_MsgPtr m_msg_orig;
  TOS_MsgPtr m_msg_copy;
  bool m_is_sending;


  // ---
  // --- StdControl
  // ---

  command result_t StdControl.init()
  {
    m_msg_copy = &m_msgdata;
    m_is_sending = FALSE;
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
    *m_msg_copy = *m_msg_orig; // required copy, I believe
    m_msg_orig->ack = 1; // ack true
    signal Routing.sendDone( m_msg_orig, SUCCESS ); // signal sendDone
    m_msg_copy = signal Routing.receive( m_msg_copy ); // then signal receive
    m_is_sending = FALSE; // unlock
  }

  command result_t Routing.send( RoutingDestination_t dest, TOS_MsgPtr msg )
  {
    if( dest.address == TOS_LOCAL_ADDRESS )
    {
      if( m_is_sending == TRUE )
	return FAIL;
      m_is_sending = TRUE; // lock
      m_msg_orig = msg;
      post loopback();
      return SUCCESS;
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

