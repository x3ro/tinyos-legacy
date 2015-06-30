function callOnlineTracking
% callOnlineTracking (no arguments)
% Function periodically fired by a timer that calls the hmttsn_testbed
% online_tracking() function.  Do not call this function directly.
%
% (Credits: Based off of run_online_tracking in hmttsn_testbed)
%
% See 'startOnlineTracking' and 'stopOnlineTracking' for details

global MTT;
global gvs; % from hmttsn_testbed
global doPEG;

if ~(isfield(MTT,'running') && MTT.running)
    error('You cannot call ''callOnlineTracking'' directly');
end

callNo = get(MTT.timer,'TasksExecuted'); %Number of time intervals that have passed

if (callNo == MTT.maxExecute) %last call
    MTT.running = false;
    delete(MTT.timer);
end


%%% hmttsn_testbed actually performs very differently depending on whether
%%% you start with zero observations vs. starting with your first
%%% observation
% if isempty(DATA.MAGMHOPRPT.reportMat) %no data yet
%     return;
% end

% Multiple packets (corresponding to multiple detections) may arrive per time interval.

yt = [];
newDat = MTT.reportMat(:,MTT.lastObsInd+1:end);
MTT.reportMat(11,MTT.lastObsInd+1:end) = -1;
MTT.lastObsInd = size(MTT.reportMat,2);

% Data Processing: Node ID is 1st field
% Note that hmttsn_testbed uses only node ID and report time
for m = 1:size(newDat,2)
    for k=1:gvs.sw.N
        if all(gvs.sw.id(k)==newDat(1,m)) %& newDat(5,m)>= 50
            MTT.reportMat(11,MTT.lastObsInd+m) = length(gvs.yobs)+1;
            yt = [yt; k];
            break
        end
    end
end

if isfield(gvs,'yobs')
    len = length(gvs.yobs);
else 
    len = 0;
end
t = len+1;
% get raw measurements
gvs.yobs_raw{t} = unique(yt); 
% fuse measurements
if ~isempty(gvs.yobs_raw{t})
    [fuseY,plikH,plikM] = fuse_detection(gvs.yobs_raw{t}); 
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
display_mcmcda_gui(gvs.mcmcda_guihandles,t,plikM,doPEG,E2P,evaders,[],[]);

fprintf('[%03d] raw=%d fuse=%d K=%d\n',t,size(gvs.yobs_raw{t},1),size(gvs.yobs{t},1),...
    size(gvs.record.trackinfo.track,2));
