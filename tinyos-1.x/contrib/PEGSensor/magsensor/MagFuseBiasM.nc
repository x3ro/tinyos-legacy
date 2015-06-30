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
// $Id: MagFuseBiasM.nc,v 1.1 2003/10/09 01:15:36 cssharp Exp $

// Description: Module to combine the magnetometer reading and bias into a
// single value.

includes MagSensor;

module MagFuseBiasM
{
  provides
  {
    interface MagSensor;
    interface Valid;
    interface StdControl;
  }
  uses
  {
    interface MagSensor as BottomMagSensor;
    interface MagBiasActuator as BottomMagBiasActuator;
    interface StdControl as BottomStdControl;
  }
}
implementation
{
  Mag_t m_mag;
  uint8_t m_spam_count;

  uint8_t calc_new_bias( uint8_t bias, uint16_t val )
  {
    if( val < MAG_BIAS_LOW )
    {
      uint16_t delta = (MAG_BIAS_CENTER-val) / MAG_BIAS_SCALE;
      return (bias < (uint8_t)delta) ? 0 : (bias-(uint8_t)delta);
      //return (bias<1) ? 0 : (bias-1);
    }
    else if( val > MAG_BIAS_HIGH )
    {
      uint16_t delta = (val-MAG_BIAS_CENTER) / MAG_BIAS_SCALE;
      return ((255-bias) < (uint8_t)delta) ? 255 : (bias+(uint8_t)delta);
      //return (bias>254) ? 255 : (bias+1);
    }
    return bias;
  }


  // spam initialization to quickly settle the bias value

  task void spam_init()
  {
    if( m_spam_count > 0 )
    {
      if( call MagSensor.read() != SUCCESS )
      {
	post spam_init();
	return;
      }
      m_spam_count--;
    }
  }


  // process a new mag reading

  task void process_new_mag_reading()
  {
    MagBias_t newbias = {
      x: calc_new_bias( m_mag.bias.x, m_mag.val.x ),
      y: calc_new_bias( m_mag.bias.y, m_mag.val.y ),
    };

    call BottomMagBiasActuator.set(newbias);

    // assumed that m_mag is reset to new values upon reentry
    m_mag.val.x += MAG_BIAS_SCALE * m_mag.bias.x;
    m_mag.val.y += MAG_BIAS_SCALE * m_mag.bias.y;

    if( m_spam_count > 0 )
    {
      post spam_init();
    }
    else
    {
      signal MagSensor.readDone(m_mag);
    }
  }

  // stdcontrol

  command result_t StdControl.init()
  {
    m_spam_count = 255;
    return call BottomStdControl.init();
  }

  command result_t StdControl.start()
  {
    m_spam_count = 255;
    call BottomStdControl.start();
    post spam_init();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return call BottomStdControl.stop();
  }


  // read adc values

  command result_t MagSensor.read()
  {
    return call BottomMagSensor.read();
  }

  event result_t BottomMagSensor.readDone( Mag_t mag )
  {
    m_mag = mag;
    post process_new_mag_reading();
    return SUCCESS;
  }

  event result_t BottomMagBiasActuator.setDone( result_t success )
  {
    return TRUE;
  }


  // valid settings

  command void Valid.set( bool valid )
  {
    if( valid == TRUE )
    {
      m_spam_count = 0;
    }
    else
    {
      m_spam_count = 255;
      post spam_init();
    }
  }

  command bool Valid.get()
  {
    return (m_spam_count == 0);
  }
}

