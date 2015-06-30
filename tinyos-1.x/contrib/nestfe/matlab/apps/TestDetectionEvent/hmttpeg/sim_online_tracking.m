function sim_online_tracking(trajfile,swobsfile,savedata,doPEG,figname,moviefile)

% Copyright (c) 2003-2005 Songhwai Oh

global gvs G

% E.g. sim_online_tracking('demo','demo_sw','demo_sw_mcmc',1,[],[]);

% setup
scen = load(trajfile);
load(swobsfile);

gvs.grid.num_min_detections = 3;
gvs.grid.localmaxima_scale = gvs.sw.Rs*2;
gvs.grid.min_fuse_cnt = (gvs.sw.Rs/2)^2*pi/4/gvs.grid.unitlen;
gvs.disp.num_min_detections_for_track = 3;
 
gvs.mcmcda.ValR = scen.gvs.ValR;    % max velocity x sampling period
gvs.mcmcda.NTR = scen.gvs.NTR;      % new target rate
gvs.mcmcda.TTR = scen.gvs.TTR;      % target termination rate
gvs.mcmcda.SRV = scen.gvs.SRV;      % surveillance region volume
gvs.mcmcda.F_T = scen.gvs.F_T;      % sampling period
gvs.mcmcda.Amat = scen.gvs.Amat;    % dynamic & observation model
gvs.mcmcda.Cmat = scen.gvs.Cmat;    % dynamic & observation model
gvs.mcmcda.Gmat = scen.gvs.Gmat;    % dynamic & observation model

gvs.mcmcda.FAR = 1/gvs.mcmcda.SRV;; % false alarm rate
gvs.mcmcda.DP = .8;

gvs.mcmcda.Qsgm = .2*[1;1];    % sqrt of process covariance
gvs.mcmcda.Qcov = diag(gvs.mcmcda.Qsgm.^2);          % process covariance
gvs.mcmcda.Rsgm = gvs.sw.Rs/4*[1;1];        % sqrt of observation covariance
gvs.mcmcda.Rcov = diag(gvs.mcmcda.Rsgm.^2); % observation covariance

G = gvs.mcmcda;

Tall = length(gvs.sw.raw.sy);
scen.ygold = gvs.sw.raw.sy; 

% global variables for 'tracking'
gvs.T = 1;          % sampling period
gvs.winsize = 20;   % observation window size
gvs.nmcmc = 3000;   % number of samples per observation
gvs.depth = 10;
gvs.minlen = 3;
gvs.greedyinit = 1;
gvs.delta = 1;

% global variables for 'tracking' outputs
gvs.yobs = [];              % fused measurements
gvs.yobs_raw = [];          % raw measurements
gvs.yobs_win = [];          % current observation window
gvs.record.trackinfo = [];  % previos track information
gvs.record.trackinfo.track = [];
gvs.record.trackinfo.times = [0,0];
gvs.record.fulltrackinfo = [];
gvs.record.fulltrackinfo.track = [];
gvs.record.cputime = zeros(1,Tall);

% global variables for PEG
if doPEG
    gvs.peg.Np = scen.gvs.M; % number pursuers
    gvs.peg.dt = 1; % time-step
    gvs.peg.U = 1;  % thruster input magnitude
    gvs.peg.Vx = zeros(gvs.peg.Np,1); % pursuer velocity x component
    gvs.peg.Vy = zeros(gvs.peg.Np,1); % pursuer velocity y component
    gvs.peg.Px = (gvs.sw.SR(1,2)-gvs.sw.SR(1,1))*rand(gvs.peg.Np,1) + gvs.sw.SR(1,1); % pursuer position x component
    gvs.peg.Py = (gvs.sw.SR(2,2)-gvs.sw.SR(2,1))*rand(gvs.peg.Np,1) + gvs.sw.SR(2,1); % pursuer position y component
    gvs.peg.ux = zeros(gvs.peg.Np,1);
    gvs.peg.uy = zeros(gvs.peg.Np,1);
end
    
close all
mcmcda_h = mcmcda_gui;
mcmcda_guihandles = guihandles(mcmcda_h);
init_displayTracks;
if ~isempty(moviefile)
    mov = avifile(moviefile,'fps',2,'compression','none');
end

elapsed_time = zeros(1,Tall);
elapsed_fusion_time = zeros(1,Tall);

for t=1:Tall
    
    if t==10
        stopme=1;
    end
    
    start_time = cputime;
    
    % get raw measurements
    gvs.yobs_raw{t} = unique(scen.ygold{t}); 
    
    % fuse measurements
    if ~isempty(gvs.yobs_raw{t})
        [fuseY,plikH,plikM] = fuse_detection(gvs.yobs_raw{t}); 
        %plikM = plikH;
    else
        fuseY = [];
        plikM = -inf*ones(gvs.grid.xN,gvs.grid.yN);
    end
    gvs.yobs{t} = fuseY;
    elapsed_fusion_time(t) = cputime - start_time;
        
    % run tracking and PEG
    toptrack = online_tracking(t);
    if doPEG & t>1
        [E2P,evaders] = dynamic_assignment(t,toptrack);
    else
        E2P = []; evaders = [];
    end
    
    % display
    display_mcmcda_gui(mcmcda_guihandles,t,plikM,doPEG,E2P,evaders,fuseY,[]);
    if ~isempty(figname)
        set(gcf,'PaperPositionMode','auto');
        print('-djpeg100',sprintf('%s_t%03d',figname,t));
    end
    if ~isempty(moviefile)
        fm = getframe(gcf);
        mov = addframe(mov,fm);
    end
    
    elapsed_time(t) = cputime - start_time;
    
    fprintf('[%03d] raw=%d fuse=%d K=%d time=%fs (%fs)\n',t,size(scen.ygold{t},1),size(gvs.yobs{t},1),...
        size(gvs.record.trackinfo.track,2),elapsed_time(t),elapsed_fusion_time(t));
end
fprintf('[total time]=%fs (%fs)\n',sum(elapsed_time),sum(elapsed_fusion_time));
if ~isempty(moviefile)
    mov = close(mov);
end

if ~isempty(savedata)
    save(savedata,'gvs');
end