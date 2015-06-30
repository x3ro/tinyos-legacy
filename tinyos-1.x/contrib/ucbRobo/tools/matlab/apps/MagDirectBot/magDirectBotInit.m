function magDirectBotInit(connString)
% Sets up the communication link to talk to SerialForwarder (suppose to be connected 
% to TOSBase) which broadcasts to motes running MagLocalAggRpt.  Also, 
% 1) initializes default values for the report threshold and the number of
%    intervals before the LED fades 
% 2) stores constants used by MagMsg.h
%
%usage: magDirectBotInit        % see genericInit() for default connections
%           magDirectBotInit('network@localhost:9000')
%           magDirectBotInit('serial@COM1')
%           magDirectBotInit('serial@COM1:mica2dot')
% cannot accept multiple arguments... if you want to open multiple
% connections, see genericInit()


global APPS;
global DATA;
global COMM;

% Variables specific to this application
MAGDIRECTBOT.reportThresh = net.tinyos.RobotTB.MagLocalAggRpt.MagLocalAggRptConst.DEFAULT_REPORT_THRESH;
MAGDIRECTBOT.readFireInterval = net.tinyos.RobotTB.MagLocalAggRpt.MagLocalAggRptConst.DEFAULT_READ_FIRE_INTERVAL;
MAGDIRECTBOT.windowSize = net.tinyos.RobotTB.MagLocalAggRpt.MagLocalAggRptConst.DEFAULT_WINDOW_SIZE;
MAGDIRECTBOT.timeOut = net.tinyos.RobotTB.MagLocalAggRpt.MagLocalAggRptConst.DEFAULT_TIMEOUT;
MAGDIRECTBOT.staleAge = net.tinyos.RobotTB.MagLocalAggRpt.MagLocalAggRptConst.DEFAULT_STALEAGE;
MAGDIRECTBOT.numFadeIntervals = net.tinyos.RobotTB.MagLocalAggRpt.MagLocalAggRptConst.DEFAULT_NUM_FADE_INTERVALS;
MAGDIRECTBOT.fadeFireInterval = net.tinyos.RobotTB.MagLocalAggRpt.MagLocalAggRptConst.DEFAULT_FADE_FIRE_INTERVAL;
MAGDIRECTBOT.QUERYMSG = net.tinyos.RobotTB.MagLocalAggRpt.MagLocalAggRptConst.QUERYMSG;
MAGDIRECTBOT.CONFIGMSG = net.tinyos.RobotTB.MagLocalAggRpt.MagLocalAggRptConst.CONFIGMSG;
MAGDIRECTBOT.QUERYREPORTMSG = net.tinyos.RobotTB.MagLocalAggRpt.MagLocalAggRptConst.QUERYREPORTMSG;


% This structure is used by genericInit, receiveAllMsgs, and stopAllMsgs
%       Make sure you follow this format exactly (no typos, no extra fields under *.Comm), or you might get
%       weird error messages from matlab that don't correspond to the problem
MAGDIRECTBOT.Comm.magQueryReportMsg.Msg = net.tinyos.RobotTB.MagLocalAggRpt.MagQueryConfigMsg;
MAGDIRECTBOT.Comm.magQueryReportMsg.Handler = {'printQueryReportMsg_MagDirectBot', 'updateQueryReportMsg_MagDirectBot'}; %, 'logQueryReportMsg_MagDirectBot'};
MAGDIRECTBOT.Comm.magReportMsg.Msg = net.tinyos.RobotTB.MagLocalAggRpt.MagReportMsg;
MAGDIRECTBOT.Comm.magReportMsg.Handler = {'printMagReportMsg_MagDirectBot','logMagReportMsg_MagDirectBot','plotMagReportMsg_MagDirectBot'};
MAGDIRECTBOT.Comm.magLeaderReportMsg.Msg = net.tinyos.RobotTB.MagLocalAggRpt.MagLeaderReportMsg;
MAGDIRECTBOT.Comm.magLeaderReportMsg.Handler = {'printMagLeaderReportMsg_MagDirectBot','plotMagLeaderReportMsg_MagDirectBot'};% 'logMagLeaderReportMsg_MagDirectBot',
%MAGDIRECTBOT.Comm.magDebugMsg.Msg = net.tinyos.RobotTB.MagLocalAggRpt.MagDebugMsg;
%MAGDIRECTBOT.Comm.magDebugMsg.Handler = {'printMagDebugMsg_MagDirectBot'};
% useful flags to use by your message handlers.
MAGDIRECTBOT.rptMsgFlag = false;
MAGDIRECTBOT.plotMsgFlag = false;
MAGDIRECTBOT.logMsgFlag = false;
%MAGDIRECTBOT.dbgMsgFlag = false;
MAGDIRECTBOT.rstConstOnRpt = false; % resets the global defaults on a Query Report Message


APPS.MAGDIRECTBOT = MAGDIRECTBOT; % for use by other generic functions

DATA.MAGDIRECTBOT.reportMat = [];
if nargin < 1
    genericInit(MAGDIRECTBOT);
else 
    genericInit(MAGDIRECTBOT,connString);
end
