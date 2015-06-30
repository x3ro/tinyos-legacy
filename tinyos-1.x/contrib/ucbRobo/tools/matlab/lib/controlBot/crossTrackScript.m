function crossTrackScript(robot1,robot2,robot3)
% crossTrackScript()
%
% Script using raw driving commands to drive 3 robots in a straight paths
% that cross.  Robot1 is assumed to start from (0,0) with a heading 1/2, 
% while Robot2 is assumed to start from (0,200) with a heading of 0 and 
% Robot3 is assumed to start from (0,400) with a heading of -1/2.

% moteIds of the two robots
if (nargin ~= 3)
robot1 = 1;
robot2 = 2;
robot3 = 3;
disp(['robot moteIDs not fully specified... defaulting to ' ...
        sprintf('robot1:%d,  robot2:%d, robot3:%d',...
        robot1,robot2,robot3)]);
end
speed1 = 25;
speed2 = 30;
speed3 = 35;
time = 2;

fwdRaw(speed1,time,robot1);
fwdRaw(speed2,time,robot2);
fwdRaw(speed3,time,robot3);


