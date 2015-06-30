function testControls
% Leaves out the sensor network and just tests the controller and
% simulation of the Pursuer/Evader dynamics.  Similar to PEGSimMain.
%
% Put this file in the main simulator directory (or make sure your paths
% are set properly) to run it.
%
% remember to comment out any SN intialization/use (ex. PEGSimInit)

global P; % pursuer structure
global E; % evader structure
global T;
global dT;

Tfinal = 20;
T = 0;
dT = 0.1;
PEGSimInit; % args: P,E
%plotSN;
while (~checkCapture) && (T < Tfinal) % args: P,E
   T = T + dT;
   rcvpkts = [T 0 E.pos(1:2,end)' 0 T]'; %perfect information on Epos
   PpolicyNoSN(rcvpkts); % args: P,T
%   Epolicy; % args: E,T; For now, no evasive action
   PSimMove; % args: P,T
   ESimMove; % args: E,T
%   plotStepMotion; % args: P,E
end
plotMotion;

% IMPLEMENTATION NOTES:
% We use global variables for big data structures like P, E, SN in the
% hopes that not copying (pass by value) means it will run faster
