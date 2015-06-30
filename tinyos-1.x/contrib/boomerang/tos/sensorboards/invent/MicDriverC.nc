// $Id: MicDriverC.nc,v 1.1.1.1 2007/11/05 19:11:36 jpolastre Exp $
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
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "Mic.h"
#include "sensorboard.h"

/**
 * Driver for the omnidirectional microphone and audio preamplifier
 * on Tmote Invent.
 * <p>
 * <b>Only available on Moteiv's Tmote Invent</b>
 * <p>
 * Before use, be sure to start the sensor using the SplitControl
 * interface.  If you would like to start the sensor on system boot,
 * use the MainControl generic component like so:
 * <pre>
 *  components new MainControl() as MicControl;
 *  components MicDriverC;
 *  MicControl.SplitControl -> MicDriverC;
 * </pre>
 * To continuously sample the microphone, use the Microphone interface
 * which allows you to specify a sampling rate and data buffer for use.
 * This is the recommended method for acquiring data from the Microphone.
 * Use the 'ADC as Mic' interface to extract single data samples from
 * the microphone, although this is not recommended.
 * <p>
 * Vrc sets the compression ratio of the underlying SSM2167 amplifier.
 * Vrg set the noise gate of the SSM2167.  See the Tmote Invent datasheet
 * for more information.
 * <p>
 * MicInterruptDrain sets the resistor value of an RC circuit that
 * determines how long charge leaves a capacitor.  MicInterruptThreshold
 * sets the voltage potential of the capacitor that is required to generate
 * an interrupt.  MicInterrupt allows the enabling/disabling of the
 * interrupt and fires the event when all of the physical conditions are met.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration MicDriverC
{
  provides {
    interface SplitControl;
    interface ADC as Mic;
    interface Microphone;
    interface SensorInterrupt as MicInterrupt;
    interface Potentiometer as Vrc;
    interface Potentiometer as Vrg;
    interface Potentiometer as MicInterruptDrain;
    interface Potentiometer as MicInterruptThreshold;    
  }
}
implementation
{
  components MicDriverM, ADCC, AD524XC, MSP430InterruptC, MSP430DMAC, MSP430ADC12C, LedsC;
  
  MicDriverM.Leds -> LedsC;

  SplitControl = MicDriverM;
  Microphone = MicDriverM;
  Mic = ADCC.ADC[TOS_ADC_MIC_PORT];
  MicInterrupt = MicDriverM;
  MicInterruptDrain = MicDriverM.MicInterruptDrain;
  MicInterruptThreshold = MicDriverM.MicInterruptThreshold;
  Vrc = MicDriverM.Vrc;
  Vrg = MicDriverM.Vrg;

  MicDriverM.ADCStdControl -> ADCC;
  MicDriverM.ADCControl -> ADCC;
  MicDriverM.AD524X -> AD524XC;
  MicDriverM.AD524XControl -> AD524XC;
  MicDriverM.MicInt -> MSP430InterruptC.Port26; // GIO3

  MicDriverM.DMA -> MSP430DMAC.MSP430DMA[unique("DMA")];
  MicDriverM.DMAControl -> MSP430DMAC;

  MicDriverM.MSP430ADC -> MSP430ADC12C.MSP430ADC12Single[unique("MSP430ADC12")];
}
