function oopsRestartTOFCalibration()
%oopsRestartTOFCalibration()
%
%this function is used if you use 'startTOFCalibration' but your tranmsitter 
%missed the triggering packet and doesn't start chirping

global TOF_CALIBRATION
global TOF_RANGING_CALIBRATION
routePackets(TOF_CALIBRATION.activeTransmitter, tofChirpCommand(255, TOF_CALIBRATION.activeTransmitter, TOF_RANGING_CALIBRATION));
