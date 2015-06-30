function output = cycles(varargin)
output = feval(varargin{:});

function output = init
global rsc
cycles_bytes = statistic('byte_offset', 'numCycles');
orig_bytes = statistic('byte_offset', 'realSource');
tablename = rsc.tablename;
type_filter = statistic('type_filter');

query = ['select ' cycles_bytes ' from ' tablename ', (select ' orig_bytes ... 
	 ', max(packetid) as packetid from ' tablename ' where ' type_filter ...
	 ' group by ' orig_bytes ') as pidtable where ' tablename ...
	 '.packetid = pidtable.packetid and ' type_filter ';'];

% select b25 + b26 * 256 from test, (select b31, max(packetid) as packetid from test where b2 = 102 
% group by b31) as pidtable where b2 = 102 and test.packetid = pidtable.packetid;
rsc.cycles = core('fetch_data', query);
output = -1;

function output = caption
global rsc
core('html_print', ['<b>Total Number of Cycles Detected</b>: ' num2str(sum(rsc.cycles))]);
core('print_br');;
core('html_print', ['<p><b>Mote Versus Number of Cycles Detected</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.nodesID;
output{2} = rsc.cycles;
output{3} = 'Mote Id';
output{4} = 'Cycles Detected';
output{5} = 'Mote Versus Cycles Detected';
output{6} = [min(output{1}) max(output{1}) 0 max(output{2}) + 1];
output{7} = 'cycles_detected';
plotlib('graph', output);
pic_name = output{7};