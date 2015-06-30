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
// $Id: PhotoMovingAvgM.nc,v 1.1 2003/02/03 23:35:49 cssharp Exp $

//!! Config 4 { uint8_t PhotoMovingAvg_num_samples = 8; }

includes moving_average;


module PhotoMovingAvgM
{
  provides
  {
    interface U16Sensor as PhotoSensor;
    interface StdControl;
  }
  uses
  {
    interface U16Sensor as BottomPhotoSensor;
    interface StdControl as BottomStdControl;
    interface Config_PhotoMovingAvg_num_samples;
  }
}
implementation
{
  enum {
    MAX_SAMPLES = 32,
  };

  ma_data_t m_movavg_data[MAX_SAMPLES];
  moving_average_t m_movavg;
  uint16_t m_photo;


  uint16_t absdiff_u16( uint16_t a, uint16_t b )
  {
    return (a<b) ? (b-a) : (a-b);
  }

  task void process_photo()
  {
    uint16_t photo = absdiff_u16(
      add_moving_average( &m_movavg, m_photo ),
      m_photo
    );

    signal PhotoSensor.readDone( photo );
  }

  void init_movavg( uint16_t num_samples )
  {
    if( num_samples > MAX_SAMPLES )
      num_samples = MAX_SAMPLES;
    init_moving_average( &m_movavg, m_movavg_data, m_movavg_data+num_samples );
  }


  event void Config_PhotoMovingAvg_num_samples.updated()
  {
    init_movavg( G_Config.PhotoMovingAvg_num_samples );
  }


  command result_t StdControl.init()
  {
    return call BottomStdControl.init();
  }

  command result_t StdControl.start()
  {
    init_movavg( G_Config.PhotoMovingAvg_num_samples );
    return call BottomStdControl.start();
  }

  command result_t StdControl.stop()
  {
    return call BottomStdControl.stop();
  }

  command result_t PhotoSensor.read()
  {
    return call BottomPhotoSensor.read();
  }

  event result_t BottomPhotoSensor.readDone( uint16_t photo )
  {
    m_photo = photo;
    post process_photo();
    return SUCCESS;
  }
}

