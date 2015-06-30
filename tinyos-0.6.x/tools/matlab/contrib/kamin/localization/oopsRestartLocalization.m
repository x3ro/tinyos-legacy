function oopsRestartLocalization()
%oopsRestartLocalization()
%
%this function is used if you use 'startLocalization' but your tranmsitter 
%missed the triggering packet and doesn't start chirping

global LOCALIZATION
global TOF_RANGING_CALIBRATION
routePackets(LOCALIZATION.activeTransmitter, tofChirpCommand(255, LOCALIZATION.activeTransmitter, TOF_RANGING_CALIBRATION));
