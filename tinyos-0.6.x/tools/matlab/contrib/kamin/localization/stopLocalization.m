function localizationInfo=stopTOFcollect(varargin)
%tofDistance=stopTOFcollect(varargin)
%
%
%This function stops all motes from reading the RF.
%It also takes the trueRF value that was just being sent and stores it.

global LOCALIZATION
global TOF_RANGING_CALIBRATION

if length(varargin) > 0
    moteIDs = varargin{1};
    varargin = {varargin{2:end}};
else
    moteIDs = LOCALIZATION.moteIDs;
end

routePackets(LOCALIZATION.activeTransmitter, tofChirpCommand(0, LOCALIZATION.activeTransmitter, TOF_RANGING_CALIBRATION));
removePacketListeners(getPortMapping(moteIDs), 'localizationReceivePackets');

localizationInfo = LOCALIZATION;