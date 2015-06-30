function setKp(Kp,moteID)
% setKp(Kp,moteID)
% Allows for command line configuration of COTSBOTS.

global COTSBOTS;
if isempty(COTSBOTS)
    error('You must call controlBotInit.m first to set up a connection.');
end
if (nargin ~= 2)
    error('Usage: setKp(Kp,moteID)');
end

RC = COTSBOTS.RC;
RobotMsg = RobotCmd.RobotCmdMsg;
RobotMsg.set_type(RC.SET_KP);
RobotMsg.set_data([Kp 0]);
send(moteID,RobotMsg);
RobotMsg
