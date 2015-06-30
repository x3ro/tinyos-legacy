function POTRFReceivePackets(s, packet)
%POTRFReceivePackets(s, packet)
%
%This function recieves new packets from the motes we are trying to calibrate.
%And tries stores it

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

global POT_RF

moteID = get(packet, 'moteID');

if ~isfield(POT_RF, 'active') | sum(size(POT_RF.active) < [moteID POT_RF.potSetting]) >0 | POT_RF.active(moteID)==0
    if (moteID == POT_RF.receivers) < 1
        return
    else
    	POT_RF.active(moteID)=1;
    end
elseif POT_RF.active(moteID)==-1
    return
end

% if ~isfield(POT_RF, 'watchedMoteID') | isempty(POT_RF.watchedMoteID)
%     POT_RF.watchedMoteID = moteID;
% end

if ~isfield(POT_RF, 'receivedRF') | sum(size(POT_RF.receivedRF) < [moteID POT_RF.potSetting]) >0
    POT_RF.receivedRF{moteID, POT_RF.potSetting} = [];
end
POT_RF.receivedRF{moteID, POT_RF.potSetting} = [POT_RF.receivedRF{moteID, POT_RF.potSetting} get(packet, 'samples')];

% 
% if ~isfield(POT_RF, 'std') | length(POT_RF.std) < moteID
%     POT_RF.std{moteID} = [];
% end
% windowSize = min(POT_RF.windowSize, length(POT_RF.bias{moteID})-1);
% POT_RF.std{moteID}(end+1) = std(POT_RF.bias{moteID}(end-windowSize:end));

    %the following should be changed to use WATCH to save CPU cycles
% if POT_RF.watchedMoteID == moteID
%     plot(POT_RF.bias{moteID})
%     title(['Estimate of Bias of Mote#' num2str(moteID)])
% 	hold on
% 	plot(POT_RF.bias{moteID} + POT_RF.std{moteID},'r--')
% 	plot(POT_RF.bias{moteID} - POT_RF.std{moteID},'r--')
% 	hold off
% end

if length(POT_RF.receivedRF{moteID, POT_RF.potSetting}) > POT_RF.numSamples
    removePacketListeners(getPortMapping(moteID), 'POTRFReceivePackets');
    POT_RF.active(moteID) = -1;
	if ~isfield(POT_RF, 'avgRF')
        POT_RF.avgRF= [];
	end
	POT_RF.avgRF(moteID, length(POT_RF.potSettings)+1) = mean(POT_RF.receivedRF{moteID, POT_RF.potSetting});
%    disp(['Bias Calibration for mote#' num2str(moteID) ' is done after ' num2str(length(POT_RF.ambientRF{moteID})) ' samples.'])
%    if moteID == POT_RF.watchedMoteID
%        POT_RF.watchedMoteID = [];
%    end
    if (POT_RF.active ==1) < 1
        disp(['POT Calibration is done for pot Setting' num2str(POT_RF.potSetting)])
		if ~isfield(POT_RF, 'potSettings')
            POT_RF.potSettings= [];
		end
        POT_RF.potSettings(end+1)=POT_RF.potSetting;

        hold off
        for i=1:length(POT_RF.active)
            if POT_RF.active(i)~=0
                plot(POT_RF.potSettings, POT_RF.avgRF(i,:))
            end
            hold on
        end
        if POT_RF.plotTrueRF==1
            POT_RF.trueRF(length(POT_RF.potSettings)) = input('Enter the true RF for this pot setting');
            plot(POT_RF.potSettings, POT_RF.trueRF)
        end
 
        if POT_RF.potSetting < POT_RF.lastPot
            POT_RF.potSetting = POT_RF.potSetting+POT_RF.potStep;
            global RADIO_POT_SETTING
			RADIO_POT_SETTING = POT_RF.potSetting;
			routePackets(POT_RF.transmitter, setPot);
            routePackets(POT_RF.transmitter, radioJamOn);
			routePackets(POT_RF.transmitter, setPot);
            routePackets(POT_RF.transmitter, radioJamOn);
			pause(1)
            
            POT_RF.active=[];
			addPacketListeners(getPortMapping(POT_RF.receivers), 'POTRFReceivePackets');
        else
  			removePacketListeners(getPortMapping(POT_RF.receivers), 'POTRFReceivePackets');
        end
    end
end

