function queryMote(moteID)
% queryMote(moteID)

global APPS;
global COMM;
if exist('APPS') && isfield(APPS,'MAGDIRECTBOT')
    MAGDIRECTBOT = APPS.MAGDIRECTBOT;
end
if ~exist('MAGDIRECTBOT')
    error('You must call magDirectBotInit.m first to set up a connection.');
end
if (nargin < 1)
    moteID = COMM.TOS_BCAST_ADDR;
end

QueryMsg = net.tinyos.RobotTB.MagLocalAggRpt.MagQueryConfigMsg;
QueryMsg.set_type(MAGDIRECTBOT.QUERYMSG);
send(moteID,QueryMsg);
QueryMsg