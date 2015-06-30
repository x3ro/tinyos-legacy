function RFCalibrateSlopeReceivePackets(s, packet)
%RFCalibrateSlopeReceivePackets(s, packet)
%
%This function recieves new packets from the motes we are trying to calibrate.
%And tries to use that info to set the parameters of the calibration function

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

moteID = get(packet, 'moteID');

if ~isfield(RF_CALIBRATION, 'active') | length(RF_CALIBRATION.active)<moteID | RF_CALIBRATION.active(moteID)==0
	RF_CALIBRATION.active(moteID)=1;
elseif RF_CALIBRATION.active(moteID)==-1
    return
end

if ~isfield(RF_CALIBRATION, 'watchedMoteID') | isempty(RF_CALIBRATION.watchedMoteID)
    RF_CALIBRATION.watchedMoteID = moteID;
end

if ~isfield(RF_CALIBRATION, 'controlledRF') | length(RF_CALIBRATION.controlledRF) < moteID
    RF_CALIBRATION.controlledRF{moteID} = [];
end
RF_CALIBRATION.controlledRF{moteID} = [RF_CALIBRATION.controlledRF{moteID} get(packet, 'samples')];

if ~isfield(RF_CALIBRATION, 'slope') | length(RF_CALIBRATION.slope) < moteID
    RF_CALIBRATION.slope{moteID} = [];
end
RF_CALIBRATION.slope{moteID}(end+1) = 1/(mean(RF_CALIBRATION.controlledRF{moteID}) - RF_CALIBRATION.bias{moteID});

if ~isfield(RF_CALIBRATION, 'slopeStd') | length(RF_CALIBRATION.slopeStd) < moteID
    RF_CALIBRATION.slopeStd{moteID} = [];
end
windowSize = min(RF_CALIBRATION.windowSize, length(RF_CALIBRATION.slope{moteID})-1);
RF_CALIBRATION.slopeStd{moteID}(end+1) = std(RF_CALIBRATION.slope{moteID}(end-windowSize:end));

    %the following should be changed to use WATCH to save CPU cycles
% if RF_CALIBRATION.watchedMoteID == moteID
%     plot(RF_CALIBRATION.bias{moteID})
%     title(['Estimate of Bias of Mote#' num2str(moteID)])
% 	hold on
% 	plot(RF_CALIBRATION.bias{moteID} + RF_CALIBRATION.std{moteID},'r--')
% 	plot(RF_CALIBRATION.bias{moteID} - RF_CALIBRATION.std{moteID},'r--')
% 	hold off
% end

if length(RF_CALIBRATION.slope{moteID}) > RF_CALIBRATION.windowSize & RF_CALIBRATION.slopeStd{moteID}(end) < RF_CALIBRATION.threshold
    removePacketListeners(getPortMapping(moteID), 'RFCalibrateReceivePackets');
    RF_CALIBRATION.active(moteID) = -1;
    disp(['Slope Calibration for mote#' num2str(moteID) ' is done after ' num2str(length(RF_CALIBRATION.ambientRF{moteID})) ' samples.'])
    if moteID == RF_CALIBRATION.watchedMoteID
        RF_CALIBRATION.watchedMoteID = [];
    end
    if (RF_CALIBRATION.active ==1) < 1
        disp('RF Slope Calibration is done; use stopRFSlopeCalibration to get calibration data.')
    end
end

