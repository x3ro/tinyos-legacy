function driveRaw_helper4(obj,event,moteID,direction,turn,speed,time)
% driveRaw_helper4(obj,event,moteid,direction,turn,speed,time)
%
% Helper function called by fwdRaw/turnRaw/revRaw, or some equivalent
% function.  Not meant to be called directly by the user. Sends a command to
% stop the COTSBOT (set the speed of the COTSBOT to 0).
%
% A separate file because MATLAB uses global namespace when executing
% timers... no lexical scoping apparently.

global COTSBOTS;
global driveRaw_dat;

RC = COTSBOTS.RC;
% set speed and start timer
RobotMsg = RobotCmd.RobotCmdMsg;
RobotMsg.set_type(RC.SET_SPEED);
RobotMsg.set_data([RC.OFF 0]);

j = find(driveRaw_dat.moteIndex == moteID);
if ~isvalid(driveRaw_dat.timer{j}(1))
  return; %Probably stopped by stopRaw
end
send(moteID,RobotMsg);
RobotMsg
