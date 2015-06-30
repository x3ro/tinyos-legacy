/**
 * Copyright (c) 2003 - The Ohio State University.
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
 * The MagClassifierC is the top-level configuration component that that wires
 * together the other components of the magnetometer-based classifier.
 *
 * @author  Prabal Dutta
 */

includes Time;

includes GridTreeMsg;


// List the interfaces that the classifier provides.
configuration MagClassifier
{
    // This component does not yet provide any interfaces.  However, this
    // module *should* provide event statistics eventually.
}

// Enumerate and wire together the components used in this application.
implementation
{
    // Enumerate the components used in this application.
    components  Main, ClassifierM, EnergyEstimatorM, SignalDetectorM,
                MovingStatisticsM, MagSamplerM, TimerC, MagC,
                ReporterM, GridRouting, GridTree, XnpC, GenericComm as XComm, LedsC, TsyncC;

    // Wire together the components used in this application.
    Main.StdControl -> ClassifierM;
    Main.StdControl -> EnergyEstimatorM;
    Main.StdControl -> SignalDetectorM;
    Main.StdControl -> MovingStatisticsM;
    Main.StdControl -> MagSamplerM;
    Main.StdControl -> MagC;
    Main.StdControl -> TsyncC;
    Main.StdControl -> ReporterM;
    Main.StdControl -> GridTree;
    

    //The next 3 lines are for routing
    ReporterM.RoutingControl -> GridRouting.StdControl;	
    ReporterM.Routing -> GridRouting;
    
    GridRouting.GridInfo -> GridTree.GridInfo;
    
    ReporterM.Classifier -> ClassifierM;
    ReporterM.Leds -> LedsC;
   
    ClassifierM.EnergyEstimator -> EnergyEstimatorM;
    ClassifierM.SignalDetector -> SignalDetectorM;
    ClassifierM.Time -> TsyncC;
    ClassifierM.Xnp -> XnpC;
    ClassifierM.GenericCommCtl -> XComm;

    EnergyEstimatorM.SignalDetector -> SignalDetectorM;
    EnergyEstimatorM.MovingStatistics -> MovingStatisticsM;

    SignalDetectorM.MovingStatistics -> MovingStatisticsM;
    SignalDetectorM.Leds -> LedsC;

    MovingStatisticsM.MagSampler -> MagSamplerM;

    MagSamplerM.Timer -> TimerC.Timer[unique("Timer")];
    MagSamplerM.MagSensor -> MagC;
}
