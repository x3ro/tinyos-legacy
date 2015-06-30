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
// $Id: MagMovingAvgM.nc,v 1.2 2003/07/04 07:23:01 cssharp Exp $

// Description: Calculate the moving average of each magnetometer axis
// independently and use that to center the current reading.

//!! Config 2 { uint8_t MagMovingAvg_num_samples = 8; }

includes moving_average;


module MagMovingAvgM
{
  provides
  {
    interface MagSensor;
    interface StdControl;
  }
  uses
  {
    interface MagSensor as BottomMagSensor;
    interface StdControl as BottomStdControl;
    interface Config_MagMovingAvg_num_samples;
  }
}
implementation
{
  enum {
    MAX_SAMPLES = 32,
  };

  ma_data_t m_movavg_data_x[MAX_SAMPLES];
  ma_data_t m_movavg_data_y[MAX_SAMPLES];

  moving_average_t m_movavg_x;
  moving_average_t m_movavg_y;

  Mag_t m_mag;
  MagVal_t m_magPrev;


  uint16_t absdiff_u16( uint16_t a, uint16_t b )
  {
    return (a<b) ? (b-a) : (a-b);
  }

  task void process_mag()
  {
    Mag_t mag;

    MagVal_t magCurr = {
      x: m_mag.val.x/2 + m_magPrev.x/2,
      y: m_mag.val.y/2 + m_magPrev.y/2,
    };

    m_magPrev = m_mag.val;

    mag.val.x = absdiff_u16(
      add_moving_average( &m_movavg_x, m_mag.val.x ),
      magCurr.x
    );

    mag.val.y = absdiff_u16(
      add_moving_average( &m_movavg_y, m_mag.val.y ),
      magCurr.y
    );

    mag.bias = m_mag.bias;

    signal MagSensor.readDone( mag );
  }

  void init_movavg( uint16_t num_samples )
  {
    if( num_samples > MAX_SAMPLES )
      num_samples = MAX_SAMPLES;
    init_moving_average( &m_movavg_x, m_movavg_data_x, m_movavg_data_x+num_samples );
    init_moving_average( &m_movavg_y, m_movavg_data_y, m_movavg_data_y+num_samples );
  }


  event void Config_MagMovingAvg_num_samples.updated()
  {
    if( G_Config.MagMovingAvg_num_samples > MAX_SAMPLES )
      G_Config.MagMovingAvg_num_samples = MAX_SAMPLES;
    init_movavg( G_Config.MagMovingAvg_num_samples );
  }


  command result_t StdControl.init()
  {
    return call BottomStdControl.init();
  }

  command result_t StdControl.start()
  {
    init_movavg( G_Config.MagMovingAvg_num_samples );
    return call BottomStdControl.start();
  }

  command result_t StdControl.stop()
  {
    return call BottomStdControl.stop();
  }

  command result_t MagSensor.read()
  {
    return call BottomMagSensor.read();
  }

  event result_t BottomMagSensor.readDone( Mag_t mag )
  {
    m_mag = mag;
    post process_mag();
    return SUCCESS;
  }
}

