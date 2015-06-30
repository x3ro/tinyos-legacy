%define Kamin's World

%     "Copyright (c) 2000 and The Regents of the University of California.  All rights reserved.
% 
%     Permission to use, copy, modify, and distribute this software and its documentation for any purpose, without fee, and without written agreement 
%     is hereby granted, provided that the above copyright notice and the following two paragraphs appear in all copies of this software.
%     
%     IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING 
%     OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%     THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
%     FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
%     PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
%     
%     Authors:  Kamin Whitehouse <kamin@cs.berkeley.edu>
%     Date:     May 10, 2002 

global ROOT
addpath([ROOT '/contrib/kamin'])
addpath([ROOT '/contrib/kamin/localization'])
addpath([ROOT '/contrib/kamin/calibration'])
addpath([ROOT '/contrib/kamin/calibration/bias'])
addpath([ROOT '/contrib/kamin/calibration/slope'])
addpath([ROOT '/contrib/kamin/RFcharacterization'])
addpath([ROOT '/contrib/kamin/POTcharacterization'])
addpath([ROOT '/contrib/kamin/RFestimation'])
addpath([ROOT '/contrib/kamin/TOFcharacterization'])
addpath([ROOT '/contrib/kamin/TOFcharacterization/analysis'])
addpath([ROOT '/contrib/kamin/TOFestimation'])
addpath([ROOT '/contrib/kamin/tools'])
addpath([ROOT '/contrib/kamin/util'])
addpath([ROOT '/contrib/kamin/data'])

global CURRENT_RF_READINGS
CURRENT_RF_READINGS.windowSize = 200;

global CURRENT_TOF_READINGS
CURRENT_TOF_READINGS.windowSize = 20;

addpath([ROOT '/apps/genericSensor'])
defineGenericSensorEnvironment;
addpath([ROOT '/shared/tofRanging'])
defineTofRangingEnvironment;

%sacrifice latency for efficiency
%setDataPortBufferSizes(20);


%define my local ports
%myPorts = {'localhost:9001'};
%myPorts = {'localhost:9001','localhost:9002'};
myPorts = {'testbed:3009'};

%define remote ports on the testbed
defineTestbed

global testbed
%myPorts = testbed.row7;
%myPorts = setxor(testBed.everything,{'COM34'});
%myPorts = union(myPorts, testbed.everything);
%myPorts = union(myPorts,testbed.westerners);
%myPorts = union(myPorts,testbed.easterners);
%myPorts = union(myPorts,testbed.row1);
%myPorts = union(myPorts,testbed.row2);
addPacketPorts(myPorts);
defineTestbedPortMapping
defineTestbedLocations
