// $Id: MicaSBTest1.nc,v 1.2 2003/10/07 21:44:53 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* Authors:  Alec Woo Su Ping 
 *           Intel Research Berkeley Lab
 * Date:     $Id: MicaSBTest1.nc,v 1.2 2003/10/07 21:44:53 idgay Exp $
 */
/* 
 * Configuration for MicaSBTest1 application.
 *
 * MicaSBTest1 is an application that test out the magnetometer,
 * accelerometer, and temperature sensor. It demonstrates how to access
 * the data from each individual sensors, how to perform real time 
 * "calibration", and how to filter and process sensory data
 * for the magnetometer.  
 *
 * The test cases for the accelerometer and the temperature sensor
 * are very simple.  The raw 10 bit data from these sensors are sent
 * over the UART for visual inspection.  The format of the packet looks like
 * the following: (24 bytes long, each data is 2 bytes long)
 *
 * [TEMP ACCEL_X ACCEL_Y] [TEMP ACCEL_X ACCEL_Y] [TEMP ACCEL_X ACCEL_Y] [TEMP ACCEL_X ACCEL_Y]
 *
 * For the magnetometer, one can visually look at the LEDs to see
 * if it is working.
 *
 * RED - self calibration is being done
 * GREEN - idle -> no magnetic field event detected
 * Yellow - event triggered:  either X or Y axis has event detected. 
 *
 */

/**
 * @author Alec Woo Su Ping
 * @author Intel Research Berkeley Lab
 */

includes sensorboard;

configuration MicaSBTest1{ 
// this module does not provide any interface
}

implementation
{
  components Main, MicaSBTest1M, GenericComm as Comm, LedsC, TimerC, Accel, Mag, PhotoTemp;

  Main.StdControl -> MicaSBTest1M;
  Main.StdControl -> TimerC;

  MicaSBTest1M.CommControl->Comm;
  MicaSBTest1M.Send->Comm.SendMsg[10];

  MicaSBTest1M.Timer -> TimerC.Timer[unique("Timer")];
  MicaSBTest1M.Leds -> LedsC;
  MicaSBTest1M.MagControl-> Mag;
  MicaSBTest1M.MagSetting-> Mag;
  MicaSBTest1M.MagX -> Mag.MagX;
  MicaSBTest1M.MagY -> Mag.MagY;
  MicaSBTest1M.AccelControl->Accel;
  MicaSBTest1M.AccelX -> Accel.AccelX;
  MicaSBTest1M.AccelY -> Accel.AccelY;
  MicaSBTest1M.TempControl->PhotoTemp.TempStdControl;
  MicaSBTest1M.TempADC->PhotoTemp.ExternalTempADC;
}

