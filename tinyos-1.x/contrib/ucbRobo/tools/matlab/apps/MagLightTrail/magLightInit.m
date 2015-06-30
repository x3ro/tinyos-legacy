function magLightInit(connString)
% Sets up the communication link to talk to SerialForwarder (suppose to be connected 
% to TOSBase) which broadcasts to motes running MagLightTrail.  Also, 
% 1) initializes default values for the report threshold and the number of
%    intervals before the LED fades 
% 2) stores constants used by MagMsg.h
%
%usage: magLightInit        % see genericInit() for default connections
%           magLightInit('network@localhost:9000')
%           magLightInit('serial@COM1')
%           magLightInit('serial@COM1:mica2dot')
% cannot accept multiple arguments... if you want to open multiple
% connections, see genericInit()


global APPS;
global DATA;
global COMM;

% Variables specific to this application
MAGLIGHT.reportThresh = 600; % should get from ncg
MAGLIGHT.numFadeIntervals = 2; % should get from ncg
MAGLIGHT.readFireInterval = 50; % should get from ncg
MAGLIGHT.fadeFireInterval = 500; % should get from ncg
MAGLIGHT.AM_MAGREPORTMSG = net.tinyos.RobotTB.MagLightTrail.MagLightConst.AM_MAGREPORTMSG;
MAGLIGHT.AM_MAGQUERYCONFIGMSG = net.tinyos.RobotTB.MagLightTrail.MagLightConst.AM_MAGQUERYCONFIGMSG;
MAGLIGHT.QUERYMSG = net.tinyos.RobotTB.MagLightTrail.MagLightConst.QUERYMSG;
MAGLIGHT.CONFIGMSG = net.tinyos.RobotTB.MagLightTrail.MagLightConst.CONFIGMSG;
MAGLIGHT.QUERYREPORTMSG = net.tinyos.RobotTB.MagLightTrail.MagLightConst.QUERYREPORTMSG;

% This structure is used by genericInit, receiveAllMsgs, and stopAllMsgs
%       Make sure you follow this format exactly (no typos, no extra fields under *.Comm), or you might get
%       weird error messages from matlab that don't correspond to the problem
MAGLIGHT.Comm.magQueryReportMsg.Msg = net.tinyos.RobotTB.MagLightTrail.MagQueryConfigMsg;
MAGLIGHT.Comm.magQueryReportMsg.Handler = {'printQueryReportMsg_MagLightTrail'}%, 'logQueryReportMsg'};
MAGLIGHT.Comm.magReportMsg.Msg = net.tinyos.RobotTB.MagLightTrail.MagReportMsg;
MAGLIGHT.Comm.magReportMsg.Handler = {'printMagReportMsg_MagLightTrail', 'logMagReportMsg_MagLightTrail'};
% useful flags to use by your message handlers.
MAGLIGHT.rptMsgFlag = false;
MAGLIGHT.logMsgFlag = false;


APPS.MAGLIGHT = MAGLIGHT; % for use by other generic functions

%DATA.MAGLIGHT = struct([]);
DATA.MAGLIGHT.reportMat = [];
if nargin < 1
    genericInit(MAGLIGHT);
else 
    genericInit(MAGLIGHT,connString);
end

% Alternatively, if you don't want to use genericInit and get all it's
% benefits:
% receive(MAGLIGHT.CommMsgs)
% receive('printQueryReportMsg_MagLightTrail',magQueryReportMsg);
% receive('printMagReportMsg_MagLightTrail',magReportMsg);
