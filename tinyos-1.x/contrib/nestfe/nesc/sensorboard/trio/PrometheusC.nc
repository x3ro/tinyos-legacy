//$Id: PrometheusC.nc,v 1.3 2005/07/22 02:28:19 jaein Exp $
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
 * Configuration file for Prometheus <p>
 *
 * @modified 6/6/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;

configuration PrometheusC {
  provides {
    interface StdControl;
    interface Prometheus;
  }
}
implementation{
  components PrometheusM, ADCC,
             PWSwitchC, IOSwitch1C, TimerC;

  StdControl = PrometheusM;
  Prometheus = PrometheusM;

  PrometheusM.ADCControl -> ADCC;
  PrometheusM.PWSwitchControl -> PWSwitchC.StdControl;
  PrometheusM.PWSwitchPort -> PWSwitchC.BytePort;

  PrometheusM.BattADC -> ADCC.ADC[TOS_ADC_MUX1_PORT];
  PrometheusM.CapADC  -> ADCC.ADC[TOS_ADC_MUX0_PORT];

  PrometheusM.IOSwitch1Control -> IOSwitch1C.StdControl;  
  PrometheusM.IOSwitch1 -> IOSwitch1C.IOSwitch;

  PrometheusM.Timer -> TimerC.Timer[unique("Timer")];
}


