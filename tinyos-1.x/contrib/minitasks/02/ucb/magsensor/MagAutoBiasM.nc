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
// $Id: MagAutoBiasM.nc,v 1.2 2003/02/03 23:32:45 cssharp Exp $

// Description: Adjust the bias setting of the magnetometer to push the
// reading to 500 with each step.

includes MagSensor;

module MagAutoBiasM
{
  provides
  {
    interface MagSensor;
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
  enum
  {
    BIAS_CENTER = 500,
    BIAS_SCALE  = 32
  };

  uint8_t calc_new_bias( uint8_t bias, uint16_t val )
  {
    if( val < BIAS_CENTER )
    {
      uint16_t delta = (BIAS_CENTER-val) / BIAS_SCALE;
      return (bias < delta) ? 0 : (bias-(uint8_t)delta);
    }
    else
    {
      uint16_t delta = (val-BIAS_CENTER) / BIAS_SCALE;
      return ((255-bias) < delta) ? 255 : (bias+(uint8_t)delta);
    }
  }


  // stdcontrol

  command result_t StdControl.init()
  {
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
    return call BottomMagSensor.read();
  }

  event result_t BottomMagSensor.readDone( Mag_t* mag )
  {
    result_t success = signal MagSensor.readDone(mag);
    MagBias_t newbias = {
      x: calc_new_bias( mag->bias.x, mag->val.x ),
      y: calc_new_bias( mag->bias.y, mag->val.y ),
    };
    return call BottomMagBiasActuator.set(&newbias) && success;
  }

  event result_t BottomMagBiasActuator.setDone( result_t success )
  {
    return TRUE;
  }
}


