function realtime_topology
global rsc
% this is going to be called every timer fired
orig_bytes = statistic('byte_offset', 'realSource');
parent_bytes = statistic('byte_offset', 'parent');
tablename = rsc.tablename;
type_filter = statistic('type_filter');
time_bytes = statistic('time_bytes');
granularity = rsc.timer_rate;

% query current time
% FIX HERE, query sql for current time
query = [];
current_time = core('fetch_query', query);


query = ['select distinct ' orig_bytes ', ' parent_bytes ' from ' tablename ...
        ' where ' type_filter ' and ' time_bytes ' < ' num2str(current_time) ...
        ' and ' time_bytes ' > ' num2str(current_time - granularity) ';'];

[id, parent] = core('fetch_query', query);

update_topology(id, parent);
