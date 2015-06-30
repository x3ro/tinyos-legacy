function configMoteD(paramArr,moteID)
% configMoteD(paramArr,moteID)
% Allows for command line configuration of motes, using global Defaults.
%
% paramArr    array of parameters to set into the fields
%             a value of -1 means keep the global default, which
%             is stored in APPS.MAGMHOPRPT
% [reportThresh,winSize,rptItvl,readFireItvl,fadeFireItvl,numFadeItvl]
%
% usage: configMoteD([10 10 10 10 10 10]) % all motes
%        configMoteD([10 10 -1 -1 10 -1],3)
%
% SEE 'getGlobalDefaults', 'setGlobalDefaults'

global APPS;
global COMM;
if exist('APPS') && isfield(APPS,'MAGMHOPRPT')
    MAGMHOPRPT = APPS.MAGMHOPRPT;
end
if ~exist('MAGMHOPRPT')
    error('You must call magMHopRptInit.m first to set up a connection.');
end
if ~isequal(size(paramArr),[1,6])
    error('paramArr: incorrect dimensions.  The dimensions must be 1x6');
end    
if (nargin < 2)
    moteID = COMM.TOS_BCAST_ADDR;
end

ConfigMsg = net.tinyos.RobotTB.MagMHopRpt.MagQueryConfigBcastMsg;
ConfigMsg.set_seqno(MAGMHOPRPT.bcast_seqNo);
APPS.MAGMHOPRPT.bcast_seqNo = mod(MAGMHOPRPT.bcast_seqNo+1,256);
ConfigMsg.set_type(MAGMHOPRPT.CONFIGMSG);
ConfigMsg.set_targetMoteID(moteID);

if (paramArr(1) ~= -1)
    ConfigMsg.set_reportThresh(paramArr(1));
else
    ConfigMsg.set_reportThresh(MAGMHOPRPT.reportThresh);
end

if (paramArr(2) ~= -1)
    ConfigMsg.set_windowSize(paramArr(2));
else
    ConfigMsg.set_windowSize(MAGMHOPRPT.windowSize);
end

if (paramArr(3) ~= -1)
    ConfigMsg.set_reportInterval(paramArr(3));
else
    ConfigMsg.set_reportInterval(MAGMHOPRPT.reportInterval);
end

if (paramArr(4) ~= -1)
    ConfigMsg.set_readFireInterval(paramArr(4));
else
    ConfigMsg.set_readFireInterval(MAGMHOPRPT.readFireInterval);
end

if (paramArr(5) ~= -1)
    ConfigMsg.set_fadeFireInterval(paramArr(5));
else
    ConfigMsg.set_fadeFireInterval(MAGMHOPRPT.fadeFireInterval);
end

if (paramArr(6) ~= -1)
    ConfigMsg.set_numFadeIntervals(paramArr(6));
else
    ConfigMsg.set_numFadeIntervals(MAGMHOPRPT.numFadeIntervals);
end

send(COMM.TOS_BCAST_ADDR,ConfigMsg); % we must NOT send to moteID
% Doing so may confuse MintRoute. See README.ucbRoboApps for a discussion.
ConfigMsg
