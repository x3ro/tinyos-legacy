function rangingData = filterRangingData(rangingData, varargin)
%rangingData = filterRangingData(rangingData, windowSize)
%
%This function takes a rangingData matrix and filters the 'samples'
%dimension such that all samples are turned into one reading.
%
%rangingData is a matrix as follows:
%
%rangingData(transmitter, receiver, time, [truth estimate])

if length(varargin)>0
    windowSize=varargin{1};
else
    windowSize=8;
end

for transmitter = 1:size(rangingData,1)
    for receiver = 1:size(rangingData,2)
        for time = 1:size(rangingData,3) %assume TOF is a vector of TOF_DISTANCE structures
            trueDistance = rangingData(transmitter, receiver, time, 1,1);
            distanceEstimates = rangingData(transmitter, receiver, time, 2,:);
            distanceEstimates = distanceEstimates(logical(distanceEstimates>0));%=max(1,rangingData(transmitter, receiver, time, 1))));
            pointEstimates = [];
            if ~isempty(distanceEstimates)
                distanceEstimates(logical(distanceEstimates<polyval([1.3 -15],trueDistance))) = 286 + distanceEstimates(logical(distanceEstimates<polyval([1.3 -15],trueDistance)));%this is to deal with clock overflow
                indices=min(windowSize,length(distanceEstimates)):length(distanceEstimates);
                for k = indices
				    window = timeWindow(distanceEstimates(1:k), windowSize);
              		pointEstimates(k) = min(window);
                end
                rangingData(transmitter, receiver, time, 2,1) = median(pointEstimates);
            end
        end
    end
end
dummy = rangingData(:,:,:,:,1);
rangingData = squeeze(dummy);