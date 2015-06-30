function motorLedToggle(moteID)
% motorLedToggle(moteID)
%
% Toggles LED on Motor Mote

global COTSBOTS;
global COMM;

if isempty(COTSBOTS)
    error('You must call controlBotInit.m first to set up a connection.');
end
if (nargin > 1)
    error('Usage: motorLedToggle(moteID)');
end
if (nargin < 1)
    moteID = COMM.TOS_BCAST_ADDR;
end

RC = COTSBOTS.RC;
RobotMsg = RobotCmd.RobotCmdMsg;
RobotMsg.set_type(RC.LED_TOGGLE);
RobotMsg.set_data([0 0]);
send(moteID,RobotMsg);
RobotMsg
