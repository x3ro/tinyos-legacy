function configMoteD(paramArr,moteID)
% configMoteD(paramArr,moteID)
% Allows for command line configuration of motes, using global Defaults.
%
% paramArr    array of parameters to set into the fields
%             a value of -1 means keep the global default, which
%             is stored in APPS.MAGDIRECTBOT
% [reportThresh,readFireItvl,winSize,timeOut,staleAge,numFadeItvl,fadeFireItvl]
%
% usage: configMoteD([10 10 10 10 10 10 10]) % all motes
%        configMoteD([10 10 -1 -1 10 -1 10],3)
%
% SEE 'getGlobalDefaults', 'setGlobalDefaults'

global APPS;
global COMM;
if exist('APPS') && isfield(APPS,'MAGDIRECTBOT')
    MAGDIRECTBOT = APPS.MAGDIRECTBOT;
end
if ~(exist('MAGDIRECTBOT') == 1)
    error('You must call magDirectBotInit.m first to set up a connection.');
end
if ~isequal(size(paramArr),[1,7])
    error('paramArr: incorrect dimensions.  The dimensions must be 1x7');
end    
if (nargin < 2)
    moteID = COMM.TOS_BCAST_ADDR;
end

ConfigMsg = net.tinyos.RobotTB.MagLocalAggRpt.MagQueryConfigMsg;
ConfigMsg.set_type(MAGDIRECTBOT.CONFIGMSG);

if (paramArr(1) ~= -1)
    ConfigMsg.set_reportThresh(paramArr(1));
else
    ConfigMsg.set_reportThresh(MAGDIRECTBOT.reportThresh);
end

if (paramArr(2) ~= -1)
    ConfigMsg.set_readFireInterval(paramArr(2));
else
    ConfigMsg.set_readFireInterval(MAGDIRECTBOT.readFireInterval);
end

if (paramArr(3) ~= -1)
    ConfigMsg.set_windowSize(paramArr(3));
else
    ConfigMsg.set_windowSize(MAGDIRECTBOT.windowSize);
end

if (paramArr(4) ~= -1)
    ConfigMsg.set_timeOut(paramArr(4));
else
    ConfigMsg.set_timeOut(MAGDIRECTBOT.timeOut);
end

if (paramArr(5) ~= -1)
    ConfigMsg.set_staleAge(paramArr(5));
else
    ConfigMsg.set_staleAge(MAGDIRECTBOT.timeOut);
end

if (paramArr(6) ~= -1)
    ConfigMsg.set_resetNumFadeIntervals(paramArr(6));
else
    ConfigMsg.set_resetNumFadeIntervals(MAGDIRECTBOT.numFadeIntervals);
end

if (paramArr(7) ~= -1)
    ConfigMsg.set_fadeFireInterval(paramArr(7));
else
    ConfigMsg.set_fadeFireInterval(MAGDIRECTBOT.fadeFireInterval);
end

send(moteID,ConfigMsg); 
ConfigMsg
