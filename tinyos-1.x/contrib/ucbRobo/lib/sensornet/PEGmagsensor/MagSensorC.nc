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
// $Id: MagSensorC.nc,v 1.1.1.1 2004/10/15 01:34:08 phoebusc Exp $

// Description: Standard magnetometer configuration.

configuration MagSensorC
{
  provides
  {
    interface MagSensor;
    interface MagBiasActuator;
    interface MagAxesSpecific;
    interface StdControl;
  }
}
implementation
{
  components MagSensorM
           , Mag;

  MagSensor       = MagSensorM;
  MagBiasActuator = MagSensorM;
  MagAxesSpecific = MagSensorM;
  StdControl      = MagSensorM;

  MagSensorM.MagX             -> Mag.MagX;
  MagSensorM.MagY             -> Mag.MagY;
  MagSensorM.MagSetting       -> Mag.MagSetting;
  MagSensorM.BottomStdControl -> Mag;
}

