// $Id: SerialIDSendM.nc,v 1.2 2004/11/08 00:26:11 cssharp Exp $

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

module SerialIDSendM
{
  provides interface StdControl;
  uses interface Timer;
  uses interface SendMsg;
  uses interface Leds;
  uses interface DS2411;
}
implementation
{
  TOS_Msg m_msg;
  int m_int;
  bool m_sending;

  typedef struct SerialIDMsg
  {
    uint16_t src;
    uint8_t id[8];
  } SerialIDMsg;

  command result_t StdControl.init()
  {
    m_sending = FALSE;
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Timer.start( TIMER_REPEAT, 1000 );
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
      SerialIDMsg* body = (SerialIDMsg*)m_msg.data;
      body->src = TOS_LOCAL_ADDRESS;
      // serial id only needs to be initialized once, but I'm initializing it here
      // before send to check for the frequency of 1-wire errors
      call DS2411.init();
      call DS2411.copy_id( &(body->id[1]) );
      body->id[0] = call DS2411.get_crc();
      body->id[7] = call DS2411.get_family();
      if( call SendMsg.send( TOS_BCAST_ADDR, sizeof(SerialIDMsg), &m_msg ) == SUCCESS )
      {
	m_sending = TRUE;
	call Leds.redToggle();
      }
    }
    return SUCCESS;
  }

  event result_t SendMsg.sendDone( TOS_MsgPtr msg, result_t success )
  {
    m_sending = FALSE;
    return SUCCESS;
  }
}

