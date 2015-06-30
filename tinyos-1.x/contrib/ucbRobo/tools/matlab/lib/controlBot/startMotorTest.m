function startMotorTest(moteID)
% startMotorTest(moteID)
%
% Toggles LED on Mica Mote

global COTSBOTS;
global COMM;

if isempty(COTSBOTS)
    error('You must call controlBotInit.m first to set up a connection.');
end
if (nargin > 1)
    error('Usage: startMotorTest(moteID)');
end
if (nargin < 1)
    moteID = COMM.TOS_BCAST_ADDR;
end

RC = COTSBOTS.RC;
RobotMsg = RobotCmd.RobotCmdMsg;
RobotMsg.set_type(RC.MOTOR_TEST_START);
RobotMsg.set_data([0 0]);
send(moteID,RobotMsg);
RobotMsg
