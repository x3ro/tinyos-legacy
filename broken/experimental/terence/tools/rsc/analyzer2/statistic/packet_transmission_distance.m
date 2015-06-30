function output = packet_transmission_distance(varargin)
output = feval(varargin{:});


function output = init
global rsc
tablename = rsc.tablename;
transmission_bytes = statistic('byte_offset', 'numTrans');
retrans_bytes = statistic('byte_offset', 'numRetrans');
orig_bytes = statistic('byte_offset', 'realSource');
type_filter = statistic('type_filter');
query = ['select avg(' transmission_bytes ' + ' retrans_bytes '), ' orig_bytes ' from ' tablename ...
        ' where ' type_filter ' group by ' orig_bytes ';'];
rsc.packet_transmission_source = core('fetch_data', query);
output = -1;

function output = caption
global rsc
core('html_print', ['<p><b>Number of Transmission For Each Packet Versus Distance</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.packet_transmission_source(:, 2);
output{2} = rsc.packet_transmission_source(:, 1);
output{3} = 'Distance';
output{4} = 'Number of Transmission For Each Packet';
output{5} = 'Number of Transmission For Each Packet Versus Distance';
output{6} = [0 max(output{2})];
output{7} = 'packet_transmission_vs_distance';
plotlib('distance', output);
pic_name = output{7};
