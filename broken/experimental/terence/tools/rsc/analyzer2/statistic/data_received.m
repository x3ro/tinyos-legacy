function output = data_received(varargin)
output = feval(varargin{:});

function output = init
global rsc

orig_bytes = statistic('byte_offset', 'realSource');
tablename = rsc.tablename;
type_filter = statistic('type_filter');

query = ['select count from (select ' orig_bytes ', count(*) as count from ' tablename ...
	 ' where ' type_filter ' group by ' orig_bytes ') as blah;'];
%% select count from (select b31, count(*) as count from hm_test33 where b2 = 102 group by b31) as blah;

rsc.data_received = core('fetch_data', query);
output = -1;

function output = caption
global rsc
core('html_print', ['<b>Total Number of Data Packet Received</b>: ' num2str(sum(rsc.data_received))]);
core('print_br');;
core('html_print', ['<p><b>Mote Versus Number of Data Packet Received</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.nodesID;
output{2} = rsc.data_received;
output{3} = 'Mote Id';
output{4} = 'Number of Data Packet BaseStation Received';
output{5} = 'Mote Versus Number of Data Packet BaseStation Received';
output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
output{7} = 'data_received_result';
plotlib('graph', output);
pic_name = output{7};