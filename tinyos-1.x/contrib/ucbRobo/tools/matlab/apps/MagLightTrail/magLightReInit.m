function magLightReInit
% Reinitializes the data structures used for logging.
%
%usage: magLightReInit

global APPS;
global DATA;

APPS.MAGLIGHT.logMsgFlag = false; %just to make sure

DATA.MAGLIGHT.reportMat = [];
