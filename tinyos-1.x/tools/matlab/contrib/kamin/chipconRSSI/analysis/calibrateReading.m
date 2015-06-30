function calibratedReading=calibrateReading(measuredReading, calibrationCoeffs, transmitterID, receiverID)
%calibratedReading=getCalibratingReading(measuredReading, calibrationCoeffs, transmitterID, receiverID)
%
%This function uses the calibration information for your transmitter and receiver on the measured Reading
%and returns the calibrated reading

n=length(calibrationCoeffs)/4;
%n=16;

%linear regression
%calibratedReading = calibrationCoeffs(2).*measuredReading + calibrationCoeffs(1);

%joint calibration with linear regression
calibratedReading = calibrationCoeffs(receiverID).*measuredReading + calibrationCoeffs(n+transmitterID).*measuredReading +  calibrationCoeffs(n*2+receiverID) + calibrationCoeffs(n*3+transmitterID);
