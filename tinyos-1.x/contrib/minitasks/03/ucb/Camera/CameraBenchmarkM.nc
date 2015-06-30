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
// $Id: CameraBenchmarkM.nc,v 1.1 2003/08/29 00:54:25 cssharp Exp $

module CameraBenchmarkM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface Leds;
    interface Timer;
    interface PTZCameraWorld;
    interface RoutingSendByAddress as Send;
  }
}
implementation
{
  ptzcamera_config_t camera_config()
  {
    const ptzcamera_config_t config = {
      pos : { x:48, y:-24, z:60 },
      rot : { x:-45, y:0, z:0 },
      zoom_scale : 1.0/60.0,
    };
    return config;
  }

  TOS_Msg m_msg;
  bool m_is_sending;

  typedef struct {
    int16_t wx;
    int16_t wy;
    int32_t pan;
    int32_t tilt;
  } header_t;


  int16_t bench_x;
  int16_t bench_y;
  bool bench_is_running;


  void do_benchmark()
  {
    Triple_float_t world = { x:bench_x, y:bench_y, z:0 };
    const ptzcamera_pantilt_t* pt = call PTZCameraWorld.calc_pantilt( &world );

    if( m_is_sending == FALSE )
    {
      header_t* head = (header_t*)initRoutingMsg( &m_msg, sizeof(header_t) );
      if( head != 0 )
      {
	int32_t scale = ((int32_t)1) << 30;
	head->wx = bench_x;
	head->wy = bench_y;
	head->pan = (int32_t)(pt->pan / M_PI * scale);
	head->tilt = (int32_t)(pt->tilt / M_PI * scale);
	if( call Send.send( TOS_UART_ADDR, &m_msg ) == SUCCESS )
	  m_is_sending = TRUE;
      }
    }

    if( ++bench_x > 5 )
    {
      bench_x = 0;
      if( ++bench_y > 5 )
	bench_y = 0;
    }

    bench_is_running = FALSE;
  }


  task void benchmark()
  {
    do_benchmark();
  }


  command result_t StdControl.init()
  {
    call Leds.init();
    call Leds.redOn();

    bench_x = 0;
    bench_y = 0;
    bench_is_running = FALSE;

    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    ptzcamera_config_t config = camera_config();
    call PTZCameraWorld.set_camera_config( &config );
    call Timer.start( TIMER_REPEAT, 32 );

    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    if( bench_is_running == FALSE )
    {
      bench_is_running = TRUE;
      post benchmark();

      call Leds.redToggle();
      call Leds.greenToggle();
    }
    return SUCCESS;
  }

  event result_t Send.sendDone( TOS_MsgPtr msg, result_t success )
  {
    m_is_sending = FALSE;
    call Leds.yellowToggle();
    return SUCCESS;
  }


  event result_t PTZCameraWorld.cmd_done( result_t success )
  {
    return SUCCESS;
  }
}

