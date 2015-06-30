/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 * Authors:  Alec Woo Su Ping 
 *           Intel Research Berkeley Lab
 *
 */
/* 
 * Configuration for MicasbTest1 application.
 *
 * MicasbTest1 is an application that test out the magnetometer, accelerometer, and temperature sensor.
 * It demonstrates how to access the data from each individual sensors, how to perform real time 
 * "calibration", and how to filter and process sensory data for the magnetometer.  
 *
 * The test cases for the accelerometer and the temperature sensor is very simple.  The raw 10 bit data from
 * these sensors are sent over the UART for visual inspection.  The format of the packet looks like
 * the following: (24 bytes long, each data is 2 bytes long)
 *
 * [TEMP ACCEL_X ACCEL_Y] [TEMP ACCEL_X ACCEL_Y] [TEMP ACCEL_X ACCEL_Y] [TEMP ACCEL_X ACCEL_Y]
 *
 * For the magnetometer, one can visually look at the LEDs to see if it is working.
 * RED - self calibration is being done
 * GREEN - idle -> no magnetic field event detected
 * Yellow - event triggered:  either X or Y axis has event detected. 
 *
 */
includes sensorboard;

configuration MicasbTest1{ 
// this module does not provide any interface
}

implementation
{
  components Main, MicasbTest1M, GenericComm as Comm, LedsC, ClockC, Accel, Mag, PhotoTemp;

  Main.StdControl -> MicasbTest1M;
  MicasbTest1M.CommControl->Comm;
  MicasbTest1M.Send->Comm.SendMsg[10];

  MicasbTest1M.Clock -> ClockC;
  MicasbTest1M.Leds -> LedsC;
  MicasbTest1M.MagControl-> Mag;
  MicasbTest1M.MagSetting-> Mag;
  MicasbTest1M.MagX -> Mag.MagX;
  MicasbTest1M.MagY -> Mag.MagY;
  MicasbTest1M.AccelControl->Accel;
  MicasbTest1M.AccelX -> Accel.AccelX;
  MicasbTest1M.AccelY -> Accel.AccelY;
  MicasbTest1M.TempControl->PhotoTemp;
  MicasbTest1M.TempADC->PhotoTemp.ExternalTempADC;
}

