//$Id: GlowLedsM.nc,v 1.6 2005/07/29 22:35:43 jpolastre Exp $

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

module GlowLedsM
{
  provides interface StdControl;
  uses interface Timer;
  uses interface LedsIntensity;
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

    NO_LED = 4,
    CYCLE_END = 5,
  };

  const int8_t m_cycle[] = {
    0, 1, 2, NO_LED, NO_LED, NO_LED, NO_LED, NO_LED, NO_LED,
    2, 1, 0, NO_LED, NO_LED, NO_LED, NO_LED, NO_LED, NO_LED,
    CYCLE_END,
  };

  uint8_t m_delay_count;
  uint8_t m_cycle_count;

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

  event result_t Timer.fired()
  {
    if( ++m_delay_count >= MAX_DELAY_COUNT )
    {
      m_delay_count = 0;

      if( m_cycle[m_cycle_count] < NO_LED )
	m_state[m_cycle[m_cycle_count]] = LED_UP;

      if( m_cycle[++m_cycle_count] == CYCLE_END )
	m_cycle_count = 0;
    }

    incLeds();

    return SUCCESS;
  }
}

