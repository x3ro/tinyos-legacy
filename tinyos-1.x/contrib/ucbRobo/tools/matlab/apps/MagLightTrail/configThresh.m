function configThresh(thresh,moteID)
% configThresh(thresh,moteID)
% Allows for command line configuration of magnetic sensor threshold.

global APPS;
global COMM;
MAGLIGHT = APPS.MAGLIGHT;


if isempty(MAGLIGHT)
    error('You must call magLightInit.m first to set up a connection.');
end
if (nargin < 2)
    moteID = COMM.TOS_BCAST_ADDR;
end

APPS.MAGLIGHT.reportThresh = thresh;
ConfigMsg = net.tinyos.RobotTB.MagLightTrail.MagQueryConfigMsg;
ConfigMsg.set_type(MAGLIGHT.CONFIGMSG);
ConfigMsg.set_resetNumFadeIntervals(MAGLIGHT.numFadeIntervals);
ConfigMsg.set_reportThresh(MAGLIGHT.reportThresh);
send(moteID,ConfigMsg);
ConfigMsg
