//$Id: RadioDemoM.nc,v 1.1.1.1 2007/11/05 19:08:59 jpolastre Exp $

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
 *
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 */

/**
 * @author Cory Sharp <info@moteiv.com>
 */

#include "CountMsg.h"

module RadioDemoM
{
  provides interface StdControl;
  uses interface Timer;
  uses interface Leds;
  uses interface SendMsg;
  uses interface ReceiveMsg;
  uses interface Button;
}
implementation
{
  uint16_t m_count;
  uint16_t m_lqi;
  uint16_t m_rssi;
  TOS_Msg m_msg;
  bool m_is_sending;
  uint16_t m_timeout;
  
  uint16_t m_mode;

  enum {
    MODE_COUNT_RADIO,
    MODE_EXCHANGE_RSSI,
    MODE_EXCHANGE_LQI,
    PERIOD_COUNT_RADIO = 333,
    PERIOD_EXCHANGE_RSSI = 33,
    PERIOD_EXCHANGE_LQI = 33,
    TIMEOUT_EXCHANGE_RSSI = 100,
    TIMEOUT_EXCHANGE_LQI = 100,
  };


  command result_t StdControl.init()
  {
    m_count = 0;
    m_lqi = 0;
    m_timeout = 0;
    m_is_sending = FALSE;
    m_mode = MODE_COUNT_RADIO;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Button.enable();
    m_mode = MODE_COUNT_RADIO;
    if( TOS_LOCAL_ADDRESS == 1 )
      call Timer.start( TIMER_REPEAT, PERIOD_COUNT_RADIO );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  void sendCount( uint16_t count )
  {
    if( m_is_sending == FALSE )
    {
      CountMsg_t* body = (CountMsg_t*)m_msg.data;
      body->n = count;
      body->src = 10000 + m_mode;
      if( call SendMsg.send(TOS_BCAST_ADDR,sizeof(CountMsg_t),&m_msg) == SUCCESS )
      {
	m_is_sending = TRUE;
      }
    }
  }

  event result_t Timer.fired()
  {
    if( TOS_LOCAL_ADDRESS == 1 )
    {
      m_count++;

      switch( m_mode )
      {
	case MODE_COUNT_RADIO:
	  call Leds.set( m_count );
	  break;
	
	case MODE_EXCHANGE_RSSI:
	case MODE_EXCHANGE_LQI:
	  if( m_timeout == 0 )
	    call Leds.set(0);
	  if( m_timeout > 0 )
	    m_timeout--;
	  break;
      }

      sendCount( m_count );
    }
    else
    {
      // timeout for address != 1
      call Leds.set(0);
    }
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t result)
  {
    m_is_sending = FALSE;
    return SUCCESS;
  }

  task void processLQI()
  {
    uint16_t leds = 1;
    if( m_lqi >= 85 ) leds |= 2;
    if( m_lqi >= 106 ) leds |= 4;
    call Leds.set( leds );
  }

  task void processRSSI()
  {
    uint16_t leds = 1;
    if( m_rssi >= 20 ) leds |= 2; //prev 15
    if( m_rssi >= 40 ) leds |= 4; //prev 35
    call Leds.set( leds );
  }

  event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg )
  {
    CountMsg_t* body = (CountMsg_t*)msg->data;
    if( body->src >= 10000 )
    {
      if( TOS_LOCAL_ADDRESS == 1 )
      {
	m_timeout = (TIMEOUT_EXCHANGE_LQI + PERIOD_EXCHANGE_LQI - 1) / PERIOD_EXCHANGE_LQI;
	m_lqi = msg->lqi;
	post processLQI();
      }
      else
      {
	m_mode = body->src - 10000;
	switch( m_mode )
	{
	  case MODE_COUNT_RADIO:
	    m_count = body->n;
	    call Leds.set( m_count );
	    call Timer.stop(); //stop timeout
	    break;

	  case MODE_EXCHANGE_RSSI:
	    call Timer.start( TIMER_ONE_SHOT, TIMEOUT_EXCHANGE_RSSI ); //timeout
	    m_rssi  = (msg->strength + 60) & 255;
	    post processRSSI();
	    sendCount( m_count );
	    break;

	  case MODE_EXCHANGE_LQI:
	    call Timer.start( TIMER_ONE_SHOT, TIMEOUT_EXCHANGE_LQI ); //timeout
	    m_lqi = msg->lqi;
	    post processLQI();
	    sendCount( m_count );
	    break;
	}
      }
    }
    return msg;
  }

  task void switchMode()
  {
    switch( m_mode )
    {
      case MODE_COUNT_RADIO:
	m_mode = MODE_EXCHANGE_RSSI;
	call Timer.start( TIMER_REPEAT, PERIOD_EXCHANGE_RSSI );
	break;

      case MODE_EXCHANGE_RSSI:
	m_mode = MODE_EXCHANGE_LQI;
	call Timer.start( TIMER_REPEAT, PERIOD_EXCHANGE_LQI );
	break;

      case MODE_EXCHANGE_LQI:
      default:
	m_mode = MODE_COUNT_RADIO;
	call Timer.start( TIMER_REPEAT, PERIOD_COUNT_RADIO );
	break;
    }
  }

  async event void Button.pressed(uint32_t time) {
    if( TOS_LOCAL_ADDRESS == 1 )
      post switchMode();
  }

  async event void Button.released(uint32_t time) { }
}

