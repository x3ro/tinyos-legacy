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
// $Id: HDMagSensorM.nc,v 1.1.1.1 2004/10/15 01:34:08 phoebusc Exp $

// Description: Expose the NestArch magnetometer sensor inferface from the
// TinyOS magnetometer interface.

//-- Config 40 { uint8_t HDMagInitialBias = 128; }
//-- Config 41 { uint8_t HDMagInitialFilter = 255; }

includes MagSensorTypes;
//includes Config;

module HDMagSensorM
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
    interface HDMag;
    interface StdControl as BottomStdControl;
  }
}
implementation
{
  enum 
  {
    FLAG_IS_READING = 0x01,
    FLAG_IS_SETTING = 0x02,
    FLAG_INIT_FILTER = 0x04,
    FLAG_INIT_BIAS = 0x08,
  };

  Mag_t m_mag;
  MagBias_t m_newbias;
  uint8_t m_axes;
  MagAxes_t m_magaxes;
  
  uint8_t m_flags;

  bool is_flagged( uint8_t flag ) { return ((m_flags & flag) != 0) ? TRUE : FALSE; }
  void set_flag( uint8_t flag ) { m_flags |= flag; }
  void clear_flag( uint8_t flag ) { m_flags &= ~flag; }

  void initialize()
  {
    if( is_flagged(FLAG_INIT_FILTER) == TRUE )
    {
      clear_flag(FLAG_INIT_FILTER);
      if( call HDMag.setBias( HDMAG_AXES_XY, 128, 128 ) == SUCCESS )
	set_flag(FLAG_INIT_BIAS);
    }
    else if( is_flagged(FLAG_INIT_BIAS) == TRUE )
    {
      clear_flag(FLAG_INIT_BIAS);
    }
    else
    {
      if( call HDMag.setFilter( HDMAG_AXES_XY, 255, 255 ) == SUCCESS )
	set_flag(FLAG_INIT_FILTER);
    }
  }

  // stdcontrol

  command result_t StdControl.init()
  {
    m_axes = HDMAG_AXES_XY;
    return call BottomStdControl.init();
  }
  
  command result_t StdControl.start()
  {
    call BottomStdControl.start();
    m_flags = 0;
    initialize();
    return SUCCESS;
  }
  
  command result_t StdControl.stop()
  {
    return call BottomStdControl.stop();
  }


  // read adc values

  command result_t MagSensor.read()
  {
    if( is_flagged(FLAG_IS_READING) == FALSE )
    {
      set_flag(FLAG_IS_READING);
      if( call HDMag.read(m_axes) == SUCCESS )
	return SUCCESS;
      clear_flag(FLAG_IS_READING);
    }
    return FAIL;
  }

  event void HDMag.readDone( uint8_t axes, uint16_t magx, uint16_t magy, result_t success )
  {
    m_mag.val.x = magx;
    m_mag.val.y = magy;
    clear_flag(FLAG_IS_READING);
    signal MagSensor.readDone( m_mag );
  }


  // set bias values

  command result_t MagBiasActuator.set( MagBias_t bias )
  {
    if( is_flagged(FLAG_IS_SETTING) == FALSE )
    {
      set_flag(FLAG_IS_SETTING);
      if( m_axes & HDMAG_AXIS_X ) m_newbias.x = bias.x;
      if( m_axes & HDMAG_AXIS_Y ) m_newbias.y = bias.y;
      if( call HDMag.setBias( m_axes, m_newbias.x, m_newbias.y ) == SUCCESS )
	return SUCCESS;
      clear_flag(FLAG_IS_SETTING);
    }
    return FAIL;
  }

  event void HDMag.setBiasDone( result_t success )
  {
    m_mag.bias = m_newbias;
    clear_flag(FLAG_IS_SETTING);

    if( is_flagged(FLAG_INIT_BIAS) == TRUE )
    {
      initialize();
      return;
    }

    signal MagBiasActuator.setDone( success );
  }


  // enable axes

  command void MagAxesSpecific.enableAxes( MagAxes_t axes )
  {
    m_axes = 0;

    if( axes.x )
    {
      m_axes |= HDMAG_AXIS_X;
    }
    else
    {
      m_mag.val.x  = 0;
      m_mag.bias.x = 0;
    }

    if( axes.y )
    {
      m_axes |= HDMAG_AXIS_Y;
    }
    else
    {
      m_mag.val.y  = 0;
      m_mag.bias.y = 0;
    }
  }

  command MagAxes_t MagAxesSpecific.isAxesEnabled()
  {
    m_magaxes.x = (m_axes & HDMAG_AXIS_X) ? TRUE : FALSE;
    m_magaxes.y = (m_axes & HDMAG_AXIS_Y) ? TRUE : FALSE;
    return m_magaxes;
  }


  // filter

  event void HDMag.setFilterDone( result_t success )
  {
    if( is_flagged(FLAG_INIT_FILTER) == TRUE )
    {
      initialize();
      return;
    }
  }
}

