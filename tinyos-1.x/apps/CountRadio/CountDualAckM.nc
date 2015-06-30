// $Id: CountDualAckM.nc,v 1.2 2004/05/30 20:48:46 cssharp Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Cory Sharp <cssharp@eecs.berkeley.edu>

includes CountMsg;
includes Timer;

module CountDualAckM
{
  provides interface StdControl;
  uses interface Timer;
  uses interface SendMsg;
  uses interface ReceiveMsg;
  uses interface Leds;
  uses interface MacControl;
}
implementation
{
  TOS_Msg m_msg;
  int m_int;
  bool m_sending;

  command result_t StdControl.init()
  {
    m_int = 0;
    m_sending = FALSE;
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call MacControl.enableAck();
    if( TOS_LOCAL_ADDRESS == 1 )
      call Timer.start( TIMER_REPEAT, 50 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    if( m_sending == FALSE )
    {
      CountMsg_t* body = (CountMsg_t*)m_msg.data;
      body->n = m_int;
      body->src = TOS_LOCAL_ADDRESS;
      if( call SendMsg.send( 3, sizeof(CountMsg_t), &m_msg ) == SUCCESS )
      {
	call Leds.set( m_int );
	m_sending = TRUE;
      }
    }
    m_int++;
    return SUCCESS;
  }

  event result_t SendMsg.sendDone( TOS_MsgPtr msg, result_t success )
  {
    if (!(msg->ack))
      m_int--;
    m_sending = FALSE;
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg )
  {
    CountMsg_t* body = (CountMsg_t*)(&msg->data[0]);
    call Leds.set( body->n );
    return msg;
  }
}

