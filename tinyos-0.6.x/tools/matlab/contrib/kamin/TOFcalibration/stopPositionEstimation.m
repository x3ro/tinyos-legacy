function tof_calibration=startTOFcalibration()
%tof_calibration=startTOFcalibration()
%
%This function will calibrate one sounder against multiple microphones for Time of Flight ranging
%at a particular position.  The positions of all microphones are assumed to have been pre-established
%using the function "setLocation(moteID, location)".  The location of the transmitter can either be
%established the same way or passed as a parameter.  The ID and location of the transmitter will either be passed
%as an argument of the application will prompt you for it
%
%You can run this function multiple time, one for each transmitter at each location

global TOF_CALIBRATION
tof_calibration=0;

disp('This function will calibration your transmitter vs multiple microphones for TOF ranging')
disp('')
disp('Make sure that all locations of your receivers have been established (''use setLocation(moteID, location)'')')
disp('')

%get the ID of the transmitter using user input
if TOF_CALIBRATION.interactive==0
    TOF_CALIBRATION.activeTransmitter=input('Enter the ID of the calibrating transmitter');
end

%if there is no active transmitter (either via user input or otherwise), calibration is over
if isempty(transmitterID)
    tof_calibration=estimateTOFCalibrationCoefficients();
    return
end

%get the location of the transmitter using user input
if TOF_CALIBRATION.interactive==0
    setLocation(TOF_CALIBRATION.activeTransmitter, input('Enter the coordinates of the calibrating transmitter'));
end

%create a plot to add new data to
hold off
TOF_CALIBRATION.plotHandle=plot(0,0,'.');
hold on
plot([1:150],[1:150])

%then route a packet to the transmitter to tell it to chirp forever
%and store the time that we started the process
TOF_CALIBRATION.activeTransmitter=transmitterID;
TOF_CALIBRATION.timeStarted=now;
routePackets(transmitterID, tofChirpCommand);