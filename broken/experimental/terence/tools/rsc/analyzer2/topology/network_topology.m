function network_topology
global rsc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% typical experiment setting
[nodesID, coor, basestationID] = hearst_setting;
tablename = 'hm_test36';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

core('init', nodesID, coor, tablename, basestationID);
global rsc
% make it to invalid at first by setting to itself
rsc.parent = nodesID;
%% find the min time
type_filter = statistic('type_filter');
query = ['select min(extract(epoch from time)) from ' tablename ' where ' type_filter ';'];
rsc.current_time = core('fetch_data', query);

rsc.granularity = 60;
rsc.timer_rate = 1;

rsc.timer = timer('TimerFcn', 'replay_topology', 'Period', rsc.timer_rate, 'ExecutionMode', 'fixedRate');

start(rsc.timer);


