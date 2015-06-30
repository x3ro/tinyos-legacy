function run_online_tracking(cfgfile,testdata,savedata,...
    doPEG,numPursuers,posPursuersX,posPursuersY,figname,moviefile)

% Copyright (c) 2003-2005 Songhwai Oh

global gvs G

% E.g. run_online_tracking('cory330-testbed.cfg','MAGMHOPRPT_1202005_1',[],0,[],[]); 
%      run_online_tracking('RFS36wired.cfg','../RFS36wired082005/RFS36wired_8202005_walk2s',[],0,[],[]);

if nargin<8
    figname = [];
    moviefile = [];
end

% setup
if isempty(cfgfile)
    cfgfile = 'cory330-testbed.cfg';
end
setup(cfgfile);

% data preprocessing
scen = load(testdata);
if strcmp(cfgfile,'cory330-testbed.cfg')
    reportMat = scen.dataStructure.reportMat;
else
    reportMat = scen.dataStructure;
end
[M,N] = size(reportMat);
rev_times = zeros(1,N);
if strcmp(cfgfile,'cory330-testbed.cfg')
    sampling_interval = 1.1;
    for n=1:N
        rev_times(n) = sum(reportMat(7:9,n).*[60*60;60;1]);
    end
    pad = 5;
    sampling_times = rev_times(1)-sampling_interval*(.5+1):sampling_interval:rev_times(end)+sampling_interval*(.5+pad);
    nsamples = length(sampling_times);
    n = 1;
    for t=1:nsamples
        yt = [];
        for m=n:N
            if rev_times(m)<=sampling_times(t) & rev_times(m)>sampling_times(t-1)
                match = find(gvs.sw.id==reportMat(1,m));
                if ~isempty(match)
                    yt = [yt; match];
                end
                n = n + 1;
            elseif rev_times(m)>sampling_times(t)
                break
            end
        end
        scen.ygold{t} = yt;
        scen.n(t) = size(yt,1);
    end   
elseif strcmp(cfgfile,'RFSmain.cfg')
    %%% based on simulation time (real-time)
    if isfield(scen,'gvs')
        scen.ygold = scen.gvs.yobs_raw;
    else
        Tmax = max(reportMat(11,:));
        for t=1:Tmax
            yt = [];
            n = 0;
            reps = find(reportMat(11,:)==t);
            for tt=1:length(reps)
                if reportMat(5,reps(tt))>=50
                    match = find(gvs.sw.id==reportMat(1,reps(tt)));
                    if ~isempty(match)
                        yt = [yt; match];
                        n = n + 1;
                    end
                end
            end
            scen.ygold{t} = yt;
            scen.n(t) = size(yt,1);
        end
    end
else
    %%% based on detection-times
    sampling_interval = 2^16;
    rev_times = reportMat(7,:);
    
    % get the first time
    vtimes = find(reportMat(7,:)>0);
    start_time = min(reportMat(7,vtimes));
    end_time = max(reportMat(7,vtimes));
    mytime = start_time;
    t = 1;
    for mytime=start_time:sampling_interval:end_time
        prev_times = find(reportMat(7,vtimes)<=mytime);
        if isempty(prev_times)
            range_1 = 1;
        else
            range_1 = vtimes(prev_times(end));
        end
        post_times = find(reportMat(7,vtimes)>mytime+sampling_interval);
        if isempty(post_times)
            range_2 = N;
        else 
            range_2 = vtimes(post_times(1))-1;
        end

        yt = [];
        for m=range_1:range_2
            match = find(gvs.sw.id==reportMat(1,m));
            if ~isempty(match)
                yt = [yt; match];
            end
        end
        scen.ygold{t} = yt;
        scen.n(t) = size(yt,1);
        fprintf('t=%d ny=%d mytime=%d\n',t,scen.n(t),mytime);
        t = t + 1;
    end    
    fprintf('percentage time-synched = %f\n',length(vtimes)/N);
end
Tall = length(scen.ygold);
gvs.scenfile = testdata;

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
    gvs.peg.Np = numPursuers; % number pursuers
    gvs.peg.dt = 1; % time-step
    %assigned in setup.m: gvs.peg.U = 1;  % thruster input magnitude
    gvs.peg.Vx = zeros(gvs.peg.Np,1); % pursuer velocity x component
    gvs.peg.Vy = zeros(gvs.peg.Np,1); % pursuer velocity y component
    gvs.peg.Px = posPursuersX;
        %(gvs.sw.SR(1,2)-gvs.sw.SR(1,1))*rand(gvs.peg.Np,1) + gvs.sw.SR(1,1); % pursuer position x component
    gvs.peg.Py = posPursuersY;
        %(gvs.sw.SR(2,2)-gvs.sw.SR(2,1))*rand(gvs.peg.Np,1) + gvs.sw.SR(2,1); % pursuer position y component
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

for t=1:Tall
    
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
        
    % run tracking and PEG
    toptrack = online_tracking(t);
    if doPEG & t>1
        [E2P,evaders] = dynamic_assignment(t,toptrack);
    else
        E2P = []; evaders = [];
    end
    
    % display
    display_mcmcda_gui(mcmcda_guihandles,t,plikM,doPEG,E2P,evaders,[],[]);
    if ~isempty(figname)
        set(gcf,'PaperPositionMode','auto');
        print('-djpeg100',sprintf('%s_t%03d',figname,t));
    end
    if ~isempty(moviefile)
        fm = getframe(gcf);
        mov = addframe(mov,fm);
    end
    
    elapsed_time(t) = cputime - start_time;
    
    fprintf('[%03d] raw=%d fuse=%d K=%d time=%fs\n',t,size(scen.ygold{t},1),size(gvs.yobs{t},1),...
        size(gvs.record.trackinfo.track,2),elapsed_time(t));
end
fprintf('[total time]=%fs\n',sum(elapsed_time));
if ~isempty(moviefile)
    mov = close(mov);
end

if ~isempty(savedata)
    save(savedata,'gvs');
end