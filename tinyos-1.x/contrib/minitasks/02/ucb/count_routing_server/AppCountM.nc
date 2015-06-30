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
// $Id: AppCountM.nc,v 1.15 2003/01/13 20:51:44 cssharp Exp $

includes Routing;
includes Neighbor;

module AppCountM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface Leds;
    interface Timer;
    interface RoutingSendByBroadcast;
    interface RoutingSendByAddress;
    interface RoutingSendByLocation;
  }
}
implementation
{
  uint8_t m_count;
  uint8_t m_sending_mode;
  TOS_Msg m_msg;
  bool m_is_sending;

  command result_t StdControl.init()
  {
    m_count = 0;
    m_sending_mode = 0;
    m_is_sending = FALSE;
    return call Leds.init();
  }

  command result_t StdControl.start()
  {
    if( call Timer.start( TIMER_REPEAT, 500 ) == FALSE )
      return FAIL;
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  uint8_t leds_set_u8( uint8_t n )
  {
    if(n&1) call Leds.redOn(); else call Leds.redOff();
    if(n&2) call Leds.greenOn(); else call Leds.greenOff();
    if(n&4) call Leds.yellowOn(); else call Leds.yellowOff();
    return n;
  }

  uint8_t routing_send_u8( uint8_t n )
  {
    if( m_is_sending == FALSE )
    {
      result_t success = FAIL;
      *(uint8_t*)initRoutingMsg( &m_msg, 1 ) = n;

      //switch( (TOS_LOCAL_ADDRESS >> 8) & 0x0f )
      switch( m_sending_mode )
      {
	case 1: // send to address 0xXX00
	  success = call RoutingSendByAddress.send( TOS_LOCAL_ADDRESS & 0xff00, &m_msg );
	  m_sending_mode = 2;
	  break;

	case 2: // send to location 0
	{
	  RoutingLocation_t loc = { pos : {x:0, y:0, z:0}, radius:{x:0, y:0, z:0} };
	  success = call RoutingSendByLocation.send( &loc, &m_msg );
	  m_sending_mode = 0;
	  break;
	}

	default: // broadcast
	  success = call RoutingSendByBroadcast.send( 1, &m_msg );
	  m_sending_mode = 1;
      }

      m_is_sending = (success == SUCCESS);
    }

    return n;
  }

  event result_t Timer.fired()
  {
    routing_send_u8( leds_set_u8( ++m_count ) );
    //routing_send_u8( ++m_count );
    return SUCCESS;
  }


  event result_t RoutingSendByBroadcast.sendDone( TOS_MsgPtr msg, result_t success )
  {
    m_is_sending = FALSE;
    return SUCCESS;
  }


  event result_t RoutingSendByAddress.sendDone( TOS_MsgPtr msg, result_t success )
  {
    m_is_sending = FALSE;
    return SUCCESS;
  }


  event result_t RoutingSendByLocation.sendDone( TOS_MsgPtr msg, result_t success )
  {
    m_is_sending = FALSE;
    return SUCCESS;
  }
}

