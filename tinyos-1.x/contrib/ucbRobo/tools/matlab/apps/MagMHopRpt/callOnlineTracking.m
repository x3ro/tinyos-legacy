function callOnlineTracking
% callOnlineTracking (no arguments)
% Function periodically fired by a timer that calls the hmttsn_testbed
% online_tracking() function.  Do not call this function directly.
%
% (Credits: Based off of run_online_tracking in hmttsn_testbed)
%
% See 'startOnlineTracking' and 'stopOnlineTracking' for details

global DATA MTT;
global gvs; % from hmttsn_testbed

if ~MTT.running
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
newDat = DATA.MAGMHOPRPT.reportMat(:,MTT.lastObsInd+1:end);
MTT.lastObsInd = size(DATA.MAGMHOPRPT.reportMat,2);

% Data Processing: Node ID is 1st field
% Note that hmttsn_testbed uses only node ID and report time
for i = 1:size(newDat,2)
    x = floor(newDat(1,i)/10);
    y = mod(newDat(1,i),10);
    yt = [yt; x+1 y+1];
end

if isfield(gvs,'yobs')
    len = length(gvs.yobs);
else 
    len = 0;
end
gvs.yobs{len+1} = yt;
gvs.record.cputime = zeros(1,len+1);
online_tracking(len+1,len+2,1,1,1);