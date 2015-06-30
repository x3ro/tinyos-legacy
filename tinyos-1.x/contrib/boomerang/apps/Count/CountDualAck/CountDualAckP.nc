// $Id: CountDualAckP.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

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
 * Implementation of CountDualAck.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module CountDualAckP {
  provides interface StdControl;
  uses interface Timer2<TMilli> as Timer;
  uses interface SPSend;
  uses interface SPReceive;
  uses interface Leds;
}
implementation
{
  TOS_Msg m_msg;
  sp_message_t m_spmsg;
  uint16_t m_count;
  bool m_sending;

#ifndef TOS_DEST_ADDRESS
#define TOS_DEST_ADDRESS 2
#endif

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
      if( call SPSend.sendAdv( &m_spmsg,
			       &m_msg,
			       SP_I_RADIO,
			       TOS_DEST_ADDRESS,
			       sizeof(CountMsg_t),
			       SP_FLAG_C_RELIABLE,
			       1
			       ) == SUCCESS ) {
	call Leds.set( m_count );
	m_sending = TRUE;
      }
      m_count++;
    }
  }

  event void SPSend.sendDone(sp_message_t *msg, sp_message_flags_t flags, sp_error_t error) {
    if (msg == &m_spmsg) {
      m_sending = FALSE;
      if (error != SP_SUCCESS)
	m_count--;
    }

  }

  event void SPReceive.receive(sp_message_t *spmsg, TOS_MsgPtr tosmsg, sp_error_t result) {
    if( TOS_LOCAL_ADDRESS != 1 ) {
      CountMsg_t* body = (CountMsg_t*)(&tosmsg->data[0]);
      call Leds.set( body->n );
    }
  }
}

