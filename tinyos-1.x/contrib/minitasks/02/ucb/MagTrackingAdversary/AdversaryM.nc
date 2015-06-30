/* "Copyright (c) 2000-2002 The Regents of the University of California.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Authors: Cory Sharp
// $Id: AdversaryM.nc,v 1.2 2003/01/31 21:10:21 cssharp Exp $

includes common_structs;
includes MagHood;

module AdversaryM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface RoutingSendByBroadcast;
    interface Timer;
    interface Leds;
  }
}
implementation
{
  TOS_Msg m_msg;
  bool m_is_sending;

  task void send_message()
  {
    if( m_is_sending == FALSE )
    {
      Estimation_t* head = (Estimation_t*)initRoutingMsg( &m_msg, sizeof(Estimation_t) );
      if( head == 0 ) return;
      
      head->x = -10 * 256;
      head->y = -10 * 256;
      head->z = 0;

      if( call RoutingSendByBroadcast.send( 10, &m_msg ) == SUCCESS )
      {
	call Leds.greenToggle();
	m_is_sending = TRUE;
      }
    }
  }

  event result_t RoutingSendByBroadcast.sendDone( TOS_MsgPtr msg, result_t success )
  {
    if( success == SUCCESS )
      call Leds.yellowToggle();
    m_is_sending = FALSE;
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    call Leds.redToggle();
    post send_message();
    return SUCCESS;
  }


  command result_t StdControl.init()
  {
    call Leds.init();
    m_is_sending = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Timer.start( TIMER_REPEAT, 1000 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }
}

