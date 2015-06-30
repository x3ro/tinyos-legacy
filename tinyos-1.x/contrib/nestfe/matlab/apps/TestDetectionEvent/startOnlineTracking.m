function startOnlineTracking(cfgfile,doPEG_input)
% startOnlineTracking(cfgfile)
% This function uses the hmttsn_testbed package to run an online tracking
% algorithm as the sensor network is gathering data with the
% TestDetectionEvent application.
%
% Only data received AFTER running 'startOnlineTracking' will be used in
% the tracking algorithm.
%
% The hmttsn_testbed package can be obtained from Songhwai Oh
%
% SUGGESTIONS:
% 1) Make sure that MTT.reportMat is not too big
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
% (Credit: Based off of run_online_tracking in hmttsn_testbed)


global MTT; %multi-target tracking run-online variables
clear global gvs; clear global G;
global gvs G; %hmttsn_testbed
global doPEG;

if ~(exist('online_tracking') == 2)
    error('Make sure your MATLAB path contains the hmttsn_testbed directory.');
end

doPEG = doPEG_input;

MTT.logOnStop = true;
MTT.maxExecute = 1000; % Maximum number of times to run; prevents runaway process
MTT.period = 2;%1.1; % Time between calling the tracking algorithm.  Make this larger
                % than MTT.samp_int.
MTT.running = true; % To prevent accidental user calling 'callOnlineTracking'
MTT.reportMat = [];
MTT.lastObsInd = size(MTT.reportMat,2); % bookeeping for identifying 
                                        % new data for tracking

setup(cfgfile);

% global variables for 'tracking' outputs
gvs.yobs = [];              % fused measurements
gvs.yobs_raw = [];          % raw measurements
gvs.yobs_win = [];          % current observation window
gvs.record.trackinfo = [];  % previos track information
gvs.record.trackinfo.track = [];
gvs.record.trackinfo.times = [0,0];
gvs.record.fulltrackinfo = [];
gvs.record.fulltrackinfo.track = [];

% global variables for PEG
if doPEG
    %assigned in setup.m: gvs.peg.Np = scen.gvs.M; % number pursuers
    gvs.peg.dt = 1; % time-step
    %assigned in setup.m: gvs.peg.U = 1;  % thruster input magnitude
    gvs.peg.Vx = zeros(gvs.peg.Np,1); % pursuer velocity x component
    gvs.peg.Vy = zeros(gvs.peg.Np,1); % pursuer velocity y component
    if ~isfield(gvs.peg,'Px')
        gvs.peg.Px = (gvs.sw.SR(1,2)-gvs.sw.SR(1,1))*rand(gvs.peg.Np,1) + gvs.sw.SR(1,1);
        gvs.peg.Py = (gvs.sw.SR(2,2)-gvs.sw.SR(2,1))*rand(gvs.peg.Np,1) + gvs.sw.SR(2,1);
    end
    gvs.peg.ux = zeros(gvs.peg.Np,1);
    gvs.peg.uy = zeros(gvs.peg.Np,1);
end

close all
mcmcda_h = mcmcda_gui;
gvs.mcmcda_guihandles = guihandles(mcmcda_h);
init_displayTracks;

MTT.timer = timer('Name','Online Tracking Timer', ...
                  'TimerFcn','callOnlineTracking', ...
                  'ExecutionMode','fixedRate','Period', MTT.period,...
                  'TasksToExecute',MTT.maxExecute);

start(MTT.timer);
