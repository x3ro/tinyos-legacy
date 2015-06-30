function tof_calibration=stopTOFcalibration()
%tof_calibration=stopTOFcalibration()
%
%This function will calibrate one sounder against multiple microphones for Time of Flight ranging
%at a particular position.  The positions of all microphones are assumed to have been pre-established
%using the function "setLocation(moteID, location)".  The location of the transmitter can either be
%established the same way or passed as a parameter.  The ID and location of the transmitter will either be passed
%as an argument of the application will prompt you for it
%
%You can run this function multiple time, one for each transmitter at each location

global TOF_CALIBRATION
global TOF_RANGING_CALIBRATION
tof_calibration=TOF_CALIBRATION;

removePacketListeners(getPortMapping(TOF_CALIBRATION.receiverIDs), 'tofCalibrationReceivePackets');
if ~isempty(TOF_CALIBRATION.activeTransmitter)
    routePackets(TOF_CALIBRATION.activeTransmitter, tofChirpCommand(0, TOF_CALIBRATION.activeTransmitter, TOF_RANGING_CALIBRATION));
end