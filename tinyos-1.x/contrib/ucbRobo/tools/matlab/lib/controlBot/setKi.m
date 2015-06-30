function setKi(Ki,moteID)
% setKi(Ki,moteID)
% Allows for command line configuration of COTSBOTS.

global COTSBOTS;
if isempty(COTSBOTS)
    error('You must call controlBotInit.m first to set up a connection.');
end
if (nargin ~= 2)
    error('Usage: setKi(Ki,moteID)');
end

RC = COTSBOTS.RC;
RobotMsg = RobotCmd.RobotCmdMsg;
RobotMsg.set_type(RC.SET_KI);
RobotMsg.set_data([Ki 0]);
send(moteID,RobotMsg);
RobotMsg
