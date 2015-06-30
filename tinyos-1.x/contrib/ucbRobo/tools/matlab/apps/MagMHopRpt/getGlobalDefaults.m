function getGlobalDefaults
% getGlobalDefaults
%
% Prints the global defaults for MAGMHOPRPT

global APPS;

if exist('APPS') && isfield(APPS,'MAGMHOPRPT')
    MAGMHOPRPT = APPS.MAGMHOPRPT;
end

if ~exist('MAGMHOPRPT')
    error('You must call magMHopRptInit.m first to set up a connection.');
end

str = sprintf('Report Threshold: %d',MAGMHOPRPT.reportThresh);
str = [str sprintf('\nNumber of Fade Intervals: %d',MAGMHOPRPT.numFadeIntervals)];
str = [str sprintf('\nRead Fire Interval: %d',MAGMHOPRPT.readFireInterval)];
str = [str sprintf('\nFade Fire Interval: %d',MAGMHOPRPT.fadeFireInterval)];
str = [str sprintf('\nWindow Size: %d',MAGMHOPRPT.windowSize)];
str = [str sprintf('\nReport Interval: %d',MAGMHOPRPT.reportInterval)];
disp(str);
