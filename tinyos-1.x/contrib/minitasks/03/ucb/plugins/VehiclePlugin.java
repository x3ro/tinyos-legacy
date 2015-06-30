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
// $Id: VehiclePlugin.java,v 1.4 2003/07/10 17:56:40 cssharp Exp $

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

public class VehiclePlugin extends Plugin implements SimConst, MagneticDisturbance
{
  Triple m_position;
  double m_time_zero = 0;
  double m_last_update = 0;
  JTextArea m_ta;

  public Triple getMagneticDisturbance( double time, Triple position )
  {
    // XXX FIXME XXX --- add relative coordinate systems between disturbance
    // and measurement point.  Here or at the measurement point.

    double strength = 0.5;
    double rx = cT.getMoteScaleWidth() / 4;
    double ry = cT.getMoteScaleHeight() / 4;
    double rz = 0.2;
    double bx = cT.getMoteScaleWidth() / 2;
    double by = cT.getMoteScaleHeight() / 2;
    double s = 1;
    double f = 0.20;
    m_position.x = rx * Math.cos( (2*Math.PI) * (time*f) ) + bx;
    m_position.y = ry * Math.sin( (2*Math.PI) * (time*f) ) + by;
    m_position.z = rz + position.z;
    double xdir = -Math.sin( (2*Math.PI) * (time*f) );
    double ydir = Math.cos( (2*Math.PI) * (time*f) );
    double strength_x = strength * xdir;
    double strength_y = strength * ydir;
    double dx = (position.x - m_position.x) * s;
    double dy = (position.y - m_position.y) * s;
    double dz = (position.z - m_position.z) * s;
    double dist = Math.sqrt( (dx*dx) + (dy*dy) + (dz*dz) );
    double dist3 = dist * dist * dist;

    double now = System.currentTimeMillis() / 1000.0;
    if( (now - m_last_update) >= (1.0 / 5) )
    {
      m_last_update = now;
      m_ta.setText( "x = " + m_position.x + "\ny = " + m_position.y );
      tv.getMotePanel().refresh();
    }

    return new Triple( strength_x/dist3, strength_y/dist3, 0 );
  }

  public void handleEvent( SimEvent e )
  {
  }

  public void register()
  {
    m_ta = new JTextArea(3,40);
    m_ta.setFont(tv.defaultFont);
    m_ta.setEditable(false);
    m_ta.setBackground(Color.lightGray);
    m_ta.setLineWrap(true);
    m_ta.setText( "VehiclePlugin causing a MagneticDisturbance." );
    pluginPanel.add(m_ta);

    m_position = new Triple();

    MagPlugin mp = (MagPlugin)tv.getPluginPanel().getPlugin( "MagPlugin" );
    if( (mp != null) && (mp.getMagneticEnvironment() != null) )
      mp.getMagneticEnvironment().addDisturbance( this );
  }

  public void deregister()
  {
    MagPlugin mp = (MagPlugin)tv.getPluginPanel().getPlugin( "MagPlugin" );
    if( mp != null )
      mp.getMagneticEnvironment().removeDisturbance( this );
  }

  public void reset()
  {
    motePanel.refresh();
  }

  public void draw( Graphics g )
  {
    double k = 0.1;
    int x0 = (int)( cT.simXToGUIX( m_position.x - k ) + 0.5 );
    int y0 = (int)( cT.simYToGUIY( m_position.y - k ) + 0.5 );
    int x1 = (int)( cT.simXToGUIX( m_position.x + k ) + 0.5 );
    int y1 = (int)( cT.simYToGUIY( m_position.y + k ) + 0.5 );
    g.setColor( Color.orange.darker() );
    g.fillRect( x0, y0, x1-x0, y1-y0 );
  }

  public String toString()
  {
    return "Vehicle (Magnetic)";
  }
}

