//$Id: OscopeM.nc,v 1.1.1.1 2007/11/05 19:09:15 jpolastre Exp $

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

includes Oscope;

module OscopeM
{
  provides interface StdControl;
  provides interface Oscope[uint8_t channel];
  uses interface SendMsg as DataMsg;
  uses interface ReceiveMsg as ResetCounterMsg;
}
implementation
{
  enum
  {
    MAX_CHANNELS = OSCOPE_MAX_CHANNELS,
    BUFFER_SIZE = OSCOPE_BUFFER_SIZE,
  };

  typedef struct
  {
    uint8_t index;
    bool send_data_ready;
    uint16_t lastCount;
    uint16_t count;
    uint16_t data[BUFFER_SIZE];
    uint16_t send_data[BUFFER_SIZE];
  } OscopeData_t;

  TOS_Msg m_msg;
  int m_is_sending;
  int m_send_next;

  OscopeData_t m_data[ MAX_CHANNELS ];

  // reset invoked on any one channel resets all channels.  The oscilloscope
  // visualization is really only useful when all channels are synchronized.

  command void Oscope.reset[uint8_t channel]()
  {
    OscopeData_t* ch = m_data+0;
    OscopeData_t* chend = m_data+MAX_CHANNELS;

    atomic
    {
      for( ; ch != chend; ch++ )
      {
	ch->index = 0;
	ch->send_data_ready = FALSE;
	ch->count = 0;
      }
    }

    m_send_next = 0;
    m_is_sending = FALSE;
  }

  command result_t StdControl.init()
  {
    call Oscope.reset[MAX_CHANNELS]();
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

  // sendHelper and sendHelperTask post tasks to retry sending a packet until
  // DataMsg.send returns SUCCESS.  It's guarded by m_is_sending so that a call
  // to Oscope.reset() also flushes any pending sendHelperTask.

  void sendHelper();
  task void sendHelperTask()
  {
    sendHelper();
  }

  void sendHelper()
  {
    if( m_is_sending == TRUE )
    {
      if( call DataMsg.send( TOS_BCAST_ADDR, sizeof(OscopeMsg_t), &m_msg ) == FAIL )
      {
	if( post sendHelperTask() == FALSE )
	  m_is_sending = FALSE; //the task didn't post, nothing to do but drop the msg
      }
    }
  }

  int channel_inc( int ch, int inc )
  {
    ch += inc;
    if( ch >= MAX_CHANNELS )
      ch -= MAX_CHANNELS;
    return ch;
  }

  // send tries to be a little fair by transmitting pending channels round
  // robin instead of possibly letting one channel starve another.  Also, as
  // soon as a pending channel is found, its data is stuffed into the local
  // TOS_Msg.  The channel is then allowed to aggregate new, additional data,
  // possibly before the message is sent.

  task void send()
  {
    if( m_is_sending == FALSE )
    {
      int i;
      OscopeData_t* chbegin = m_data + 0;
      OscopeData_t* chend = m_data + MAX_CHANNELS;
      OscopeData_t* ch = m_data + m_send_next;

      for( i=0; i<MAX_CHANNELS; i++ )
      {
	if( ch->send_data_ready == TRUE )
	{
	  OscopeMsg_t* body = (OscopeMsg_t*)m_msg.data;
	  int n = channel_inc( i, m_send_next );

	  body->sourceMoteID = TOS_LOCAL_ADDRESS;
	  body->lastSampleNumber = ch->lastCount;
	  body->channel = n;
	  memcpy( body->data, ch->send_data, sizeof(uint16_t)*BUFFER_SIZE );

	  ch->send_data_ready = FALSE;

	  m_is_sending = TRUE;
	  m_send_next = channel_inc( n, 1 );

	  sendHelper();
	  return; // a channel has been queued for send, get out of here
	}

	if( ++ch == chend )
	  ch = chbegin;
      }
    }
  }

  // When a message is done sending, mark the local TOS_Msg as free to use.
  // Post send again here in case another channel is pending to send, as well.

  event result_t DataMsg.sendDone( TOS_MsgPtr msg, result_t success )
  {
    m_is_sending = FALSE;
    post send();
    return SUCCESS;
  }

  // put increments the reading count regardless if the value is ultimately
  // dropped or not -- this is appropriate.  Because of this, we have to save
  // the count as lastCount so that Oscilloscope can properly visualze in time
  // the aggregated data versus the dropped data.

  task void prepare_send_data()
  {
    OscopeData_t* ch = m_data + 0;
    OscopeData_t* chend = m_data + MAX_CHANNELS;

    for( ; ch != chend; ch++ )
    {
      atomic
      {
	if( ch->index >= BUFFER_SIZE )
	{
	  ch->lastCount = ch->count;
	  memcpy( ch->send_data, ch->data, sizeof(uint16_t)*BUFFER_SIZE );
	  ch->send_data_ready = TRUE;
	  ch->index = 0;
	  post send();
	}
      }
    }
  }

  async command result_t Oscope.put[uint8_t channel]( uint16_t value )
  {
    result_t rv = FAIL;
    atomic
    {
      if( channel < MAX_CHANNELS )
      {
	OscopeData_t* ch = &m_data[channel];
	ch->count++;
	if( ch->index < BUFFER_SIZE )
	{
	  ch->data[ ch->index++ ] = value;
	  if( ch->index >= BUFFER_SIZE )
	    post prepare_send_data();
	  rv = SUCCESS;
	}
      }
    }
    return rv;
  }

  event TOS_MsgPtr ResetCounterMsg.receive( TOS_MsgPtr msg )
  {
    call Oscope.reset[MAX_CHANNELS]();
    return msg;
  }
}

