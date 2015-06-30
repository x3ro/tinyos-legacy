function PEGSimMain(SNfile,PEfile,Pctrlrfile)
% The main module for the sensor network simulator.  This is a discrete
% time simulator.  The main loop is structured as follows:
% 1) Check for capture... stop if capture
% 2) Increment Time
% 3) Using the position of the pursuer(s) and evader(s), check if the
%     sensor network triggers any readings.  Calculate the readings.
% 4) Calculate/create the packets to pass into the pursuer
% 5) Calculate the pursuer(s) policy
% 6) Calculate the evader policy
% 7) Update the change in position of the pursuer/evader using the
%     vehicle dynamics and noise model
% 8) Repeat
% 
% The module can plot the motion of the pursuer/evader in real time, and
% can also save the trajectory and packet reports.
%
% IMPORTANT FLAGS: ReSimFlag
% ReSimFlag determines whether to resimulate Evader Motion using old 
% traces.  This flag is not altered in any of the files called by
% PEGSimMain (unless it does not exist, in which case it is set to false),
% and is meant to be altered by the batch simulation script or the user.
% Note that the value of the flag (1, 2, 3, etc.) choose the control cost
% function.
% * Affected data structures are SN and E/E_precomp.
% * It is the responsibility of the user calling PEGSimMain to save
%   E to Eprecomp before the resimulation
% * Remember to 

% Most values are listed for easy access when debugging
global Pctrlr; % pursuer controller structure
global P; % pursuer structure
global E; % evader structure
global Eprecomp; % for resimulation
global SN; % sensor network structure
global T;
global dT;
global history;
global ReSimFlag;

if isempty(ReSimFlag)
    ReSimFlag = 0;
end

Tfinal = 40;
T = 0;
dT = 0.5;

if (nargin == 3)
    PEGSimInit(SNfile,PEfile,Pctrlrfile);
elseif (nargin == 2)
    PEGSimInit(SNfile,PEfile);
elseif (nargin == 1)
    PEGSimInit(SNfile);
else
    PEGSimInit('examples/scen21_25x25_fixedSN.mat',...
               'examples/scen21_25x25_fixedPE.mat');
    %PEGSimInit('examples/nodes100_25x25_2.mat'); % args: SNfile, PEfile
end


while (~checkCapture) && (T < Tfinal) % args: P,E
   T = T + dT;

   %% Perfect Information from Sensor Network
   %    arrTime = T; delay = 0;
   %    packets = [0 E.pos(1:2,end)' 0 T]'; %perfect information on Epos
   %    rcvpkts = [arrTime ; packets];

   [delay packets] = SNSim_ralpha(1); % 1 = NoDelay
%  [delay packets] = SNSim_simple(1); % args: P,E,SN; output: negative delay
                                      % means dropped packet
   rcvpkts = pktQueue(delay,packets); % args: T
   %   plotRoute(rcvpkts);

   history.delay{end+1} = delay;
   history.packets{end+1} = packets;
   history.rcvpkts{end+1} = rcvpkts;

   %PpolicyLQG(rcvpkts); % args: P,T   
   PpolicyNonLinOpt(rcvpkts); % args: P,T
%   Epolicy; % args: E,T; For now, no evasive action
   PSimMove; % args: P,T
   ESimMove; % args: E,Eprecomp,T
%   plotStepMotion; % args: P,E
   drawnow;
   disp(sprintf('T = %d',T));
end
%plotSN;
plotMotion;

% IMPLEMENTATION NOTES:
% We use global variables for big data structures like P, E, SN in the
% hopes that not copying (pass by value) means it will run faster