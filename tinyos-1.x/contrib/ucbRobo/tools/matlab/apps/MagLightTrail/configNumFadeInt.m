function configNumFadeInt(numFadeInt,moteID)
% configNumFadeInt(numFadeInt,moteID)
% Allows for command line configuration of number of intervals before an
% LED turns off.

global APPS;
global COMM;
MAGLIGHT = APPS.MAGLIGHT;


if isempty(MAGLIGHT)
    error('You must call magLightInit.m first to set up a connection.');
end
if (nargin < 2)
    moteID = COMM.TOS_BCAST_ADDR;
end

APPS.MAGLIGHT.numFadeIntervals = numFadeInt;
ConfigMsg = net.tinyos.RobotTB.MagLightTrail.MagQueryConfigMsg;
ConfigMsg.set_type(MAGLIGHT.CONFIGMSG);
ConfigMsg.set_resetNumFadeIntervals(MAGLIGHT.numFadeIntervals);
ConfigMsg.set_reportThresh(MAGLIGHT.reportThresh);
send(moteID,ConfigMsg);
ConfigMsg
