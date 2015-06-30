function setGlobalDefaults(reportThresh,readFireItvl,winSize,timeOut,staleAge,numFadeItvl,fadeFireItvl)
% setGlobalDefaults(reportThresh,readFireItvl,winSize,timeOut,staleAge,numFadeItvl,fadeFireItvl)
%
% Sets the global defaults for MAGDIRECTBOT

global APPS;

if ~exist('APPS.MAGDIRECTBOT')
    error('You must call magDirectBotInit.m first to set up a connection.');
end

APPS.MAGDIRECTBOT.reportThresh = reportThresh;
APPS.MAGDIRECTBOT.readFireInterval = readFireItvl;
APPS.MAGDIRECTBOT.windowSize = winSize;
APPS.MAGDIRECTBOT.timeOut = timeOut;
APPS.MAGDIRECTBOT.staleAge = staleAge;
APPS.MAGDIRECTBOT.numFadeIntervals = numFadeItvl;
APPS.MAGDIRECTBOT.fadeFireInterval = fadeFireItvl;
