// $Id: PirToLeds.nc,v 1.1 2004/05/03 23:09:41 prabal Exp $

/*
 * Copyright (c) 2004 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

/**
 * PirToLeds is an application that periodically samples the PIR sensor
 * and displays the highest 3 bits of the raw PIR ADC reading to the
 * LEDs, with YELLOW being the most signficant bit and RED being the
 * least significant bit.
 *
 * @author  Prabal Dutta
 */
includes sensorboard;
configuration PirToLeds
{
}
implementation
{
    components Main, SenseToInt, IntToLeds, TimerC, ADCC, PirC;

    Main.StdControl -> SenseToInt;
    Main.StdControl -> IntToLeds;

    SenseToInt.Timer -> TimerC.Timer[unique("Timer")];
    SenseToInt.TimerControl -> TimerC;
    SenseToInt.ADC -> PirC.A;
    SenseToInt.ADCControl -> PirC;
    SenseToInt.IntOutput -> IntToLeds;
}
