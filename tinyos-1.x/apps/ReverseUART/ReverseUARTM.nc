// $Id: ReverseUARTM.nc,v 1.2 2005/07/12 07:38:43 cssharp Exp $

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

module ReverseUARTM
{
  provides interface StdControl;
  uses interface SendMsg;
  uses interface ReceiveMsg;
  uses interface Leds;
}
implementation
{
  TOS_Msg m_msg;
  bool m_sending;

  command result_t StdControl.init()
  {
    m_sending = FALSE;
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

  event result_t SendMsg.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call Leds.greenToggle();
    m_sending = FALSE;
    return SUCCESS;
  }

  task void sendMsg()
  {
    if( call SendMsg.send( TOS_UART_ADDR, m_msg.length, &m_msg ) == FAIL )
      m_sending = FALSE;
  }

  int szLen( int8_t* data, int maxlen )
  {
    int i;
    for( i=0; i<maxlen; i++ )
    {
      if( data[i] == 0 )
	return i;
    }
    return maxlen;
  }

  event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg )
  {
    call Leds.redToggle();
    if( m_sending == FALSE )
    {
      const int n = szLen( msg->data, sizeof(msg->data) ) - 1;
      int i;

      m_msg.data[n+1] = 0;

      for( i=0; i<=n; i++ )
	m_msg.data[n-i] = msg->data[i];

      m_msg.length = msg->length;

      if( post sendMsg() == TRUE )
	m_sending = TRUE;
    }
    return msg;
  }
}

