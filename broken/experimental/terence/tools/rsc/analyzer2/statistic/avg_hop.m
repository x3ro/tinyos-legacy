function output = avg_hop(varargin)
output = feval(varargin{:});

function output = init
global rsc

tablename = rsc.tablename;
type_filter = statistic('type_filter');
orig_bytes = statistic('byte_offset', 'realSource');
hop_bytes = statistic('byte_offset', 'hop');

query = ['select avghop from (select ' orig_bytes ', avg(' hop_bytes ') as avghop from ' tablename ...
        ' where ' type_filter ' group by ' orig_bytes ') as blah;'];

% select avghop from (select b31, avg(b15) as avghop from test where b2 = 102 group by b31) as blah;
rsc.avg_hop = core('fetch_data', query);
output = -1;

function output = caption
global rsc
core('html_print', ['<p><b>Mote Versus Average Hop</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.nodesID;
output{2} = rsc.avg_hop;
output{3} = 'Mote Id';
output{4} = 'Average Hop Count';
output{5} = 'Mote Versus Average Hop Count';
output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
output{7} = 'avg_hop';
plotlib('graph', output);
pic_name = output{7};