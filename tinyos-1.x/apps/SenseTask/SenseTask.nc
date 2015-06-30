// $Id: SenseTask.nc,v 1.4 2004/05/30 23:34:56 jpolastre Exp $

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
/* 
 * Authors:  David Culler   Su Ping 
 *           Intel Research Berkeley Lab
 *
 */
/**
 * Configuration for SenseTask application.
 * 
 * When the timer fires, this application reads sensor data (light in 
 * this case),  averages the sensor readings, and displays the highest 
 * 3 bits of the average to the LEDs. Unlike Sense, it uses a task to
 * display the data.
 * 
 * @author David Culler
 * @author Su Ping
 * @author Intel Research Berkeley Lab
 **/
configuration SenseTask { 
// this module does not provide any interfaces
}
implementation
{
  components Main, SenseTaskM, LedsC, TimerC, DemoSensorC as Sensor;

  Main.StdControl -> TimerC;
  Main.StdControl -> Sensor;
  Main.StdControl -> SenseTaskM;

  SenseTaskM.Timer -> TimerC.Timer[unique("Timer")];
  SenseTaskM.ADC -> Sensor;
  SenseTaskM.Leds -> LedsC;
}

