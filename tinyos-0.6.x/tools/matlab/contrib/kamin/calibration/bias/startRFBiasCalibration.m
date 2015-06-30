function startRFBiasCalibration(varargin)
%startRFBiasCalibration(varargin)
%
%USAGE:  startRFCalibration()
%        startRFCalibration(moteIDs)
%        startRFCalibration(moteIDs, threshold)
%        startRFCalibration(moteIDs, threshold, windowSize)
%
%this function starts calibration of the motes.
%It effectually collects data about the motes transceivers
%and tries to correctly parameterize the calibration function
%of that mote.  
%
%If you pass it the ID's of some motes it will calibrate them
%otherwise it will calibrate all motes.
%
%the threshold is used to automatically stop calibrating a mote
%when the standard deviation of the last WINDOW_SIZE bias calculations
%of that mote have gone below the threshold.
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
%     Date:     May 10, 2002 

global RF_CALIBRATION

if length(varargin) > 0
    moteIDs = varargin{1};
else
    moteIDs = 'all';
end

if ischar(moteIDs) & strcmpi(moteIDs, 'all')
    RF_CALIBRATION.moteIDs = 'all';
elseif length(RF_CALIBRATION.moteIDs) ==0
    RF_CALIBRATION.moteIDs = moteIDs;
elseif ~strcmpi(RF_CALIBRATION.moteIDs,'all')
    for i = 1:length(moteIDs)
        contains = 0;
        for j = 1:length(RF_CALIBRATION.moteIDs)
            if RF_CALIBRATION.moteIDs(j) == moteIDs(i);
                contains = 1;
            end
        end
        if contains == 0
            RF_CALIBRATION.moteIDs = [RF_CALIBRATION.moteIDs moteIDs(i)];
        end
    end
end



if length(varargin) >1
    RF_CALIBRATION.threshold  = varargin{2};
else
    RF_CALIBRATION.threshold = 0.05;
end
if length(varargin) >2
    RF_CALIBRATION.windowSize  = varargin{3};
else
    RF_CALIBRATION.windowSize = 200;
end

addPacketListeners(getPortMapping(moteIDs), 'RFCalibrateBiasReceivePackets');
