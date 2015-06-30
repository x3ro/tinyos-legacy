function [totalAbsoluteError,absoluteError]=findLocationError(t)
%[totalAbsoluteError,absoluteError]=findLocationError(t)
%
%This function takes the current XY positions and the true XY positions
%
%It returns the absolute error (in terms of absolute euclidean distance between
%true positions and estimateddistances).  It also returns absolute error
%per node

mobileNodes = vectorFind(setdiff(t.nodeIDs, t.anchorNodes), t.nodeIDs);
xy=t.xyEstimate(mobileNodes,1)+t.xyEstimate(mobileNodes,2)*1i;
trueXY=t.xy(mobileNodes,1)+t.xy(mobileNodes,2)*1i;
absoluteError = abs(xy-trueXY)';
totalAbsoluteError = mean(absoluteError);