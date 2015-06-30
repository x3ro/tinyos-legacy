function [avgError, percentErrors, absoluteErrors] = rangingDataError(trueDistances, estimatedDistances)
%[avgError, percentErrors, absoluteErrors] = rangingDataError(trueDistances, estimatedDistances)
%
%This function gives you the ranging errors

absoluteErrors = estimatedDistances-trueDistances;
percentErrors = abs(absoluteErrors)./trueDistances;
avgError = mean(percentErrors);