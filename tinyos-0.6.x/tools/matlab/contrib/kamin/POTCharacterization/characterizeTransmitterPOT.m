function characterizeTransmitterPOT(varargin)
%characterizeTransmitterPOT(transmitter, firstPotSetting, lastPotSetting, potSettingStep)
%
%this function takes the ID of a mote and then changes it's pot setting
%accordingly, each time asking you for an emprical measurement of it's transmission power.
%the standard will be to put the antenna 1ft from the transmitter.

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
global RADIO_POT_SETTING
POT_RF.potSettings = [];
POT_RF.trueRF = [];
hold off

POT_RF.transmitter = varargin{1};
if length(varargin) > 1
    POT_RF.firstPot = varargin{2};
    POT_RF.potSetting = varargin{2};
end
if length(varargin) > 2
    POT_RF.lastPot = varargin{3};
end
if length(varargin) > 3
    POT_RF.potStep = varargin{4};
end

for pot = POT_RF.firstPot:POT_RF.potStep:POT_RF.lastPot
	POT_RF.potSetting = pot;
	POT_RF.potSettings(end+1) = pot;
    RADIO_POT_SETTING = POT_RF.potSetting;
	routePackets(POT_RF.transmitter, setPot);
	routePackets(POT_RF.transmitter, radioJamOn);
    
	POT_RF.trueRF(length(POT_RF.potSettings)) = input('Enter the true RF for this pot setting');
	plot(POT_RF.potSettings, POT_RF.trueRF)
end
