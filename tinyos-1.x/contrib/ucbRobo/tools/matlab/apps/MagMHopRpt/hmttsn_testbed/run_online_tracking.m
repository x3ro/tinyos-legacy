function run_online_tracking(testdata,savedata)

% Copyright (c) 2003-2004 Songhwai Oh

global gvs G

nmcmc = 1000;
winsize = 10;

% data preprocessing
scen = load(testdata);
[M,N] = size(scen.dataStructure.reportMat);
rev_times = zeros(1,N);
for n=1:N
    rev_times(n) = sum(scen.dataStructure.reportMat(7:9,n).*[60*60;60;1]);
end
sampling_interval = 1.1;
pad = 5;
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

gvs.record.cputime = zeros(1,Tall);

for t=1:Tall
    
    % get observations
    gvs.yobs = scen.ygold(1:t);
    
    % run tracking
    showfig = 1;
    stepon = 1;
    verbose = 1;
    online_tracking(t,t+1,showfig,stepon,verbose);
    
end