function output = invalid_parent(varargin)
output = feval(varargin{:});

function output = init
global rsc

tablename = rsc.tablename;
type_filter = statistic('type_filter');
invalid_parent_bytes = statistic('byte_offset', 'noParentCount');
orig_bytes = statistic('byte_offset', 'realSource');

query = ['select ' invalid_parent_bytes ' from ' tablename ', (select ' orig_bytes ... 
	 ', max(packetid) as packetid from ' tablename ' where ' type_filter ...
	 ' group by ' orig_bytes ') as pidtable where ' tablename ...
	 '.packetid = pidtable.packetid and ' type_filter ';'];

% select b22 + b23 * 256 from test, (select b31, max(packetid) as packetid
% from test where b2 = 102 group by b31) as pidtable where test.packetid = pidtable.packetid
% and b2 = 102;
rsc.invalid_parent = core('fetch_data', query);
output = -1;

function output = caption
global rsc
core('html_print', ['<b>Total Number of Data Packet Sent With Invalid Parent</b>: ' num2str(sum(rsc.invalid_parent))]);
core('print_br');;
core('html_print', ['<p><b>Mote Versus Data Packet Sent With Invalid Parent</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.nodesID;
output{2} = rsc.invalid_parent;
output{3} = 'Mote Id';
output{4} = 'Number of Data Packets Sent With Invalid Parent';
output{5} = 'Mote Versus Number of Data Packets Sent With Invalid Parent';
output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
output{7} = 'invalid_parent';
plotlib('graph', output);
pic_name = output{7};