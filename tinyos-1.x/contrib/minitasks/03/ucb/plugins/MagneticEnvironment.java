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
// $Id: MagneticEnvironment.java,v 1.2 2003/06/09 08:45:05 cssharp Exp $

import java.util.*;

class MagneticEnvironment
{
  Vector m_disturbances;

  public MagneticEnvironment()
  {
    m_disturbances = new Vector();
  }

  public void addDisturbance( MagneticDisturbance md )
  {
    if( m_disturbances.contains(md) == false )
      m_disturbances.add( md );
  }

  public void removeDisturbance( MagneticDisturbance md )
  {
    m_disturbances.remove( md );
  }

  public Triple measure( double time, Triple position )
  {
    Triple mag = new Triple(0,0,0);
    for( int i=0; i<m_disturbances.size(); i++ )
    {
      MagneticDisturbance md = (MagneticDisturbance)m_disturbances.get(i);
      Triple mdval = md.getMagneticDisturbance( time, position );
      mag.x += mdval.x;
      mag.y += mdval.y;
      mag.z += mdval.z;
    }
    return mag;
  }
}

