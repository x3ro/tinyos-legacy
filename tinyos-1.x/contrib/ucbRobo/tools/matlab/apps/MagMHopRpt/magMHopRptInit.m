function magMHopRptInit(connString)
% Sets up the communication link to talk to SerialForwarder (suppose to be connected 
% to TOSBase) which broadcasts to motes running MagMHopRpt.  Also, 
% 1) initializes default values for the report threshold and the number of
%    intervals before the LED fades 
% 2) stores constants used by MagMsg.h
%
%usage: magMHopRptInit        % see genericInit() for default connections
%           magMHopRptInit('network@localhost:9000')
%           magMHopRptInit('serial@COM1')
%           magMHopRptInit('serial@COM1:mica2dot')
% cannot accept multiple arguments... if you want to open multiple
% connections, see genericInit()


global APPS;
global DATA;
global COMM;

% Variables specific to this application
MAGMHOPRPT.reportThresh = net.tinyos.RobotTB.MagMHopRpt.MagMHopRptConst.DEFAULT_REPORT_THRESH;
MAGMHOPRPT.numFadeIntervals = net.tinyos.RobotTB.MagMHopRpt.MagMHopRptConst.DEFAULT_NUM_FADE_INTERVALS;
MAGMHOPRPT.readFireInterval = net.tinyos.RobotTB.MagMHopRpt.MagMHopRptConst.DEFAULT_READ_FIRE_INTERVAL;
MAGMHOPRPT.fadeFireInterval = net.tinyos.RobotTB.MagMHopRpt.MagMHopRptConst.DEFAULT_FADE_FIRE_INTERVAL;
MAGMHOPRPT.windowSize = net.tinyos.RobotTB.MagMHopRpt.MagMHopRptConst.DEFAULT_WINDOW_SIZE;
MAGMHOPRPT.reportInterval = net.tinyos.RobotTB.MagMHopRpt.MagMHopRptConst.DEFAULT_REPORT_INTERVAL;
MAGMHOPRPT.QUERYMSG = net.tinyos.RobotTB.MagMHopRpt.MagMHopRptConst.QUERYMSG;
MAGMHOPRPT.CONFIGMSG = net.tinyos.RobotTB.MagMHopRpt.MagMHopRptConst.CONFIGMSG;
%MAGMHOPRPT.QUERYREPORTMSG = net.tinyos.RobotTB.MagMHopRpt.MagMHopRptConst.QUERYREPORTMSG;

% This structure is used by genericInit, receiveAllMsgs, and stopAllMsgs
%       Make sure you follow this format exactly (no typos, no extra fields under *.Comm), or you might get
%       weird error messages from matlab that don't correspond to the problem
MAGMHOPRPT.Comm.magQueryReportMsg.Msg = net.tinyos.RobotTB.MagMHopRpt.MagQueryRptMhopMsg;
MAGMHOPRPT.Comm.magQueryReportMsg.Handler = {'printQueryReportMsg_MagMHopRpt', 'updateQueryReportMsg_MagMHopRpt'}; %, 'logQueryReportMsg_MagMHopRpt'};
MAGMHOPRPT.Comm.magReportMsg.Msg = net.tinyos.RobotTB.MagMHopRpt.MagReportMhopMsg;
MAGMHOPRPT.Comm.magReportMsg.Handler = {'printMagReportMsg_MagMHopRpt', 'logMagReportMsg_MagMHopRpt','plotMagReportMsg_MagMHopRpt'};
MAGMHOPRPT.Comm.magDebugMsg.Msg = net.tinyos.RobotTB.MagMHopRpt.MagDebugMsg;
MAGMHOPRPT.Comm.magDebugMsg.Handler = {'printMagDebugMsg_MagMHopRpt'};
% useful flags to use by your message handlers.
MAGMHOPRPT.rptMsgFlag = false;
MAGMHOPRPT.logMsgFlag = false;
MAGMHOPRPT.dbgMsgFlag = false;
MAGMHOPRPT.rstConstOnRpt = false; % resets the global defaults on a Query Report Message
MAGMHOPRPT.bcast_seqNo = 0;


APPS.MAGMHOPRPT = MAGMHOPRPT; % for use by other generic functions

DATA.MAGMHOPRPT.reportMat = [];
if nargin < 1
    genericInit(MAGMHOPRPT);
else 
    genericInit(MAGMHOPRPT,connString);
end

% Alternatively, if you don't want to use genericInit and get all it's
% benefits:
% receive(MAGMHOPRPT.CommMsgs)
% receive('printQueryReportMsg_MagMHopRpt',magQueryReportMsg);
% receive('printMagReportMsg_MagMHopRpt',magReportMsg);
