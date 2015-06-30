function scen_tracking(testdata,savefile,nmcmc,winsize,showfig,stepon,make_movie,verbose)

% Copyright (c) 2003-2004 Songhwai Oh

global gvs G

scen = load(testdata);

[M,N] = size(scen.dataStructure.reportMat);

rev_times = zeros(1,N);
for n=1:N
    rev_times(n) = sum(scen.dataStructure.reportMat(7:9,n).*[60*60;60;1]);
end

pad = 2;
sampling_interval = 1.1;
sampling_times = rev_times(1)-sampling_interval*(.5+1):sampling_interval:rev_times(end)+sampling_interval*(.5+pad);
nsamples = length(sampling_times);

n = 1;
for t=1:nsamples
    yt = [];
    for m=n:N
        if rev_times(m)<=sampling_times(t) & rev_times(m)>sampling_times(t-1)
            x = floor(scen.dataStructure.reportMat(1,m)/10);
            y = mod(scen.dataStructure.reportMat(1,m),10);
            yt = [yt; x+1 y+1];
            n = n + 1;
        elseif rev_times(m)>sampling_times(t)
            break
        end
    end
    scen.ygold{t} = yt;
    scen.n(t) = size(yt,1);
end   

Tall = length(scen.ygold);
gvs.scenfile = testdata;
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
gvs.record.trackinfo = [];    % previos track information
gvs.record.trackinfo.track = [];
gvs.record.trackinfo.times = [0,0];
gvs.record.fulltrackinfo = [];
gvs.record.fulltrackinfo.track = [];

gvs.record.cputime = zeros(1,Tall);

if make_movie
    mov = avifile(savefile, 'fps',2,'compression', 'none');
end

for t=1:Tall
    
    % get observations
    gvs.yobs = scen.ygold(1:t);
    
    % tracking ... 
    gvs.record.cputime(t) = cputime;
    mcmcda_tracking(t,1);
    gvs.record.cputime(t) = cputime - gvs.record.cputime(t);
    
    %%% FULL TRACK
    Tnow = t;
    Tinit = max(1,Tnow-gvs.winsize+1);
    Tf = Tnow - Tinit + 1;
    if Tnow>gvs.winsize
        full_T = ceil(Tf/2);
        part_uT = ceil(Tf/2);
    else
        full_T = 1;
        part_uT = 1;
    end
    full_K = 0;
    if Tnow==gvs.winsize
        if ~isempty(gvs.record.trackinfo.track)
            [part_T,part_K] = size(gvs.record.trackinfo.track);
            full_T = ceil(gvs.winsize/2);
            kf = 0;
            for kp=1:part_K
                if any(gvs.record.trackinfo.track(1:full_T,kp)~=0)
                    kf = kf + 1;
                    gvs.record.fulltrackinfo.track(1:full_T,kf) = ...
                        gvs.record.trackinfo.track(1:full_T,kp);
                end
            end
        end
    elseif Tnow>gvs.winsize
        full_T = Tinit + ceil(Tf/2) - 2; 
        if ~isempty(gvs.record.fulltrackinfo.track)
            [full_T,full_K] = size(gvs.record.fulltrackinfo.track);
            gvs.record.fulltrackinfo.track(full_T+1,1:full_K) = 0;
        end
        [part_T,part_K] = size(gvs.record.trackinfo.track);
        for kf=1:full_K
            for kp=1:part_K
                vtrack = find(gvs.record.fulltrackinfo.track(:,kf)>0);
                full_tf = vtrack(length(vtrack));
                if full_tf>=Tinit
                    part_tf = full_tf-Tinit+1;
                    if gvs.record.fulltrackinfo.track(full_tf,kf) ...
                            == gvs.record.trackinfo.track(part_tf,kp)
                        if Tnow < Tall
                            gvs.record.fulltrackinfo.track(full_tf:full_T+1,kf) = ...
                                gvs.record.trackinfo.track(part_tf:part_uT,kp);
                        else
                            gvs.record.fulltrackinfo.track(full_tf:Tall,kf) = ...
                                gvs.record.trackinfo.track(part_tf:part_T,kp);
                        end
                    end
                end
            end
        end
        kf = full_K;
        for kp=1:part_K
            % add new tracks
            if all(gvs.record.trackinfo.track(1:part_uT-1,kp)==0) ...
                    && gvs.record.trackinfo.track(part_uT,kp)>0
                kf = kf + 1;
                if Tnow < Tall
                    gvs.record.fulltrackinfo.track(full_T+1,kf) = ...
                        gvs.record.trackinfo.track(part_uT,kp);
                else
                    gvs.record.fulltrackinfo.track(full_T+1:Tall,kf) = ...
                        gvs.record.trackinfo.track(part_uT:part_T,kp);
                end
            end
        end
        
    end
    if Tnow==Tall && ~isempty(gvs.record.fulltrackinfo.track)
        full_T = size(gvs.record.fulltrackinfo.track,1);
        if full_T<Tall
            gvs.record.fulltrackinfo.track(full_T+1:Tall,:) = 0;
        end
    end
    
    % plot
    if showfig & stepon
        if t==1, figure;
        else    clf;
        end
        axis([gvs.SR(1,1),gvs.SR(1,2),gvs.SR(2,1),gvs.SR(2,2)]);
        axis equal
        box on
        hold on
        for c=1:5
            for r=1:9
                plot(r,c,'k.','MarkerSize',15);
            end
        end
        if 0 %t==1
            view(0,-90)
            print('-djpeg100',sprintf('%s_layout',savefile));
        end
        if ~isempty(gvs.yobs{t})
            plot(gvs.yobs{t}(:,1),gvs.yobs{t}(:,2),'ro','Markersize',15,'LineWidth',2);
        end
        if ~isempty(gvs.record.trackinfo.track)
            for k=1:size(gvs.record.trackinfo.track,2)
                [dummy1,dummy2] = ...
                    mykalmanfilter(length(gvs.yobs_win),gvs.record.trackinfo.track(:,k),...
                        gvs.record.trackinfo.xinit(:,k),gvs.yobs_win,1,'b:',3);
            end
        end
        if ~isempty(gvs.record.fulltrackinfo.track)
            [full_T,full_K] = size(gvs.record.fulltrackinfo.track);
            fullxinit = zeros(4,full_K);
            for k=1:full_K
                fullxinit(:,k) = get_xinit(gvs.record.fulltrackinfo.track(:,k),gvs.yobs(1:full_T));
                [dummy1,dymmy2,dummy3] ...
                    = mykalmanfilter(full_T,gvs.record.fulltrackinfo.track(:,k),...
                        fullxinit(:,k),gvs.yobs(1:full_T),1,'r-',3);
            end
        end
        %view(0,-90)
        drawnow
        print('-djpeg50',sprintf('%s_t%02d',savefile,t));
        if make_movie
            f = getframe(gcf);
            mov = addframe(mov, f);
        end
        pause(.5)
    end
    if verbose & stepon
        fprintf('[%d] ny=%d K=%d time=%.02fs\n', t, size(gvs.yobs{t},1), ...
            size(gvs.record.trackinfo.track,2),gvs.record.cputime(t));
    end
%     if size(gvs.record.trackinfo.track,2)>0 | size(gvs.yobs{t},1)>0
%         stopme=1;
%     end
end
if make_movie
    mov = close(mov);
end
        
full_K = size(gvs.record.fulltrackinfo.track,2);
gvs.record.fulltrackinfo.xinit = zeros(4,full_K);
gvs.record.fulltrackinfo.loglik = zeros(1,full_K);
gvs.record.fulltrackinfo.xest = zeros(4,Tall,full_K);
gvs.record.fulltrackinfo.Pcov = zeros(4,4,Tall,full_K);

for k=1:full_K
    gvs.record.fulltrackinfo.xinit(:,k) = ...
        get_xinit(gvs.record.fulltrackinfo.track(:,k),gvs.yobs);
    [gvs.record.fulltrackinfo.xest(:,:,k),...
     gvs.record.fulltrackinfo.loglik(k),...
     gvs.record.fulltrackinfo.Pcov(:,:,:,k)] ...
        = mykalmanfilter(Tall,gvs.record.fulltrackinfo.track(:,k),...
          gvs.record.fulltrackinfo.xinit(:,k),gvs.yobs,0);
    % interpolate missing parts
    vtrack = find(gvs.record.fulltrackinfo.track(:,k)>0);
    vtrack_len = length(vtrack);
    for vt=2:vtrack_len
        d = vtrack(vt) - vtrack(vt-1); 
        if d>1
            x1 = gvs.record.fulltrackinfo.xest(1:2,vtrack(vt),k);
            x0 = gvs.record.fulltrackinfo.xest(1:2,vtrack(vt-1),k);
            for dt=1:d-1
                gvs.record.fulltrackinfo.xest(1:2,vtrack(vt-1)+dt,k) = x0 + (x1 - x0).*(dt/d);
            end
        end
    end
end
save(savefile,'gvs');

if showfig
    figure
    axis([gvs.SR(1,1),gvs.SR(1,2),gvs.SR(2,1),gvs.SR(2,2)]);
    axis equal
    box on
    hold on
    for c=1:5
        for r=1:9
            plot(r,c,'k.','MarkerSize',15);
        end
    end
    for t=1:Tall
        if ~isempty(gvs.yobs{t})
            plot(gvs.yobs{t}(:,1),gvs.yobs{t}(:,2),'ro','Markersize',15);
        end
    end
    markers = {'b+-','r+-','g+-','m+-','k+-','b+-','r+-','g+-','m+-','k+-'};
    if ~isempty(gvs.record.fulltrackinfo.track)
        for k=1:size(gvs.record.fulltrackinfo.track,2)
            [gvs.record.fulltrackinfo.xest(:,:,k),...
             gvs.record.fulltrackinfo.loglik(k),...
             gvs.record.fulltrackinfo.Pcov(:,:,:,k)] ...
                = mykalmanfilter(Tall,gvs.record.fulltrackinfo.track(:,k),...
                  gvs.record.fulltrackinfo.xinit(:,k),gvs.yobs,1,markers{k},3,sprintf('%d',k));
        end
    end
    drawnow
    %view(0,-90)
    print('-djpeg50',sprintf('%s',savefile));
end

