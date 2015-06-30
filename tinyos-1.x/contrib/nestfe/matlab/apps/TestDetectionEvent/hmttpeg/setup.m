function setup(cfgfile)

% Copyright (c) 2005 Songhwai Oh

global gvs G

% sensor network parameters
gvs.sw = read_swcfgfile(cfgfile);

% remove the path before the file name
% assumes no / or \ in filename
remStr = strrep(cfgfile,'\','/');
while ~isempty(remStr)
    [cfgFilename remStr] = strtok(remStr,'/');
end

switch cfgFilename
    case {'cory330-testbed.cfg'}
        gvs.sw.Rs = 2;
        unitlen = 1;
        gvs.sw.Pd = .8*ones(1,gvs.sw.N);
        gvs.sw.Pf = .1*ones(1,gvs.sw.N); 
        gvs.peg.Np = 2;
        gvs.peg.U = .2; 
        gvs.grid.num_min_detections = 1;
        gvs.grid.localmaxima_scale = gvs.sw.Rs*2;
        gvs.grid.min_fuse_cnt = (gvs.sw.Rs/2)^2*pi/4/unitlen;
        gvs.disp.num_min_detections_for_track = 1;
    case {'RFS36wired.cfg','RFSmain.cfg'}
        gvs.sw.Rs = 10;
        unitlen = 1;
        gvs.sw.Pd = .8*ones(1,gvs.sw.N);
        gvs.sw.Pf = .1*ones(1,gvs.sw.N); 
        gvs.peg.Np = 2;
        gvs.peg.U = .5; 
        gvs.peg.Px = [1 45]';
        gvs.peg.Py = [-5 -5]';
        gvs.grid.num_min_detections = 3;
        gvs.grid.localmaxima_scale = gvs.sw.Rs*2;
        gvs.grid.min_fuse_cnt = (gvs.sw.Rs/2)^2*pi/4/unitlen;
        gvs.grid.ratio_min_detections = 0;
        gvs.disp.num_min_detections_for_track = 3;
    otherwise
        error(['No setup is available for configuration ' cfgFilemame '.']);
end

gvs.sw.SR = [min(gvs.sw.pos(:,1)) max(gvs.sw.pos(:,1)); ...
             min(gvs.sw.pos(:,2)) max(gvs.sw.pos(:,2))]; 
% gvs.sw.SR(:,1) = gvs.sw.SR(:,1) - gvs.sw.Rs;
% gvs.sw.SR(:,2) = gvs.sw.SR(:,2) + gvs.sw.Rs; 

% detection grid parameters
gvs.grid.unitlen = unitlen;
gvs.grid.xN = floor((gvs.sw.SR(1,2)-gvs.sw.SR(1,1))/gvs.grid.unitlen);
gvs.grid.yN = floor((gvs.sw.SR(2,2)-gvs.sw.SR(2,1))/gvs.grid.unitlen);
gvs.grid.N = gvs.grid.xN * gvs.grid.yN;

% grid assignment
gvs.grid.sensV = cell(1,gvs.grid.N);
for n=1:gvs.grid.N
    [ix,iy] = ind2sub([gvs.grid.xN,gvs.grid.yN],n);
    distM = (gvs.sw.pos - repmat(gvs.grid.unitlen*[ix,iy],gvs.sw.N,1)).^2;
    distM = sqrt(sum(distM,2));
    gvs.grid.sensV{n} = find(distM<gvs.sw.Rs);
end

% % grid clustering
gvs.grid.cluster = [];
% for n=1:gvs.grid.N
%     curr_sensV = gvs.grid.sensV{n};
%     curr_sensV_len = length(curr_sensV);
%     old_cluster = 0;
%     for m=1:length(gvs.grid.cluster)
%         this_sensV = gvs.grid.sensV{gvs.grid.cluster{m}(1)};
%         if curr_sensV_len==length(this_sensV) & all(curr_sensV==this_sensV)
%             old_cluster = m;
%             break
%         end
%     end
%     if old_cluster>0
%         gvs.grid.cluster{old_cluster} = [gvs.grid.cluster{old_cluster},n];
%     else
%         gvs.grid.cluster{end+1} = n;
%     end
% end

% global variables for mcmc data association s
switch cfgFilename
    case {'cory330-testbed.cfg','RFS36wired.cfg','RFSmain.cfg'}
        gvs.mcmcda.ValR = 1*gvs.sw.Rs;    
        gvs.mcmcda.NTR = 2.0000e-005;    
        gvs.mcmcda.TTR = 1.0000e-005;     
        gvs.mcmcda.SRV = prod(gvs.sw.SR(:,2)-gvs.sw.SR(:,1));;     
        gvs.mcmcda.F_T = 1;     
        dT = gvs.mcmcda.F_T;
        gvs.mcmcda.Amat = [1 0 dT 0; 0 1 0 dT; 0 0 1 0; 0 0 0 1];
        gvs.mcmcda.Gmat = [dT^2/2 0; 0 dT^2/2; dT 0; 0 dT];
        gvs.mcmcda.Cmat = [1 0 0 0; 0 1 0 0];
        gvs.mcmcda.Qsgm = .1*[1;1];
        gvs.mcmcda.Qcov = diag(gvs.mcmcda.Qsgm.^2);
        gvs.mcmcda.Rsgm = gvs.sw.Rs/4*[1;1];
        gvs.mcmcda.Rcov = diag(gvs.mcmcda.Rsgm.^2);
        gvs.mcmcda.FAR = 1/gvs.mcmcda.SRV;    
        gvs.mcmcda.DP = .8;     
    otherwise
        error(['No setup is available for configuration ' setting '.']);
end
G = gvs.mcmcda;

% global variables for 'tracking'
gvs.T = 1;          % sampling period
gvs.winsize = 30;   % observation window size
gvs.nmcmc = 3000;   % number of samples per observation
gvs.depth = 15;
gvs.minlen = 3;
gvs.greedyinit = 0;
gvs.delta = 1;

% for display
gvs.disp.winsize = 20;
