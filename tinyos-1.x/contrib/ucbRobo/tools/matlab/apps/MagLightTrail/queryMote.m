function queryMote(moteID)
% queryMote(moteID)
% Queries the report threshold and number of intervals before an LED turns
% off.

global APPS;
global COMM;
MAGLIGHT = APPS.MAGLIGHT;

if isempty(MAGLIGHT)
    error('You must call magLightInit.m first to set up a connection.');
end
if (nargin < 1)
    moteID = COMM.TOS_BCAST_ADDR;
end

QueryMsg = net.tinyos.RobotTB.MagLightTrail.MagQueryConfigMsg;
QueryMsg.set_type(MAGLIGHT.QUERYMSG);
send(moteID,QueryMsg);
QueryMsg