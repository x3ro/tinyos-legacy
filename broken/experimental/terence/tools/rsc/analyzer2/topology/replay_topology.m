function replay_topology
global rsc
% this is going to be called every timer fired
orig_bytes = statistic('byte_offset', 'realSource');
parent_bytes = statistic('byte_offset', 'parent');
tablename = rsc.tablename;
type_filter = statistic('type_filter');
time_bytes = statistic('epoch_offset');
granularity = rsc.granularity;
current_time = rsc.current_time;
rsc.current_time = rsc.current_time + granularity;

query = ['select distinct ' orig_bytes ', ' parent_bytes ' from ' tablename ...
        ' where ' type_filter ' and ' time_bytes ' > ' num2str(current_time) ...
        ' and ' time_bytes ' < ' num2str(current_time + granularity) ';'];
result = core('fetch_data', query);
if (isempty(result))
    return;
end
id = result(:, 1);
parent = result(:, 2);
update_topology(id', parent');

