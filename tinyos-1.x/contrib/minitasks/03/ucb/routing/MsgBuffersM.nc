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
// $Id: MsgBuffersM.nc,v 1.14 2003/07/10 22:04:31 cssharp Exp $

// Stupid memory leaks
//!! Config 8 { uint16_t MsgBuffersFlushOnFailTimeout = 5000; }

//!! RoutingMsgExt { uint8_t debug_msg_buffers; }

includes Routing;
includes MsgBuffers;

module MsgBuffersM
{
  provides interface MsgBuffers;
  uses interface DiagMsg;
  uses interface Timer;
  uses interface TimedLeds;
  uses interface ReceiveMsg;
}
implementation
{
  TOS_Msg m_buffer_data[MSGBUFFERS_NUM_BUFFERS];
  TOS_MsgPtr m_buffer[MSGBUFFERS_NUM_BUFFERS];
  uint8_t m_first_avail;

  command result_t MsgBuffers.init()
  {
    int ii;
    for( ii=0; ii<MSGBUFFERS_NUM_BUFFERS; ii++ )
      m_buffer[ii] = m_buffer_data+ii;
    m_first_avail = 0;
    return SUCCESS;
  }

  void alloc_failed()
  {
    if( G_Config.MsgBuffersFlushOnFailTimeout > 0 )
    {
      // For proper behavior (timeout on the first failure, not the most
      // recent failure), depend on Timer.start failing if is already running.
      call Timer.start( TIMER_ONE_SHOT, G_Config.MsgBuffersFlushOnFailTimeout );
    }
  }

  void free_succeeded()
  {
    call Timer.stop();
  }

  event result_t Timer.fired()
  {
    // The timeout timer fired, flush the message buffers (sorry lil guys)
    if( call DiagMsg.record() == SUCCESS )
    {
      int i;
      call DiagMsg.str("MsgBuffDbg");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      for( i=0; i<MSGBUFFERS_NUM_BUFFERS; i++ )
	call DiagMsg.uint8( m_buffer[i]->ext.debug_msg_buffers );
      call DiagMsg.send();
      call TimedLeds.redOn( 1000 );
    }
    m_first_avail = 0;
    return FAIL;
  }

  command TOS_MsgPtr MsgBuffers.debug_alloc( uint8_t debug )
  {
    if( m_first_avail < MSGBUFFERS_NUM_BUFFERS )
    {
      m_buffer[m_first_avail]->ext.debug_msg_buffers = debug;
      return m_buffer[ m_first_avail++ ];
    }
    alloc_failed();
    return NULL;
  }

  command TOS_MsgPtr MsgBuffers.debug_alloc_for_swap( uint8_t debug, TOS_MsgPtr msg_to_alloc )
  {
    if( m_first_avail < MSGBUFFERS_NUM_BUFFERS )
    {
      TOS_MsgPtr free_buffer = m_buffer[m_first_avail];
      m_buffer[m_first_avail] = msg_to_alloc;
      m_buffer[m_first_avail]->ext.debug_msg_buffers = debug;
      m_first_avail++;
      return free_buffer;
    }
    else
    {
      alloc_failed();
    }
    return NULL;
  }

  command void MsgBuffers.free_and_swap( TOS_MsgPtr msg_to_release, TOS_MsgPtr msg_to_provide )
  {
    uint8_t ii;
    for( ii=0; ii<m_first_avail; ii++ )
    {
      if( m_buffer[ii] == msg_to_release )
      {
	m_first_avail--;
	m_buffer[ii] = m_buffer[m_first_avail];
	m_buffer[m_first_avail] = msg_to_provide;
	free_succeeded();
	break;
      }
    }
  }

  command void MsgBuffers.free( TOS_MsgPtr msg_to_release )
  {
    call MsgBuffers.free_and_swap( msg_to_release, msg_to_release );
  }

  command void MsgBuffers.report()
  {
    if( call DiagMsg.record() == SUCCESS )
    {
      	call DiagMsg.str("used buffers");
	call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	call DiagMsg.uint8(m_first_avail);
	call DiagMsg.send();
    }
  }

  command void MsgBuffers.reset()
  {
    uint8_t old = m_first_avail;
    m_first_avail = 0; // think about what happens if free is called after this
    if( call DiagMsg.record() == SUCCESS )
    {
      call DiagMsg.str("reset buffers");
      call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
      call DiagMsg.uint8(old);
      call DiagMsg.send();
    }
  }

  event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg )
  {
    uint8_t cmd = msg->data[0];
    switch( cmd )
    {
      case 1: call MsgBuffers.report(); break;
      case 2: call MsgBuffers.reset(); break;
    }
    return msg;
  }
}

