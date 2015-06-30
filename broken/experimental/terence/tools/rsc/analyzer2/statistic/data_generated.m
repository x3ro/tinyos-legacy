function output = data_generated(varargin)
output = feval(varargin{:});

function output = init
global rsc
dg_bytes = statistic('byte_offset', 'dataGenerated');
orig_bytes = statistic('byte_offset', 'realSource');
amtype_bytes = statistic('byte_offset', 'amtype');
tablename = rsc.tablename;
type_filter = statistic('type_filter');

query = ['select ' dg_bytes ' from ' tablename ', (select ' orig_bytes ... 
	 ', max(packetid) as packetid from ' tablename ' where ' type_filter ...
	 ' group by ' orig_bytes ') as pidtable where ' tablename ...
	 '.packetid = pidtable.packetid and ' type_filter ';'];

%% select b5 + b6 * 256 from test, (select b31, max(packetid) as packetid
%% from test where b2 = 102 group by b31) as pidtable where test.packetid = pidtable.packetid
%% and b2 = 102;


rsc.data_generated = core('fetch_data', query);
output = -1;


function output = caption
global rsc
core('html_print', ['<b>Total Number of Data Packet Generated</b>: ' num2str(sum(rsc.data_generated))]);
core('print_br');;
core('html_print', ['<p><b>Mote Versus Number of Data Packet Generated</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.nodesID;
output{2} = rsc.data_generated;
output{3} = 'Mote Id';
output{4} = 'Number of Data Packet Generated';
output{5} = 'Mote Versus Number of Data Packet Generated';
output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
output{7} = 'data_packet_generated';
plotlib('graph', output);
pic_name = output{7};



