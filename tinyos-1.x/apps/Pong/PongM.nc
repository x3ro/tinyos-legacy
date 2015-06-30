// $Id: PongM.nc,v 1.1 2004/06/21 20:00:49 jpolastre Exp $

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

includes PongMsg;
includes Timer;

module PongM
{
  provides interface StdControl;
  uses interface Timer;
  uses interface SendMsg;
  uses interface ReceiveMsg;
  uses interface ReceiveMsg as PingMsg;
  uses interface Leds;
}
implementation
{
  TOS_Msg m_msg;
  TOS_MsgPtr p_msg;
  PongMsg_t* pongmsg;
  int m_int;
  bool m_sending;

  command result_t StdControl.init()
  {
    m_int = 0;
    m_sending = FALSE;
    pongmsg = (PongMsg_t*)m_msg.data;
    p_msg = &m_msg;
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    if (TOS_LOCAL_ADDRESS == 1) {
//      call Timer.start(TIMER_REPEAT, 2000);
    }
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  event result_t Timer.fired()
  {      
      call Leds.redToggle();
      pongmsg->src = TOS_LOCAL_ADDRESS;
      if (call SendMsg.send(TOS_BCAST_ADDR, sizeof(PongMsg_t), p_msg)) {
      }

    return SUCCESS;
  }

  event result_t SendMsg.sendDone( TOS_MsgPtr msg, result_t success )
  {
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg )
  {
    PongMsg_t* _pongmsg;
    call Leds.greenToggle();
    _pongmsg = (PongMsg_t*)msg->data;
    if( _pongmsg->src != TOS_LOCAL_ADDRESS )
    {
        pongmsg->src = _pongmsg->src;
        pongmsg->src_rssi = msg->strength;
        pongmsg->src_lqi = msg->lqi;
	pongmsg->dest = TOS_LOCAL_ADDRESS;
        call SendMsg.send(_pongmsg->src, sizeof(PongMsg_t), p_msg);
    }
    else {
        // send to UART
        call Leds.yellowToggle();
        pongmsg->src = _pongmsg->src;
        pongmsg->src_rssi = _pongmsg->src_rssi;
        pongmsg->src_lqi = _pongmsg->src_lqi;
	pongmsg->dest = _pongmsg->dest;
        pongmsg->dest_rssi = msg->strength;
        pongmsg->dest_lqi = msg->lqi;
        call SendMsg.send(TOS_UART_ADDR, sizeof(PongMsg_t), p_msg);
    }
    return msg;
  }

  event TOS_MsgPtr PingMsg.receive( TOS_MsgPtr msg )
  {
    PingMsg_t* pingmsg = (PingMsg_t*)(msg->data);
    if (pingmsg->src == TOS_UART_ADDR) {
      call Leds.redToggle();
      pongmsg->src = TOS_LOCAL_ADDRESS;
      if (call SendMsg.send(TOS_BCAST_ADDR, sizeof(PongMsg_t), p_msg)) {
        call Leds.greenToggle();
      }
    }
    return msg;
  }
}

