function [calibratedEstimates, trueDistances, transmitters, receivers, times] = calibrateRangingData(rangingData, calibrationCoeffs, varargin)
%calibratedEstimates = calibrateRangingData(moteIDs, rangingEstimates, calibrationCoeffs, polynomialDegree)
%
%This function will take ranging estimates from a bunch of transmitter and
%receivers and calibrate them using the calibrationCoeffs.  

%parse arguments
if length(varargin)>0
    polynomialDegree = varargin{1};
else
    polynomialDegree= 1; %default to linear regression
end
trueDistances=[];
calibratedEstimates=[];
transmitters = [];
receivers = [];
times = [];
for time = 1:size(rangingData,3) %assume TOF is a vector of TOF_DISTANCE structures
    trueDists = rangingData(:,:,time,1);            
    estDists = rangingData(:,:,time,2);
    trans=ndgrid(1:size(rangingData,1),1:size(rangingData,2));
    rcvs=ndgrid(1:size(rangingData,2),1:size(rangingData,1))';
    transmitterIDs = trans(logical(estDists>0));
    receiverIDs = rcvs(logical(estDists>0));
    rangingEstimates = estDists(logical(estDists>0));
    if isempty(calibrationCoeffs)
        calibratedEstimates = [calibratedEstimates; estDists(logical(estDists>0))];
    else
        for i=1:length(rangingEstimates)
            t=transmitterIDs(i);
            r = receiverIDs(i);
            calibratedEstimates(end+1,1) = polyval(calibrationCoeffs(transmitterIndices(t,polynomialDegree+1)), rangingEstimates(i)) + polyval(calibrationCoeffs(receiverIndices(r,polynomialDegree+1)), rangingEstimates(i));
        end
    end
    transmitters = [transmitters; transmitterIDs];
    receivers = [receivers; receiverIDs];
    times = [times; time * ones(length(trueDists(logical(estDists>0))),1)];
    trueDistances =[trueDistances; trueDists(logical(estDists>0))];
end
