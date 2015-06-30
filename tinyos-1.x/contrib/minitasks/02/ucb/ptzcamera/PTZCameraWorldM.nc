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
// $Id: PTZCameraWorldM.nc,v 1.3 2003/01/24 20:00:39 cssharp Exp $

module PTZCameraWorldM
{
  provides
  {
    interface PTZCameraWorld;
    interface StdControl;
  }
  uses
  {
    interface PTZCmdPantilt;
    interface PTZCmdZoom;
    interface StdControl as PTZCameraCommStdControl;
  }
}
implementation
{
  ptzcamera_config_t default_camera_config()
  {
    const ptzcamera_config_t config = {
      pos : { x:48, y:-24, z:60 },
      rot : { x:-45, y:0, z:0 },
      zoom_scale : 1.0/60.0,
    };
    return config;
  }

  ptzcamera_config_t m_camera_config;
  ptzcamera_affine_t m_ax;
  ptzcamera_affine_t m_ay;
  ptzcamera_affine_t m_az;

  ptzcamera_pantilt_t m_pantilt;

  bool m_have_new_pantilt;
  bool m_have_new_zoom;
  bool m_is_pantilt_pending;
  bool m_is_zoom_pending;
  bool m_is_sending;



  void init_affine()
  {
    const float D2R = M_PI / 180.0;
    const float Cx = cos( m_camera_config.rot.x * D2R );
    const float Cy = cos( m_camera_config.rot.y * D2R );
    const float Cz = cos( m_camera_config.rot.z * D2R );
    const float Sx = sin( m_camera_config.rot.x * D2R );
    const float Sy = sin( m_camera_config.rot.y * D2R );
    const float Sz = sin( m_camera_config.rot.z * D2R );
    const float x0 = m_camera_config.pos.x;
    const float y0 = m_camera_config.pos.y;
    const float z0 = m_camera_config.pos.z;

    m_ax.x =  Cz*Cy;
    m_ax.y =  Sz*Cy;
    m_ax.z = -Sy;
    m_ax.b =  Sy*z0 - Cy*y0*Sz - Cy*x0*Cz;

    m_ay.x = -Sz*Cx + Cz*Sy*Sx;
    m_ay.y =  Cz*Cx + Sz*Sy*Sx;
    m_ay.z =  Cy*Sx;
    m_ay.b = -Cy*z0*Sx - Sy*y0*Sz*Sx - Cz*y0*Cx - Sy*x0*Cz*Sx + x0*Sz*Cx;

    m_az.x =  Sz*Sx + Cz*Sy*Cx;
    m_az.y = -Cz*Sx + Sz*Sy*Cx;
    m_az.z =  Cy*Cx;
    m_az.b = -Cy*z0*Cx - Sy*y0*Sz*Cx + y0*Cz*Sx - Sy*x0*Cz*Cx - x0*Sz*Sx;
  }


  command void PTZCameraWorld.set_camera_config( const ptzcamera_config_t* config )
  {
    m_camera_config = *config;
    init_affine();
  }


  void calc_pantilt( const Triple_float_t* w )
  {
    const float cx = m_ax.x*w->x + m_ax.y*w->y + m_ax.z*w->z + m_ax.b;
    const float cy = m_ay.x*w->x + m_ay.y*w->y + m_ay.z*w->z + m_ay.b;
    const float cz = m_az.x*w->x + m_az.y*w->y + m_az.z*w->z + m_az.b;
    const float ch = sqrt( cx*cx + cy*cy );
    // Bugs! AVR's atan2 is atan2(x,y), *not* the canonical atan2(y,x)
    m_pantilt.pan = atan2( cy, cx );
    m_pantilt.tilt = atan2( ch, cz );
    m_pantilt.dist = sqrt( cx*cx + cy*cy + cz*cz );
    m_have_new_pantilt = TRUE;
    m_have_new_zoom = (m_camera_config.zoom_scale != 0);
  }


  command const ptzcamera_pantilt_t* PTZCameraWorld.calc_pantilt( const Triple_float_t* world )
  {
    calc_pantilt( world );
    return &m_pantilt;
  }


  bool do_pantilt()
  {
    if( (m_have_new_pantilt == TRUE)
        && (m_is_sending == FALSE)
	&& (m_is_pantilt_pending == FALSE)
      )
    {
      if( call PTZCmdPantilt.set_abs_rad( m_pantilt.pan, m_pantilt.tilt ) == SUCCESS )
      {
	m_have_new_pantilt = FALSE;
	m_is_sending = TRUE;
	m_is_pantilt_pending = TRUE;
	return TRUE;
      }
    }
    return FALSE;
  }


  bool do_zoom()
  {
    if( (m_have_new_zoom == TRUE)
        && (m_is_sending == FALSE)
        && (m_is_zoom_pending == FALSE)
      )
    {
      float zoom = m_pantilt.dist * m_camera_config.zoom_scale;
      if( call PTZCmdZoom.set_abs_factor( zoom ) == SUCCESS )
      {
	m_have_new_zoom = FALSE;
	m_is_sending = TRUE;
	m_is_zoom_pending = TRUE;
	return TRUE;
      }
    }
    return FALSE;
  }


  command result_t PTZCameraWorld.pantilt_to( const Triple_float_t* world )
  {
    calc_pantilt( world );
    return (do_pantilt() || do_zoom()) ? SUCCESS : FAIL;
  }


  event result_t PTZCmdPantilt.cmd_ack( result_t success )
  {
    m_is_sending = FALSE;
    do_zoom();
    return SUCCESS;
  }

  event result_t PTZCmdPantilt.cmd_done( result_t success )
  {
    m_is_pantilt_pending = FALSE;
    do_zoom();
    if( m_is_zoom_pending == FALSE )
      signal PTZCameraWorld.cmd_done( success );
    return SUCCESS;
  }


  event result_t PTZCmdZoom.cmd_ack( result_t success )
  {
    m_is_sending = FALSE;
    do_pantilt();
    return SUCCESS;
  }

  event result_t PTZCmdZoom.cmd_done( result_t success )
  {
    m_is_zoom_pending = FALSE;
    do_pantilt();
    if( m_is_pantilt_pending == FALSE )
      signal PTZCameraWorld.cmd_done( success );
    return SUCCESS;
  }


  command result_t StdControl.init()
  {
    call PTZCameraCommStdControl.init();
    m_have_new_pantilt = FALSE;
    m_have_new_zoom = FALSE;
    m_is_pantilt_pending = FALSE;
    m_is_zoom_pending = FALSE;
    m_is_sending = FALSE;
    m_camera_config = default_camera_config();
    init_affine();
    return SUCCESS;
  }


  command result_t StdControl.start()
  {
    call PTZCameraCommStdControl.start();
    return SUCCESS;
  }


  command result_t StdControl.stop()
  {
    call PTZCameraCommStdControl.stop();
    return SUCCESS;
  }
}

