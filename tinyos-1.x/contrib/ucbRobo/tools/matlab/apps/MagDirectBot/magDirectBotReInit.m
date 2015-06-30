function magDirectBotReInit
% Reinitializes the data structures used for logging.
%
%usage: magDirectBotReInit

global APPS;
global DATA;

APPS.MAGDIRECTBOT.logMsgFlag = false; %just to make sure

DATA.MAGDIRECTBOT.reportMat = [];
