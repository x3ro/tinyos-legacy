function sampleNavScript(mote_id)
% sampleNavScript(mote_id)
%
% Sample script of navigation commands executed in tandem with pauses in
% between
%
% navCmdArgs [[x0 y0 x1 y1 heading] ...]

global COMM;

if nargin < 1
    mote_id = COMM.TOS_BCAST_ADDR; % cotsbot you wish to control
end
navCmdArgs = [
    [0 0, 1 0, 0];
    [1 0, 1 1, 0];
    [1 1, 0 1, 0];
    [0 1, 0 0, 0];
] * 100;

navCmdArgs = TestNavHack(navCmdArgs);

pause_int = 3; %wait 3 seconds
for i=1:size(navCmdArgs,1)
    a = navCmdArgs(i,:)
    nav(a(1),a(2),a(3),a(4),a(5),mote_id);
    pause(pause_int);
end

function [outvals] = TestNavHack(cmdArgs)
outvals = [cmdArgs(:,2) cmdArgs(:,1) cmdArgs(:,4) cmdArgs(:,3) cmdArgs(:,5)];
