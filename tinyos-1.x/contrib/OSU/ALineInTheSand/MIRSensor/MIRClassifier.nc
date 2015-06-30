/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. *//**
 * The MIRClassifierC is the top-level configuration component that that wires
 * together the other components of the MIR-based classifier.
 *
 * @author  Prabal Dutta
 */

includes Time;

includes GridTreeMsg;

includes MIR;

// List the interfaces that the classifier provides.
configuration MIRClassifier
{
    // This component does not yet provide any interfaces.  However, this
    // module *should* provide event statistics eventually.
}

// Enumerate and wire together the components used in this application.
implementation
{
    // Enumerate the components used in this application.
    components  Main, ReporterM, GridRouting, GridTree,
		
		    //MIR
                ADCC, MIRSensorM, TimerC, MIRSamplerM, MIRTrivialDetectorM, TsyncC, LedsC,
		    		    
		    //Wireless Programming
		    XnpC, GenericComm as XComm;

		  
    // Wire together the components used in this application.
    Main.StdControl -> TsyncC;
    Main.StdControl -> ReporterM;
    Main.StdControl -> GridTree;
    

    //The next 3 lines are for routing
    ReporterM.RoutingControl -> GridRouting.StdControl;	
    ReporterM.Routing -> GridRouting;
    GridRouting.GridInfo -> GridTree.GridInfo;
    
    ReporterM.Leds -> LedsC;

    // Wire up MIRReporter modules.
    ReporterM.MIRSignalDetector -> MIRTrivialDetectorM;
	
    // Wire up MIRSensorM modules.
    Main.StdControl -> MIRSensorM;
    MIRSensorM.ADC -> ADCC.ADC[1];
    MIRSensorM.ADCControl -> ADCC.ADCControl;

    // Wire up MIRSamplerM modules.
    Main.StdControl -> MIRSamplerM;
    MIRSamplerM.MIRSensor -> MIRSensorM;
    MIRSamplerM.Timer -> TimerC.Timer[unique("Timer")];
    MIRSamplerM.TimerControl -> TimerC;

    // Wire up MIRTrivialDetector
    Main.StdControl -> MIRTrivialDetectorM;
    MIRTrivialDetectorM.MIRSampler -> MIRSamplerM;
    MIRTrivialDetectorM.Time -> TsyncC;

    //Wireless Programming
    ReporterM.Xnp -> XnpC;
    ReporterM.GenericCommCtl -> XComm;
}
