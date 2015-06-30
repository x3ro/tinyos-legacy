function driveRaw_helper2(obj,event,moteID,direction,turn,speed,time)
% driveRaw_helper2(obj,event,moteid,direction,turn,speed,time)
%
% Helper function called by fwdRaw/turnRaw/revRaw, or some equivalent
% function.  Not meant to be called directly by the user. Sends a command to
% set the direction of the COTSBOT.
%
% A separate file because MATLAB uses global namespace when executing
% timers... no lexical scoping apparently.

global COTSBOTS;
global driveRaw_dat;

RC = COTSBOTS.RC;
% set speed and start timer
RobotMsg = RobotCmd.RobotCmdMsg;
RobotMsg.set_type(RC.SET_TURN);
RobotMsg.set_data([turn 0]);

j = find(driveRaw_dat.moteIndex == moteID);
if ~isvalid(driveRaw_dat.timer{j}(3))
  return; %Probably stopped by stopRaw
end
send(moteID,RobotMsg);
RobotMsg

start(driveRaw_dat.timer{j}(3));
