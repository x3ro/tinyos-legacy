function calibratedReading=calibrateReading(measuredReading, transmitterID, receiverID)
%calibratedReading=getCalibratingReading(measuredReading)
%
%This function uses the calibration information for your transmitter and receiver on the measured Reading

global TOF_CALIBRATION

if length(TOF_CALIBRATION.transmitterCoefficients)<transmitterID
    t=[.5 0];
else
    t = TOF_CALIBRATION.transmitterCoefficients{transmitterID};
end

if length(TOF_CALIBRATION.receiverCoefficients)<receiverID
    r=[.5 0];
else
    r = TOF_CALIBRATION.receiverCoefficients{receiverID};
end

calibratedReading = measuredReading*t(1) + measuredReading*r(1) +  t(2) + r(2);