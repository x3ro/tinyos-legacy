function output = stability(varargin)
output = feval(varargin{:});

function output = init
global rsc
output = -1;
tablename = rsc.tablename;
type_filter = statistic('type_filter');
orig_bytes = statistic('byte_offset', 'realSource');
parent_changes_bytes = statistic('byte_offset', 'parentChange');

%% first get the time where we get the first and last packet
%% so we know when to stop
epoch_byte = statistic('epoch_offset');
query = ['select min(' epoch_byte '), max(' epoch_byte ') from ' tablename ' where ' type_filter ';'];
result = core('fetch_data', query);
first_packet_time = result(1, 1);
last_packet_time = result(1, 2);

%% Set the granularity 
granularity = 60;
rsc.parent_change_granularity = granularity;
current_time = first_packet_time;
total_parent_change = [];
time = [];
i = 0;
enum_changes = zeros(1, length(rsc.nodesID));
while (current_time < last_packet_time)
  query = ['select ' orig_bytes ', max(' parent_changes_bytes ') as changes from ' tablename ...
	   ' where ' epoch_byte ' > ' num2str(current_time) ' and ' epoch_byte ...
	   ' <= ' num2str(current_time + granularity) ' and ' type_filter ...
	   ' group by ' orig_bytes ';'];

  time = [time current_time - first_packet_time];
  current_time = current_time + granularity;
  result = core('fetch_data', query);
  known_id = result(:, 1);
  known_changes = result(:, 2);
  [blah, known_index] = intersect(rsc.nodesID, known_id);
  total_old_changes = sum(enum_changes);
  enum_changes(known_index) = known_changes;
  result = sum(enum_changes) - total_old_changes;
  total_parent_change = [total_parent_change result]; 
end  

% select sum(blah.changes) from (select b31, max(b24 + b25 * 256) 
% as changes from hm_test33 where extract(epoch from time) > 1059006537.046
% and extract(epoch from time) <= 1059006537.046 + 6000 and 
% b2 = 102 group by b31) as blah;

rsc.parent_change = total_parent_change;
rsc.parent_change_time = time;

function output = caption
global rsc
core('html_print', ['<p><b>Mote Versus Number of Changes in ' num2str(rsc.parent_change_granularity) ' seconds</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.parent_change_time;
output{2} = rsc.parent_change;
output{3} = 'Time';
output{4} = ['Number of Parent Changes in ' num2str(rsc.parent_change_granularity) ' seconds'];
output{5} = ['Time Versus ' output{4}];
output{6} = [min(output{1}) max(output{1}) + 1 0 max(output{2}) + 1];
output{7} = 'stability';
plotlib('graph', output);
pic_name = output{7};



