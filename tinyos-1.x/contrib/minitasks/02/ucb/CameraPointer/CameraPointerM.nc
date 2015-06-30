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
// $Id: CameraPointerM.nc,v 1.2 2003/01/31 21:11:32 cssharp Exp $

includes common_structs;
includes Localization;
includes CameraPointer;
includes Config;

//!! Config 10 { Triple_float_t CameraPointer_pos = { x:90, y:-20, z:60 }; }
//!! Config 11 { Triple_float_t CameraPointer_rot = { x:-45, y:0, z:0 }; }
//!! Config 12 { float CameraPointer_world_scale = 22.5; }
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
    interface RoutingReceive;
    interface Config_CameraPointer_pos;
    interface Config_CameraPointer_rot;
    interface Config_CameraPointer_zoom_scale;
  }
}
implementation
{
  CameraPointer_t m_point;
  bool m_is_new_point;
  bool m_in_pantilt;


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
    Triple_float_t world;

    call Leds.yellowToggle();

    if( (m_in_pantilt == TRUE) || (m_is_new_point == FALSE) )
      return;

    m_in_pantilt = TRUE;

    world.x = G_Config.CameraPointer_world_scale * m_point.x;
    world.y = G_Config.CameraPointer_world_scale * m_point.y;
    world.z = G_Config.CameraPointer_world_scale * m_point.z;

    if( call PTZCameraWorld.pantilt_to( &world ) == SUCCESS )
      m_is_new_point = FALSE;
    else
      m_in_pantilt = FALSE;
  }


  task void task_pantilt()
  {
    pantilt_to_estimate();
  }


  event TOS_MsgPtr RoutingReceive.receive( TOS_MsgPtr msg )
  {
    CameraPointer_t* head = (CameraPointer_t*)popFromRoutingMsg( msg, sizeof(CameraPointer_t) );
    call Leds.redToggle();
    if( head == 0 ) return msg;
    m_point = *head;
    m_is_new_point = TRUE;
    if( m_in_pantilt == FALSE )
      post task_pantilt();
    return msg;
  }


  command result_t StdControl.init()
  {
    call PTZCameraStdControl.init();
    call Leds.init();
    m_is_new_point = FALSE;
    m_in_pantilt = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    update_camera_config();
    call PTZCameraStdControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call PTZCameraStdControl.stop();
    return SUCCESS;
  }


  event result_t PTZCameraWorld.cmd_done( result_t success )
  {
    call Leds.greenToggle();
    m_in_pantilt = FALSE;
    if( m_is_new_point == TRUE )
      post task_pantilt();
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

