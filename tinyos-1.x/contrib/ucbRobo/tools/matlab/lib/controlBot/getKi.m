function getKi(moteID)
% getKi(moteID)
% Allows for command line configuration of COTSBOTS.

global COTSBOTS;
if isempty(COTSBOTS)
    error('You must call controlBotInit.m first to set up a connection.');
end
if (nargin ~= 1)
    error('Usage: getKi(moteID)');
end

RC = COTSBOTS.RC;
RobotMsg = RobotCmd.RobotCmdMsg;
RobotMsg.set_type(RC.GET_KI);
RobotMsg.set_data([0 0]);
send(moteID,RobotMsg);
RobotMsg
