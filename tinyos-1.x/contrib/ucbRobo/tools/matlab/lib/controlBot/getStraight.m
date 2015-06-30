function getStraight(moteID)
% getStraight(moteID)
% Allows for command line configuration of COTSBOTS.

global COTSBOTS;
if isempty(COTSBOTS)
    error('You must call controlBotInit.m first to set up a connection.');
end
if (nargin ~= 1)
    error('Usage: getStraight(moteID)');
end

RC = COTSBOTS.RC;
RobotMsg = RobotCmd.RobotCmdMsg;
RobotMsg.set_type(RC.GET_STRAIGHT);
RobotMsg.set_data([0 0]);
send(moteID,RobotMsg);
RobotMsg
