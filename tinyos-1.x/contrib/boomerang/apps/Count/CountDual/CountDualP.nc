// $Id: CountDualP.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "../CountMsg.h"

/**
 * Implementation of CountDual.
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
module CountDualP {
  provides interface StdControl;
  uses interface Timer2<TMilli> as Timer;
  uses interface SendMsg;
  uses interface ReceiveMsg;
  uses interface Leds;
}
implementation
{
  TOS_Msg m_msg;
  uint16_t m_count;
  bool m_sending;

  command result_t StdControl.init() {
    m_count = 0;
    m_sending = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    if( TOS_LOCAL_ADDRESS == 1 )
      call Timer.startPeriodic( 200 );
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void Timer.fired() {
    if( m_sending == FALSE ) {
      CountMsg_t* body = (CountMsg_t*)m_msg.data;
      body->n = m_count;
      body->src = TOS_LOCAL_ADDRESS;
      if( call SendMsg.send( TOS_BCAST_ADDR, sizeof(CountMsg_t), &m_msg ) == SUCCESS ) {
	call Leds.set( m_count );
	m_sending = TRUE;
      }
    }
    m_count++;
  }

  event result_t SendMsg.sendDone( TOS_MsgPtr msg, result_t success ) {
    m_sending = FALSE;
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg ) {
    if( TOS_LOCAL_ADDRESS != 1 ) {
      CountMsg_t* body = (CountMsg_t*)(&msg->data[0]);
      call Leds.set( body->n );
    }
    return msg;
  }
}

