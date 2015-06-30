function startOnlineTracking(nmcmc,winsize)
% startOnlineTracking(nmcmc,winsize)
% This function uses the hmttsn_testbed package to run an online tracking
% algorithm as the sensor network is gathering data with the MagMHopRpt
% application.
%
% Only data received AFTER running 'startOnlineTracking' will be used in
% the tracking algorithm.
%
% The hmttsn_testbed package can be obtained from Songhwai Oh
%
% SUGGESTIONS:
% 1) Make sure that DATA.MAGMHOPRPT.reportMat is not too big
% 2) Due to the low update frequency, the way the measurements are binned
%    is _critical_ to the outcome of the algorithm.  Sensors typically have a
%    a quiet period after they first report before they report again.  Thus,
%    the starting time of your targets is critical to the phase of receiving
%    the updates from two sensors.  It may be best to start your targets 
%    moving at the same time to keep them in phase.
% 3) Assuming 2 targets: Even if you start the two targets at the same
%    time, the two targets may be split into two bins if the online
%    tracking update period falls between the times of receiving the two
%    measurements.  Hacks may be made to make this work (shifting the phase
%    of the online tracking updates).
%
% INPUTS: nmcmc and winsize are parameters to hmttsn_testbed
%
% (Credit: Based off of run_online_tracking in hmttsn_testbed)


global APPS DATA MTT; %multi-target tracking run-online variables
clear global gvs; clear global G;
global gvs G; %hmttsn_testbed

if ~(exist('APPS') && isfield(APPS,'MAGMHOPRPT'))
    error('You must call magMHopRptInit.m first to set up a connection.');
end

if ~(exist('online_tracking') == 2)
    error('Make sure your MATLAB path contains the hmttsn_testbed directory.');
end

MTT.maxExecute = 100; % Maximum number of times to run; prevents runaway process
MTT.period = 0.6; %1.1; % Time between calling the tracking algorithm.  Make this larger
                % than MTT.samp_int.
MTT.running = true; % To prevent accidental user calling 'callOnlineTracking'
MTT.lastObsInd = size(DATA.MAGMHOPRPT.reportMat,2); % bookeeping for identifying 
                                                    % new data for tracking

if (nargin < 1)
    nmcmc = 1000;
end
if (nargin < 2)
    winsize = 10;
end


% global variables
gvs.SR = [0 10; 0 6];  

% global variables for mcmc data association
gvs.mcmcda.ValR = 2;    
gvs.mcmcda.NTR = 2.0000e-005;    
gvs.mcmcda.TTR = 1.0000e-005;     
gvs.mcmcda.SRV = prod(gvs.SR(:,2)-gvs.SR(:,1));;     
gvs.mcmcda.F_T = 1;     
dT = gvs.mcmcda.F_T;
gvs.mcmcda.Amat = [1 0 dT 0; 0 1 0 dT; 0 0 1 0; 0 0 0 1];
gvs.mcmcda.Gmat = [dT^2/2 0; 0 dT^2/2; dT 0; 0 dT];
gvs.mcmcda.Cmat = [1 0 0 0; 0 1 0 0];
gvs.mcmcda.Qsgm = [.2;.2];
gvs.mcmcda.Qcov = diag(gvs.mcmcda.Qsgm.^2);
gvs.mcmcda.Rsgm = [.1;.1];
gvs.mcmcda.Rcov = diag(gvs.mcmcda.Rsgm.^2);
gvs.mcmcda.FAR = 0.00001;    
gvs.mcmcda.DP = .95;     

G = gvs.mcmcda;

% global variables for 'tracking'
gvs.T = 1;              % sampling period
gvs.winsize = winsize;  % observation window size
gvs.nmcmc = nmcmc;      % number of samples per observation
gvs.depth = winsize;
gvs.minlen = 3;
gvs.greedyinit = 0;
gvs.delta = 1;
gvs.yobs_win = []; % current observation window
gvs.record.trackinfo = [];    % previous track information
gvs.record.trackinfo.track = [];
gvs.record.trackinfo.times = [0,0];
gvs.record.fulltrackinfo = [];
gvs.record.fulltrackinfo.track = [];


MTT.timer = timer('TimerFcn','callOnlineTracking', ...
                  'ExecutionMode','fixedRate','Period', MTT.period,...
                  'TasksToExecute',MTT.maxExecute);

start(MTT.timer);