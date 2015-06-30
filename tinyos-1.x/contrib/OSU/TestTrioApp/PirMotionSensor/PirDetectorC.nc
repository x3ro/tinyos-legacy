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
 * The <code>PirDetectorC</code> provides a PIR detector configuration
 *
 * @author  Emre Ertin
 */

#ifndef _PIR_H
#define _PIR_H

#define LOG_SERIAL 1
#endif 

includes Pir;
configuration PirDetectorC
{
    provides
    {
        interface PirDetector;
        interface StdControl;
    }
}
implementation
{
    components  PIRC, ScheduleC, LedsC

    #ifdef LOG_SERIAL
    	,GenericComm as UARTComm	
    #endif

    ,PirDetectorM;
		   		    

    // Map interfaces used to implementations provided.
           
    PirDetectorM.PIR -> PIRC;	
    PirDetectorM.ADC -> PIRC.PIRADC;
    PirDetectorM.PirControl -> PIRC;
    PirDetectorM.Scheduler -> ScheduleC;
 
    // Map interfaces provided by this configuration to interface providers.

    PirDetector = PirDetectorM;
    StdControl = PirDetectorM;

    #ifdef LOG_SERIAL
	    PirDetectorM.UARTControl -> UARTComm.Control;
    	    PirDetectorM.UARTSend -> UARTComm.SendMsg[105];
    #endif

    PirDetectorM.Leds -> LedsC;
}
