// $Id: PIRC.nc,v 1.1.1.1 2005/05/10 23:37:06 rsto99 Exp $

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
 * The <code>Pir</code> configuration provides an API to the functionality of
 * the passive infrared (PIR) detectors on the Echelon Mote.
 *
 * @author  Prabal Dutta <dutta.4@osu.edu>
 */
includes sensorboard;
configuration PIRC
{
//    provides interface Pir;
    provides interface ADC as A;
    provides interface StdControl;
}
implementation
{
    components PIRM, ADCC;

//    Pir = PIRM;
    StdControl = PIRM;
    A = ADCC.ADC[TOS_ADC_PIR_A_PORT];
    PIRM.ADCControl -> ADCC;
}
