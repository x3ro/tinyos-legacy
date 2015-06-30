function resetTurn(turn,moteID)
% resetTurn(turn,moteID)
%
% !!! Finish updating comments!!!
% Allows for command line reset of COTSBOT.  Drives with wheels turned
% at speed setting for a specified amount of time.
% Can be interrupted by stopRaw or other functions that call stopRaw
% (ex. turnRaw, revRaw).  May have race conditions, but that's okay (see
% stopRaw for details).  Also, can drive multiple robots at the same
% time.
%
% INPUTS: turn             Raw turn setting for COTSBOT
%         moteID                moteID of the robot we are controlling
%                               If omitted, we broadcast.
% Usage: turnRaw(20,50,2,1)     turn = 20, speed = 50, time = 2 sec, moteid = 1
%        turnRaw(40,50,0,0)     turn = 40, speed = 50, time = inf, 
%                               moteid = broadcast

% Uses driveRaw_helper<1..4> to help in 5 steps:
% 1) send a "stop/set speed = 0" message, done by calling stopRaw
% 2) send a "set direction" message (forward or reverse)
% 3) send a "set turn" message (straight)
% 4) send a "start/set speed" message
% 5) send a "stop/set speed = 0" message
  
global COTSBOTS;
global COMM;
global driveRaw_dat; % contains moteid -> index mapping and array of timers

if isempty(COTSBOTS)
    error('You must call controlBotInit.m first to set up a connection.');
end
if (nargin < 3)
    error('Wrong number of arguments: turnRaw(turn,speed,time,moteID)');
elseif (nargin < 4)
    moteID = COMM.TOS_BCAST_ADDR;
end

minDelay = COTSBOTS.driveRaw_minDelay;
RC = COTSBOTS.RC;

stopRaw(moteID); % deletes all timers & sends a stop message

if isempty(driveRaw_dat)
  j = [];
  driveRaw_dat.moteIndex = [];
  driveRaw_dat.timer = [];
else
  j = find(driveRaw_dat.moteIndex == moteID); % should be ONE
end

if isempty(j) % moteID was never inserted
    j = length(driveRaw_dat.timer)+1;
    driveRaw_dat.moteIndex(end+1) = moteID;
end


driveRaw_dat.timer{j}(1) = timer('TimerFcn',{'driveRaw_helper1', moteID, ...
  	    RC.FORWARD, turn, speed, time}, 'StartDelay', minDelay);
driveRaw_dat.timer{j}(2) = timer('TimerFcn',{'driveRaw_helper2', moteID, ...
	    RC.FORWARD, turn, speed, time}, 'StartDelay', minDelay);
driveRaw_dat.timer{j}(3) = timer('TimerFcn',{'driveRaw_helper3', moteID, ...
	    RC.FORWARD, turn, speed, time}, 'StartDelay', minDelay);
if (time ~= 0)
  driveRaw_dat.timer{j}(4) = timer('TimerFcn',{'driveRaw_helper4', moteID, ...
	    RC.FORWARD, turn, speed, time}, 'StartDelay', time);
elseif (length(driveRaw_dat.timer{j}) >= 4)
  driveRaw_dat.timer{j}(4) = [];  % interpret this as infinite time.
end

start(driveRaw_dat.timer{j}(1)) % start the first timer
