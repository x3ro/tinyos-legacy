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
// $Id: MagSensorM.nc,v 1.1 2003/10/09 01:15:36 cssharp Exp $

// Description: Expose the NestArch magnetometer sensor inferface from the
// TinyOS magnetometer interface.

includes MagSensor;

module MagSensorM
{
  provides
  {
    interface MagSensor;
    interface MagBiasActuator;
    interface MagAxesSpecific;
    interface StdControl;
  }
  uses
  {
    interface ADC as MagX;
    interface ADC as MagY;
    interface MagSetting;
    interface StdControl as BottomStdControl;
  }
}
implementation
{
  Mag_t m_mag;
  MagBias_t m_newbias;
  MagAxes_t m_axes;

  bool m_read_okay;
  bool m_set_okay;
  

  // stdcontrol

  command result_t StdControl.init()
  {
    m_axes.x    = TRUE;
    m_axes.y    = TRUE;
    m_read_okay = TRUE;
    m_set_okay  = TRUE;
    return call BottomStdControl.init();
  }
  
  command result_t StdControl.start()
  {
    return call BottomStdControl.start();
  }
  
  command result_t StdControl.stop()
  {
    return call BottomStdControl.stop();
  }


  // read adc values

  command result_t MagSensor.read()
  {
    if( m_read_okay )
    {
      m_read_okay = FALSE;
      if(m_axes.x) return call MagX.getData();
      if(m_axes.y) return call MagY.getData();
      m_read_okay = TRUE;
    }
    return FAIL;
  }

  async event result_t MagX.dataReady( uint16_t val )
  {
    m_mag.val.x = val;
    if(m_axes.y) return call MagY.getData();
    m_read_okay = TRUE;
    return signal MagSensor.readDone( m_mag );
  }

  async event result_t MagY.dataReady( uint16_t val )
  {
    m_mag.val.y = val;
    m_read_okay = TRUE;
    return signal MagSensor.readDone( m_mag );
  }


  // set bias values

  command result_t MagBiasActuator.set( MagBias_t bias )
  {
    if( m_set_okay )
    {
      m_set_okay = FALSE;
      m_newbias = bias;
      if(m_axes.x) return call MagSetting.gainAdjustX(m_newbias.x);
      if(m_axes.y) return call MagSetting.gainAdjustY(m_newbias.y);
      m_set_okay = TRUE;
    }
    return FAIL;
  }

  event result_t MagSetting.gainAdjustXDone( bool result )
  {
    m_mag.bias.x = m_newbias.x;
    if(m_axes.y) return call MagSetting.gainAdjustY(m_newbias.y);
    m_set_okay = TRUE;
    return signal MagBiasActuator.setDone(result);
  }

  event result_t MagSetting.gainAdjustYDone( bool result )
  {
    m_mag.bias.y = m_newbias.y;
    m_set_okay = TRUE;
    return signal MagBiasActuator.setDone(result);
  }


  // enable axes

  command void MagAxesSpecific.enableAxes( MagAxes_t axes )
  {
    m_axes = axes;

    if(!m_axes.x)
    {
      m_mag.val.x  = 0;
      m_mag.bias.x = 0;
    }

    if(!m_axes.y)
    {
      m_mag.val.y  = 0;
      m_mag.bias.y = 0;
    }
  }

  command MagAxes_t MagAxesSpecific.isAxesEnabled()
  {
    return m_axes;
  }
}

