function stopRaw(moteID)
% stopRaw(moteID)
%
% Allows for command line driving of COTSBOT.  Stops the COTSBOT.
%
% INPUTS: moteID                moteID of the robot we are controlling
%                               If omitted, we broadcast.
% Usage: stopRaw(1)             moteid = 1
%        stopRaw()              moteid = broadcast
%
% Although this code is written such that it is possible to have race
% conditions, it really shouldn't matter too much.  You might delete a
% running timer and get an error message (pretty harmless), a helper method
% might start a deleted timer and get an error message (also pretty
% harmless), or you might have to run the stopRaw command again if the
% COTSBOT doesn't stop, for instance.

global COTSBOTS;
global COMM;
global driveRaw_dat;

if isempty(COTSBOTS)
    error('You must call controlBotInit.m first to set up a connection.');
end
if (nargin < 1)
    moteID = COMM.TOS_BCAST_ADDR;
end

if ~isempty(driveRaw_dat)
    if (moteID == COMM.TOS_BCAST_ADDR)
        %broadcast address is special... stop all timers
        index = 1:length(driveRaw_dat.moteIndex);
    else
        index = find(driveRaw_dat.moteIndex == moteID);
    end
else
    index = [];
end

if ~isempty(index)
    for j = index % looping in case where we want to delete all
        for k = 1:size(driveRaw_dat.timer{j},2)
            if isvalid(driveRaw_dat.timer{j}(k))
                stop(driveRaw_dat.timer{j}(k));
                delete(driveRaw_dat.timer{j}(k)); % makes the timer invalid
            end
        end % for k
    end %for j
end

RC = COTSBOTS.RC;
% stop Robot
RobotMsg = RobotCmd.RobotCmdMsg;
RobotMsg.set_type(RC.SET_SPEED);
RobotMsg.set_data([RC.OFF 0]);
send(moteID,RobotMsg);
RobotMsg
