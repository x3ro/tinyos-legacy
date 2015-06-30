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
// $Id: PhotoSensorM.nc,v 1.1 2003/06/02 12:34:16 dlkiskis Exp $

module PhotoSensorM
{
  provides
  {
    interface U16Sensor as PhotoSensor;
    interface StdControl;
  }
  uses
  {
    interface ADC as BottomPhoto;
    interface StdControl as BottomStdControl;
  }
}
implementation
{
  bool m_is_reading;

  // stdcontrol

  command result_t StdControl.init()
  {
    m_is_reading = FALSE;
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

  command result_t PhotoSensor.read()
  {
    if( m_is_reading == FALSE )
    {
      m_is_reading = TRUE;
      if( call BottomPhoto.getData() == SUCCESS )
	return SUCCESS;
      m_is_reading = FALSE;
    }
    return FAIL;
  }

  event result_t BottomPhoto.dataReady( uint16_t val )
  {
    m_is_reading = FALSE;
    return signal PhotoSensor.readDone( val );
  }
}

