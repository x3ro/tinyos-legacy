function getGlobalDefaults
% getGlobalDefaults
%
% Prints the global defaults for MAGDIRECTBOT

global APPS;

if exist('APPS') && isfield(APPS,'MAGDIRECTBOT')
    MAGDIRECTBOT = APPS.MAGDIRECTBOT;
end

if ~exist('MAGDIRECTBOT')
    error('You must call magDirectBotInit.m first to set up a connection.');
end

str = sprintf('Report Threshold: %d',MAGDIRECTBOT.reportThresh);
str = [str sprintf('\nRead Fire Interval: %d',MAGDIRECTBOT.readFireInterval)];
str = [str sprintf('\nWindow Size: %d',MAGDIRECTBOT.windowSize)];
str = [str sprintf('\nTime Out: %d',MAGDIRECTBOT.timeOut)];

str = [str sprintf('\nStale Age: %d',MAGDIRECTBOT.staleAge)];
str = [str sprintf('\nNumber of Fade Intervals: %d',MAGDIRECTBOT.numFadeIntervals)];
str = [str sprintf('\nFade Fire Interval: %d',MAGDIRECTBOT.fadeFireInterval)];
disp(str);
