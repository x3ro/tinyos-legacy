function magMHopRptReInit
% Reinitializes the data structures used for logging.
%
%usage: magMHopRptReInit

global APPS;
global DATA;

APPS.MAGMHOPRPT.logMsgFlag = false; %just to make sure

DATA.MAGMHOPRPT.reportMat = [];
