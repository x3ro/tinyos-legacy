function plotRangingData(rangingData, varargin)
%plotRangingData(rangingData, <calibrationCoeffs>, <knowledgeMatrix>)
%
%This function will plot each rangingEstimate against the true distance (if
%known).  If calibrationCoeffs are passed, it plots calibrated
%rangingEstimates.

if length(varargin)>0
    calibrationCoeffs=varargin{1};
else
    calibrationCoeffs=[];
end

if length(varargin)>1
    knowledgeMatrix=varargin{2};
else
    knowledgeMatrix=ones(size(rangingData(:,:,:)));
end

normalizationFactor = max(max(max(max(rangingData))));
rangingData = rangingData./normalizationFactor;
[calibratedDistances, trueDistances, transmitterIDs, receiverIDs, times] = calibrateRangingData(rangingData, calibrationCoeffs);
calibratedDistances = calibratedDistances.*normalizationFactor;
trueDistances = trueDistances.*normalizationFactor;

knownNodes = logical(knowledgeMatrix(sub2ind(size(knowledgeMatrix), transmitterIDs(logical(trueDistances>0)), receiverIDs(logical(trueDistances>0)), times(logical(trueDistances>0))))>0);
unknownNodes = logical(knowledgeMatrix(sub2ind(size(knowledgeMatrix), transmitterIDs(logical(trueDistances>0)), receiverIDs(logical(trueDistances>0)), times(logical(trueDistances>0))))<=0);

[avgError, percentErrors, absoluteErrors] = rangingDataError(trueDistances(logical(trueDistances>0)), calibratedDistances(logical(trueDistances>0)));

% [f x y] = kernelDensity2D([trueDistances calibratedDistances]);%, [-5 230], [-5 230], [], [], []);
% for c=1:size(f,2)%normalize columns
%     if sum(f(:,c))>0
%         f(:,c) = f(:,c)./sum(f(:,c));
%     end
% end
% clf;
% cla;
% hold off
% surf(x,y,f);
plot(trueDistances(knownNodes),calibratedDistances(knownNodes),'*r');
hold on
plot(trueDistances(unknownNodes),calibratedDistances(unknownNodes),'.b');
hold on
plot(1:211, 1:211,'-r')

hold off
title(['Emprical Conditional Probability of Distance Estimates given True Distance: ' num2str(avgError*100) '% error'])
xlabel('True Distance (cm)')
ylabel('Estimated Distance (cm)')
zlabel('Conditional Probability')
figure(gcf)
figure
hist(absoluteErrors, 50)
title(['Distribution of absolute error: ' num2str(avgError*100) '% error'])
xlabel('Error (cm)')
ylabel('# occurences (cm)')
