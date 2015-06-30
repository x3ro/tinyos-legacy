function [x, y]=estimatePursuerPosition(readings)
%[x y]=estimatePursuerPosition(readings)
%
%this function takes the node IDs and tof readings sent to it
%and estimates the position of the evader

global PURSUER_EVADER

[x y]=averagePosition(readings(:,1));