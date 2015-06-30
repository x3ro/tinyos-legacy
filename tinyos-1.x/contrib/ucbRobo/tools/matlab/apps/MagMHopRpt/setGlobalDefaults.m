function setGlobalDefaults(reportThresh,winSize,rptItvl,readFireItvl,fadeFireItvl,numFadeItvl)
% setGlobalDefaults(reportThresh,winSize,rptItvl,readFireItvl,fadeFireItvl,numFadeItvl)
%
% Sets the global defaults for MAGMHOPRPT

global APPS;

if ~exist('APPS.MAGMHOPRPT')
    error('You must call magMHopRptInit.m first to set up a connection.');
end

APPS.MAGMHOPRPT.reportThresh = reportThresh;
APPS.MAGMHOPRPT.numFadeIntervals = numFadeItvl;
APPS.MAGMHOPRPT.readFireInterval = readFireItvl;
APPS.MAGMHOPRPT.fadeFireInterval = fadeFireItvl;
APPS.MAGMHOPRPT.windowSize = winSize;
APPS.MAGMHOPRPT.reportInterval = rptItvl;