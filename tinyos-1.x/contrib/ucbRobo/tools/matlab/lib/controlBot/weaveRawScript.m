function weaveRawScript(robot1,robot2)
% weaveRawScript()
%
% Script using raw driving commands to drive 2 robots in a weaving
% pattern.  Robot1 is assumed to start from (0,0) while Robot2 is assumed
% to start from (0,200), both with a heading of 0.  The weaving motion
% proceeds from le
ft to right (increasing x-coordinate).
%
% navCmdArgs [[turn speed time moteID] ...]

% NOT USED
% persistent t1; % timer 1
% persistent t2; % timer 2

% moteIds of the two robots
if (nargin ~= 2)
robot1 = 1;
robot2 = 2;
disp(['robot moteIDs not fully specified... defaulting to ' ...
        sprintf('robot1:%d,  robot2:%d',...
        robot1,robot2)]);
end

initT = 0.5;
weaveL = 27;
weaveR = 36;
wSpeed1 = 25;
wSpeed2 = 30;
wTime = 3;

navCmdArgs1 = [
    % 1st command to start angled
    [40 25 initT robot1];
    % start weaving
    [weaveL wSpeed1 wTime robot1];
    [weaveR wSpeed1 wTime robot1];
];
navCmdArgs2 = [
    % 1st command to start angled
    [20 25 initT robot2]
    % start weaving;
    [weaveR wSpeed2 wTime robot2];
    [weaveL wSpeed2 wTime robot2];
];

for i=1:size(navCmdArgs1,1)
    a = navCmdArgs1(i,:)
    b = navCmdArgs2(i,:)
    turnRaw(a(1),a(2),a(3),a(4));
    turnRaw(b(1),b(2),b(3),b(4));
    pause(max(a(3),b(3)));
end

% NOTE:
% You cannot start two timers to emulate multithreading and use pause or
% wait in them... the timers created by these timers will not execute.  The
% example below does not work.
% t1 = timer('TimerFcn',{'rawScriptExec', navCmdArgs1}, 'StartDelay', 0);
% t2 = timer('TimerFcn',{'rawScriptExec', navCmdArgs2}, 'StartDelay', 0);
% %rawScriptExec(0,0,navCmdArgs1);
% start(t1);
% start(t2);
