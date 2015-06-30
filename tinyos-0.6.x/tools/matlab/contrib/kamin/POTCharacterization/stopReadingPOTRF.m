function potRF=stopReadingPOTRF(varargin)
%potRF=stopReadingPOTRF(<<moteIDs>, trueRF>)
%
%
%This function stops all motes from reading the RF.
%It also takes the trueRF value that was just being sent and stores it.

global POT_RF

if length(varargin) > 1
    moteIDs = varargin{1};
    varargin = {varargin{2:end}};
else
    moteIDs = POT_RF.receivers;
end

removePacketListeners(getPortMapping(moteIDs), 'POTRFReceivePackets');

if length(varargin)>0
    POT_RF.trueRF(POT_RF.potSetting) = varargin{1};
end

potRF = POT_RF;