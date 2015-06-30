function driveRaw_helper3(obj,event,moteID,direction,turn,speed,time)
% driveRaw_helper3(obj,event,moteid,direction,turn,speed,time)
%
% Helper function called by fwdRaw/turnRaw/revRaw, or some equivalent
% function.  Not meant to be called directly by the user. Sends a command to
% move the COTSBOT (set the speed of the COTSBOT to a nonzero value).
%
% A separate file because MATLAB uses global namespace when executing
% timers... no lexical scoping apparently.

global COTSBOTS;
global driveRaw_dat;

RC = COTSBOTS.RC;
% set speed and start timer
RobotMsg = RobotCmd.RobotCmdMsg;
RobotMsg.set_type(RC.SET_SPEED);
RobotMsg.set_data([speed 0]);

j = find(driveRaw_dat.moteIndex == moteID);
if (length(driveRaw_dat.timer{j}) > 3)  && ...
      ~isvalid(driveRaw_dat.timer{j}(4))
  return; %Probably stopped by stopRaw
end
send(moteID,RobotMsg);
RobotMsg

if (length(driveRaw_dat.timer{j}) > 3)
  start(driveRaw_dat.timer{j}(4));
end

