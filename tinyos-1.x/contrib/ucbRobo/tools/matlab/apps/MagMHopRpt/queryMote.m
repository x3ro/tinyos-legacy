function queryMote(moteID)
% queryMote(moteID)
% Queries the report threshold and number of intervals before an LED turns
% off.

global APPS;
global COMM;
if exist('APPS') && isfield(APPS,'MAGMHOPRPT')
    MAGMHOPRPT = APPS.MAGMHOPRPT;
end
if ~exist('MAGMHOPRPT')
    error('You must call magMHopRptInit.m first to set up a connection.');
end
if (nargin < 1)
    moteID = COMM.TOS_BCAST_ADDR;
end

QueryMsg = net.tinyos.RobotTB.MagMHopRpt.MagQueryConfigBcastMsg;
QueryMsg.set_seqno(MAGMHOPRPT.bcast_seqNo);
APPS.MAGMHOPRPT.bcast_seqNo = mod(MAGMHOPRPT.bcast_seqNo+1,256);
QueryMsg.set_type(MAGMHOPRPT.QUERYMSG);
QueryMsg.set_targetMoteID(moteID);
send(COMM.TOS_BCAST_ADDR,QueryMsg); % we must NOT send to moteID
% Doing so may confuse MintRoute. See README.ucbRoboApps for a discussion.
QueryMsg