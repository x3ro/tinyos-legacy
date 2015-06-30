function output = avg_retransmission(varargin)
output = feval(varargin{:});

function output = init
global rsc

orig_bytes = statistic('byte_offset', 'realSource');
dg_bytes = statistic('byte_offset', 'dataGenerated');
forward_bytes = statistic('byte_offset', 'forwardPacket');
tr_bytes = statistic('byte_offset', 'totalRetransmission');
type_filter = statistic('type_filter');
tablename = rsc.tablename;

query = ['select cast(' tr_bytes ' as float) / cast(' forward_bytes ' + ' dg_bytes ' as float) from ' tablename ...
        ', (select ' orig_bytes ', max(packetid) as packetid from ' tablename ...
        ' where ' type_filter ' group by ' orig_bytes ') as pidtable where ' tablename ...
        '.packetid = pidtable.packetid and ' type_filter ';'];

% select cast(b9 + b10 * 256 as float) / cast((b5 + b6 * 256 + b7 + b8 * 256) as float) from test, 
% (select b31, max(packetid) as packetid from test where b2 = 102 group by b31) as pidtable where test.packetid = pid
% table.packetid;

rsc.avg_retransmission = core('fetch_data', query);
output = -1;

function output = caption
global rsc
core('html_print', ['<b>Average Retransmissions of All Nodes</b>: ' num2str(sum(rsc.avg_retransmission) / length(rsc.avg_retransmission))]);
core('print_br');;
core('html_print', ['<p><b>Mote Versus Average Retransmission</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.nodesID;
output{2} = rsc.avg_retransmission;
output{3} = 'Mote Id';
output{4} = 'Average Retransmission';
output{5} = 'Mote Versus Average Retransmission';
output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
output{7} = 'average_retransmission';
plotlib('graph', output);
pic_name = output{7};


