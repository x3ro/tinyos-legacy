//$Id: MicC.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/**
 * Configuration file for the Trio microphone <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;

configuration MicC
{
  provides {
    interface StdControl;
    interface Mic;
    interface ADC as MicADC;
  }
}
implementation
{
  components AD5242Bus0C, IOSwitch1C, IOSwitch2C, ADCC, MicM;

  StdControl = MicM;
  Mic = MicM;
  MicADC = ADCC.ADC[TOS_ADC_ACOUSTIC_PORT];

  MicM.ADCControl -> ADCC;
  MicM.AD5242Control -> AD5242Bus0C.StdControl;
  MicM.AD5242 -> AD5242Bus0C.AD5242;

  MicM.IOSwitch1Control -> IOSwitch1C.StdControl;
  MicM.IOSwitch1 -> IOSwitch1C.IOSwitch;
  MicM.IOSwitch1Interrupt -> IOSwitch1C.IOSwitchInterrupt;
  MicM.IOSwitch2Control -> IOSwitch2C.StdControl;
  MicM.IOSwitch2 -> IOSwitch2C.IOSwitch;
}
