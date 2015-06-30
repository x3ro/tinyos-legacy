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
// $Id: CameraTestM.nc,v 1.1 2003/01/24 20:03:46 cssharp Exp $

includes common_structs;

module CameraTestM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface Leds;
    interface PTZCameraWorld;
    interface Timer;
    interface StdControl as PTZCameraStdControl;
  }
}
implementation
{
  float m_world_scale;

  ptzcamera_config_t camera_config()
  {
    const ptzcamera_config_t config = {
      pos : { x:48, y:-24, z:48 },
      rot : { x:-45, y:0, z:0 },
      zoom_scale : 1.0/60.0,
    };

    m_world_scale = 24;

    return config;
  }

  ptzcamera_config_t m_camera_config;
  uint8_t m_state;
  bool m_in_pantilt;

  void int_to_leds( uint8_t n )
  {
    if(n&1) call Leds.redOn(); else call Leds.redOff();
    if(n&2) call Leds.greenOn(); else call Leds.greenOff();
    if(n&4) call Leds.yellowOn(); else call Leds.yellowOff();
  }


  task void pantilt()
  {
    const Triple_uint8_t path[] = {
      {0,0,0}, {1,0,0}, {2,0,0}, {3,0,0},
      {4,0,0}, {4,1,0}, {4,2,0}, {4,3,0},
      {4,4,0}, {3,4,0}, {2,4,0}, {1,4,0},
      {0,4,0}, {0,3,0}, {0,2,0}, {0,1,0},
    };

    Triple_float_t world = { 
	x : path[m_state].x * m_world_scale,
	y : path[m_state].y * m_world_scale,
	z : path[m_state].z * m_world_scale,
      };

    call Leds.redToggle();

    if( call PTZCameraWorld.pantilt_to( &world ) == SUCCESS )
    {
      m_in_pantilt = TRUE;
      if( ++m_state >= 16 )
	m_state = 0;
    }
  }


  command result_t StdControl.init()
  {
    call PTZCameraStdControl.init();
    call Leds.init();
    m_camera_config = camera_config();
    m_state = 0;
    m_in_pantilt = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call PTZCameraWorld.set_camera_config( &m_camera_config );
    call PTZCameraStdControl.start();
    call Timer.start( TIMER_REPEAT, 1000 );
    post pantilt();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call PTZCameraStdControl.stop();
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    if( m_in_pantilt == FALSE )
      post pantilt();
    return SUCCESS;
  }

  event result_t PTZCameraWorld.cmd_done( result_t success )
  {
    post pantilt();
    return SUCCESS;
  }
}

