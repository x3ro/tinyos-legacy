%defineTofRangingEnvironment
%
%This file defines the environment needed to interact 
%with the TOF_RANGING component.  
%
%The TOF_RANGING component estimates distance between motes using
%time of flight
%

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
%     Date:     June 6, 2002 

global ROOT
addpath([ROOT '/shared/tofRanging'])


global TOF_RANGING_CHIRP_AM_HANDLER
TOF_RANGING_CHIRP_AM_HANDLER=114;            %114 is the AM handler when TOF_RANGING chirps

tofRangingChirpHeader(1)= createField('msgType', 2);
tofRangingChirpHeader(2)= createField('context', 2);
tofRangingChirpHeader(3)= createField('srcID',2);
tofRangingChirpHeader(4)= createField('sounderCalibOffset', 2);
tofRangingChirpHeader(5)= createField('sounderCalibScale',2);
tofRangingChirpHeader(6)= createField('micCalibOffset', 2);
tofRangingChirpHeader(7)= createField('micCalibScale',2);
tofRangingChirpHeader(8)= createField('chirpNumber',2);
addAMHeaders(TOF_RANGING_CHIRP_AM_HANDLER, tofRangingChirpHeader);


global TOF_RANGING_DATA_AM_HANDLER
TOF_RANGING_DATA_AM_HANDLER=115;            %115 is the AM handler when TOF_RANGING sends ranging info

tofRangingDataHeader(1)= createField('msgType', 2);
tofRangingDataHeader(2)= createField('srcID',2);
tofRangingDataHeader(3)= createField('transmitterID', 2);
tofRangingDataHeader(4)= createField('distance',2);
addAMHeaders(TOF_RANGING_DATA_AM_HANDLER, tofRangingDataHeader);

global TOF_RANGING_RANGING
TOF_RANGING_RANGING = 1;

global TOF_RANGING_CALIBRATION
TOF_RANGING_CALIBRATION = 2;

global TOF_RANGING_REQUEST               %this is the msgType to send to a mote if you want it to send ranging data
TOF_RANGING_REQUEST = 1;

global TOF_RANGING_RESPONSE               %this is the msgType of a message with ranging data
TOF_RANGING_RESPONSE = 2;

global TOF_RANGING_COMMAND             %this is the msgType to send to a mote if you want it to chirp
TOF_RANGING_COMMAND = 3;

global TOF_RANGING_CHIRP               %this is the msgType of a tof ranging chirp
TOF_RANGING_CHIRP = 4;