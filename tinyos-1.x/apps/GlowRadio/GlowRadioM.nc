//$Id: GlowRadioM.nc,v 1.4 2005/07/29 22:37:49 jpolastre Exp $

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

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

module GlowRadioM
{
  provides interface StdControl;
  uses interface Timer;
  uses interface LedsIntensity;
  uses interface SendMsg;
  uses interface ReceiveMsg;
}
implementation
{
  int8_t m_acc[3];
  uint8_t m_state[3];

  enum {
    MAX_VAL = 32,
    MAX_DELAY_COUNT = 8,

    LED_OFF = 0,
    LED_UP = 1,
    LED_DOWN = 2,

    NO_LED = 3,
    CYCLE_END = 4,
  };

  const int8_t m_cycle[] = {
    0, 1, 2, NO_LED, NO_LED, NO_LED, NO_LED, NO_LED, NO_LED,
    2, 1, 0, NO_LED, NO_LED, NO_LED, NO_LED, NO_LED, NO_LED,
    CYCLE_END,
  };

  uint8_t m_delay_count;
  uint8_t m_cycle_count;

  typedef struct
  {
    uint8_t ledNum;
  } GlowMsg_t;

  TOS_Msg m_msg;
  bool m_is_sending;

  command result_t StdControl.init()
  {
    m_acc[0] = 0;
    m_acc[1] = 0;
    m_acc[2] = 0;
    m_state[0] = LED_OFF;
    m_state[1] = LED_OFF;
    m_state[2] = LED_OFF;
    m_delay_count = 0;
    m_cycle_count = 0;
    m_is_sending = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Timer.start( TIMER_REPEAT, 20 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  void incLeds()
  {
    int i;
    for( i=0; i<3; i++ )
    {
      switch( m_state[i] )
      {
	case LED_OFF:
	  break;
	case LED_UP:
	  if( ++m_acc[i] >= (MAX_VAL-1) )
	  {
	    m_acc[i] = (MAX_VAL-1);
	    m_state[i] = LED_DOWN;
	  }
	  call LedsIntensity.set( i, m_acc[i] << 3 );
	  break;
	case LED_DOWN:
	  if( --m_acc[i] <= 0 )
	  {
	    m_acc[i] = 0;
	    m_state[i] = LED_OFF;
	  }
	  call LedsIntensity.set( i, m_acc[i] << 3 );
	  break;
      }
    }
  }

  void cycleLeds()
  {
    if( ++m_delay_count >= MAX_DELAY_COUNT )
    {
      m_delay_count = 0;

      if( m_cycle[m_cycle_count] < NO_LED )
      {
	uint8_t ledNum = m_cycle[m_cycle_count];
	m_state[ledNum] = LED_UP;
	if( m_is_sending == FALSE )
	{
	  GlowMsg_t* body = (GlowMsg_t*)m_msg.data;
	  body->ledNum = ledNum;
	  if( call SendMsg.send( TOS_BCAST_ADDR, sizeof(GlowMsg_t), &m_msg ) == SUCCESS )
	    m_is_sending = TRUE;
	}
      }

      if( m_cycle[++m_cycle_count] == CYCLE_END )
	m_cycle_count = 0;
    }
  }

  event result_t Timer.fired()
  {
    if( TOS_LOCAL_ADDRESS == 1 )
      cycleLeds();
    incLeds();
    return SUCCESS;
  }

  event result_t SendMsg.sendDone( TOS_MsgPtr msg, result_t success )
  {
    m_is_sending = FALSE;
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg )
  {
    if( TOS_LOCAL_ADDRESS != 1 )
    {
      GlowMsg_t* body = (GlowMsg_t*)msg->data;
      if( body->ledNum < NO_LED )
	m_state[body->ledNum] = LED_UP;
    }
    return msg;
  }
}

