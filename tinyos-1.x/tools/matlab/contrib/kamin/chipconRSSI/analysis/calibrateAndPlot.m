function [avgError, percentErrors, absoluteErrors] =calibrateAndPlot(rangingData, calibrationCoeffs)
%
%this function takes data in the same format:
%data = [receiverId transmitterId estimatedDistance trueDistance]
%
%and changed the estimated distance using the calibrationCoeffs, which must
%be in a format that works with the function calibrateReading

calibratedDistances = calibrateReading(rangingData(:,3), calibrationCoeffs, rangingData(:,2), rangingData(:,1));
trueDistances = rangingData(:,4);

%plot the calibrated estimates
hold off
%plot(trueDistances, calibratedDistances,'.b')
[f, x, y] = kernelDensity2D([trueDistances calibratedDistances]);%, x, y, nXPoints=25, nYPoints=25, sigma=1, weights)
surf(x,y,f)
hold on
maxDistance = max(trueDistances);
plot([0:maxDistance],[0:maxDistance],'-r')
[avgError, percentErrors, absoluteErrors] = rangingDataError(trueDistances, calibratedDistances);
xlabel('True Distance (cm)')
ylabel('Estimated Distance (cm)')
title(['RSSI: ' num2str(mean(percentErrors)*100) '% error; ' num2str(mean(abs(absoluteErrors))) 'cm error'])