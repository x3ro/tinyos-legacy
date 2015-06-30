// $Id: TelosADCM.nc,v 1.1 2004/11/22 02:33:13 cssharp Exp $

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

module TelosADCM
{
  provides interface StdControl;
  uses interface Timer;
  uses interface SendMsg;
  uses interface Leds;
  uses interface ADC;
  uses interface ADCControl;
}
implementation
{
  TOS_Msg m_msg;
  int m_int;
  bool m_sending;

  command result_t StdControl.init()
  {
    atomic m_int = 0;
    m_sending = FALSE;
    call Leds.init();
    call ADCControl.init();
    call ADCControl.bindPort( TOS_ADC_GIO0_PORT, TOSH_ACTUAL_ADC_GIO0_PORT );
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Timer.start( TIMER_REPEAT, 200 );
    call ADC.getData();
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
      int n;
      CountMsg_t* body = (CountMsg_t*)m_msg.data;
      atomic n = m_int;
      body->n = n;
      body->src = TOS_LOCAL_ADDRESS;
      if( call SendMsg.send( TOS_UART_ADDR, sizeof(CountMsg_t), &m_msg ) == SUCCESS )
      {
	call Leds.set( n >> 9 );
	m_sending = TRUE;
      }
    }
    call ADC.getData();
    return SUCCESS;
  }

  async event result_t ADC.dataReady( uint16_t data )
  {
    atomic m_int = data;
    return SUCCESS;
  }

  event result_t SendMsg.sendDone( TOS_MsgPtr msg, result_t success )
  {
    m_sending = FALSE;
    return SUCCESS;
  }
}

