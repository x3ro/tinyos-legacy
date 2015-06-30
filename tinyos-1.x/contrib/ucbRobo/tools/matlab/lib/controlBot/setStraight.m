function setStraight(straight,moteID)
% setStraight(straight,moteID)
% Allows for command line configuration of COTSBOTS.

global COTSBOTS;
if isempty(COTSBOTS)
    error('You must call controlBotInit.m first to set up a connection.');
end
if (nargin ~= 2)
    error('Usage: setStraight(straight,moteID)');
end

RC = COTSBOTS.RC;
RobotMsg = RobotCmd.RobotCmdMsg;
RobotMsg.set_type(RC.SET_STRAIGHT);
RobotMsg.set_data([straight 0]);
send(moteID,RobotMsg);
RobotMsg
