function startLocalization()
%startLocalization()
%
%

global LOCALIZATION
global TOF_RANGING_CALIBRATION

if isfield(LOCALIZATION,'activeTransmitterIndex')
    LOCALIZATION.activeTransmitterIndex=LOCALIZATION.activeTransmitterIndex+1;
else
    LOCALIZATION.activeTransmitterIndex=1;
end
if LOCALIZATION.activeTransmitterIndex>length(LOCALIZATION.transmitters)
    LOCALIZATION.activeTransmitterIndex=1;
end
LOCALIZATION.activeTransmitter=LOCALIZATION.transmitters(LOCALIZATION.activeTransmitterIndex);

LOCALIZATION.timeStarted=now;
addPacketListeners(getPortMapping(LOCALIZATION.moteIDs), 'localizationReceivePackets');
routePackets(LOCALIZATION.activeTransmitter, tofChirpCommand(255, LOCALIZATION.activeTransmitter, TOF_RANGING_CALIBRATION));