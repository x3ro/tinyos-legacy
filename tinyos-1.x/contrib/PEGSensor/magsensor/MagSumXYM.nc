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
// $Id: MagSumXYM.nc,v 1.1 2003/10/09 01:15:36 cssharp Exp $

// Description: Module to combine the magnetometer reading and bias into a
// single value.

includes MagSensor;

module MagSumXYM
{
  provides
  {
    interface U16Sensor;
    interface StdControl;
  }
  uses
  {
    interface MagSensor as BottomMagSensor;
    interface StdControl as BottomStdControl;
  }
}
implementation
{
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

  command result_t U16Sensor.read()
  {
    return call BottomMagSensor.read();
  }

  event result_t BottomMagSensor.readDone( Mag_t mag )
  {
    uint16_t mag_sum = mag.val.x + mag.val.y;

    // ceiling at 65535, so test for unsigned overflow
    if( mag_sum < mag.val.x )
      mag_sum = ~(0u);

    return signal U16Sensor.readDone( mag_sum );
  }
}


