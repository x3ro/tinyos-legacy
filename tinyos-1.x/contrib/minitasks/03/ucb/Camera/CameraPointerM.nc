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
// $Id: CameraPointerM.nc,v 1.2 2003/10/04 00:22:40 cssharp Exp $

includes common_structs;
includes Localization;
includes CameraPointer;
includes Config;
includes MagCenter;

//!! Config 10 { Triple_float_t CameraPointer_pos = { x:68, y:-78, z:89 }; }
//!! Config 11 { Triple_float_t CameraPointer_rot = { x:-33.6, y:0, z:0 }; }
//!! Config 12 { float CameraPointer_world_scale = 1; }
//!! Config 13 { float CameraPointer_zoom_scale = (1.0/60.0); }

module CameraPointerM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface Leds;
    interface PTZCameraWorld;
    interface StdControl as PTZCameraStdControl;
    interface Config_CameraPointer_pos;
    interface Config_CameraPointer_rot;
    interface Config_CameraPointer_zoom_scale;

    interface RoutingReceive as ReceiveTriple;
    interface RoutingReceive as ReceiveMagBroadcast;
    interface ERoute as ReceiveMagCroute;
  }
}
implementation
{
  CameraPointer_t m_point;
  MagLeaderReport_t m_magreport;
  bool m_is_new_point;
  bool m_in_pantilt;
  bool m_is_running;

  void update_camera_config()
  {
    const ptzcamera_config_t config = {
      pos : G_Config.CameraPointer_pos,
      rot : G_Config.CameraPointer_rot,
      zoom_scale : G_Config.CameraPointer_zoom_scale,
    };

    call PTZCameraWorld.set_camera_config( &config );
  }


  void pantilt_to_estimate()
  {
    if( m_is_running )
    {
      Triple_float_t world;

      if( (m_in_pantilt == TRUE) || (m_is_new_point == FALSE) )
	return;

      call Leds.yellowToggle();

      m_in_pantilt = TRUE;
      m_is_new_point = FALSE;

      world.x = G_Config.CameraPointer_world_scale * m_point.x;
      world.y = G_Config.CameraPointer_world_scale * m_point.y;
      world.z = G_Config.CameraPointer_world_scale * m_point.z;

      if( call PTZCameraWorld.pantilt_to( &world ) != SUCCESS )
      {
	m_in_pantilt = FALSE;
	m_is_new_point = TRUE;
      }
    }
  }


  task void task_pantilt()
  {
    if( m_is_running )
    {
      pantilt_to_estimate();
    }
  }

  task void task_magreport()
  {
    if( m_is_running )
    {
      m_point.x = (float)m_magreport.x_sum / ( 256.0 * (float)m_magreport.mag_sum );
      m_point.y = (float)m_magreport.y_sum / ( 256.0 * (float)m_magreport.mag_sum );
      m_point.z = 0;
      pantilt_to_estimate();
    }
  }


  event TOS_MsgPtr ReceiveTriple.receive( TOS_MsgPtr msg )
  {
    if( m_is_running )
    {
      CameraPointer_t* body = (CameraPointer_t*)popFromRoutingMsg( msg, sizeof(CameraPointer_t) );
      call Leds.redToggle();
      if( body == 0 ) return msg;
      m_point = *body;
      m_is_new_point = TRUE;
      if( m_in_pantilt == FALSE )
	post task_pantilt();
    }
    return msg;
  }

  void receive_MagLeaderReport( MagLeaderReport_t* report )
  {
    if( m_is_running )
    {
      m_magreport = *report;
      m_is_new_point = TRUE;
      if( m_in_pantilt == FALSE )
	post task_magreport();
    }
  }

  event TOS_MsgPtr ReceiveMagBroadcast.receive( TOS_MsgPtr msg )
  {
    if( m_is_running )
    {
      MagLeaderReport_t* body = (MagLeaderReport_t*)popFromRoutingMsg( msg, sizeof(MagLeaderReport_t) );
      call Leds.redToggle();
      if( body != 0 )
	receive_MagLeaderReport( body );
    }
    return msg;
  }

  event result_t ReceiveMagCroute.receive( EREndpoint dest, uint8_t datalen, uint8_t* data )
  {
    if( m_is_running )
    {
      if( datalen == sizeof(MagLeaderReport_t) )
	receive_MagLeaderReport( (MagLeaderReport_t*)data );
      return SUCCESS;
    }
  }

  event result_t ReceiveMagCroute.sendDone( EREndpoint dest, uint8_t * data )
  {
    return SUCCESS;
  }


  command result_t StdControl.init()
  {
    call PTZCameraStdControl.init();
    call Leds.init();
    m_is_new_point = FALSE;
    m_in_pantilt = FALSE;
    m_is_running = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    update_camera_config();
    call PTZCameraStdControl.start();
    m_is_running = TRUE;
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    m_is_running = FALSE;
    call PTZCameraStdControl.stop();
    return SUCCESS;
  }


  event result_t PTZCameraWorld.cmd_done( result_t success )
  {
    if( m_is_running )
    {
      call Leds.greenToggle();
      m_in_pantilt = FALSE;
      if( m_is_new_point == TRUE )
	post task_pantilt();
    }
    return SUCCESS;
  }


  event void Config_CameraPointer_pos.updated()
  {
    update_camera_config();
  }

  event void Config_CameraPointer_rot.updated()
  {
    update_camera_config();
  }

  event void Config_CameraPointer_zoom_scale.updated()
  {
    update_camera_config();
  }
}

