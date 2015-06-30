function toptrack = mcmcda_tracking(Tnow,do_toptracking) 

% Copyright (c) 2003-2004 Songhwai Oh

global gvs;
if nargin<2, do_toptracking = 0; end

Tinit = max(1,Tnow-gvs.winsize+1);
gvs.yobs_win = gvs.yobs(Tinit:Tnow);
Tf = Tnow - Tinit + 1;
if Tnow>gvs.winsize
    Ts = ceil(Tf/2);
else
    Ts = 1;
end
nmcmc_now = gvs.nmcmc;
depth_now = min(gvs.depth,Tf);
minlen_now = min(gvs.minlen,Tf);

toptrack = [];
if Tnow>1
    if isempty(gvs.record.trackinfo.track)
        gvs.record.trackinfo = mcmcda_mex(gvs.mcmcda,gvs.yobs_win,Ts,Tf,nmcmc_now, ...
            depth_now,minlen_now,gvs.greedyinit,gvs.delta);
    else
        pt_siz = size(gvs.record.trackinfo.track);
        track0 = zeros(Tf,pt_siz(2));
        if Tinit<=gvs.record.trackinfo.times(2)
            pwin_ti = Tinit - gvs.record.trackinfo.times(1) + 1;
            pwin_len = pt_siz(1) - pwin_ti + 1;
            track0(1:pwin_len,:) = gvs.record.trackinfo.track(pwin_ti:pt_siz(1),:);
        end
        gvs.record.trackinfo = mcmcda_mex(gvs.mcmcda,gvs.yobs_win,Ts,Tf,nmcmc_now, ...
            depth_now,minlen_now,gvs.greedyinit,gvs.delta,track0);
    end
    gvs.record.trackinfo.times = [Tinit,Tnow];
    num_tracks = size(gvs.record.trackinfo.track,2);
    if do_toptracking & num_tracks>0
        toptrack.pos = cell(1,num_tracks);
        toptrack.loglik = zeros(1,num_tracks);
        toptrack.cov = cell(1,num_tracks);
        for k=1:num_tracks
            [toptrack.pos{k},toptrack.loglik(k),toptrack.cov{k}] = ...
                mykalmanfilter(size(gvs.yobs_win,2),gvs.record.trackinfo.track(:,k),...
                               gvs.record.trackinfo.xinit(:,k),gvs.yobs_win,0);
        end
    end
end 

