function [xkmat] = gen_demo_trajectory(trajname)

% Copyright (c) 2003-2004 Songhwai Oh

global G

G.SR = [0 70; 0 95];
xtimes = [3 35; 3 35; 10 35];
xinits = [1 1 2 3; 69 1 -2 3; 1 60 3 0];

vmax = 5; vmin=1;
tmax = max(xtimes(:));
ntracks = size(xtimes,1);

G.M = ntracks;                     % max number of targets
G.TMAX = tmax;                     % number of time steps
%G.MIN_TRACK_LENGTH = tlen;
G.DIM = 4;                         % dimension of state space for targets
%G.L = L;
%G.SR = [0 G.L; 0 G.L];             % surveillance region
G.SRV = prod(G.SR(:,2)-G.SR(:,1)); % volume of surveillance region
%G.DP = min(dpr,.99);
%G.FAR = nfa/G.SRV;
G.NTR = ntracks/G.SRV/G.TMAX;
G.TTR = 1e-5;
G.BIRTH = G.TMAX;
G.LIFEXP = G.TMAX;

G.F_VEL_MAX   = vmax;
G.F_VEL_MIN   = vmin;
G.F_VEL_INIT  = vmin + .5*(vmax-vmin);

G.F_T = 1;
dT = G.F_T;
G.Amat = [1 0 dT 0; 0 1 0 dT; 0 0 1 0; 0 0 0 1];
G.Gmat = [dT^2/2 0; 0 dT^2/2; dT 0; 0 dT];
G.Cmat = [1 0 0 0; 0 1 0 0];
G.Qsgm = G.F_VEL_INIT/10*[1;1];
G.Qcov = diag(G.Qsgm.^2);
G.Rsgm = [1;1];
G.Rcov = diag(G.Rsgm.^2);
G.ValR = G.F_T*G.F_VEL_MAX;

xtrajs = cell(G.M,1);
xidmat = zeros(G.M,G.TMAX);

for m=1:G.M
    tracklen = xtimes(m,2)-xtimes(m,1)+1;
    xtrajs{m} = zeros(G.DIM,tracklen);
    xtrajs{m}(:,1) = xinits(m,:)';
    xidmat(m,xtimes(m,1):xtimes(m,2)) = 1;
    for t=2:tracklen
        xrnd = G.Gmat * (G.Qsgm.*randn(2,1));
        xtrajs{m}(:,t) = G.Amat*xtrajs{m}(:,t-1);% + xrnd;
    end
end
xkmat = sum(xidmat,1);

fprintf(' [ ');
for t=1:G.TMAX
    fprintf('%d ',sum(xidmat(:,t)>0));
end
fprintf(']\n');

plottraj(G.M,G.TMAX,xtimes,xtrajs,cell(1,G.TMAX));

gvs = G;
save(trajname,'gvs','xtrajs','xtimes','xidmat','xkmat');