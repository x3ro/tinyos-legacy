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
// $Id: FloodRoutingM.nc,v 1.2 2003/02/03 23:48:18 cssharp Exp $

module FloodRoutingM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface Leds;
    interface RoutingSendByBroadcast;
  }
}
implementation
{
  uint8_t m_count;
  TOS_Msg m_msg;

  uint8_t leds_set_u8( uint8_t n )
  {
    if(n&1) call Leds.redOn(); else call Leds.redOff();
    if(n&2) call Leds.greenOn(); else call Leds.greenOff();
    if(n&4) call Leds.yellowOn(); else call Leds.yellowOff();
    return n;
  }

  task void send()
  {
    uint8_t* head = (uint8_t*)initRoutingMsg( &m_msg, 1 );
    *head = m_count;
    if( call RoutingSendByBroadcast.send( 255, &m_msg ) == FAIL )
    {
      post send();
      return;
    }
    leds_set_u8( m_count );
    m_count++;
  }

  event result_t RoutingSendByBroadcast.sendDone( TOS_MsgPtr msg, result_t success )
  {
    if( msg == &m_msg )
      post send();
  }


  command result_t StdControl.init()
  {
    m_count = 0;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    post send();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }
}



