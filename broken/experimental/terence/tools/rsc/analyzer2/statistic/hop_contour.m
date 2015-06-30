function output = hop_contour(varargin)
output = feval(varargin{:});

function output = init
global rsc
hop_bytes = statistic('byte_offset', 'hop');
orig_bytes = statistic('byte_offset', 'realSource');
tablename = rsc.tablename;
type_filter = statistic('type_filter');

query = ['select ' hop_bytes ' from ' tablename ', (select ' orig_bytes ... 
	 ', max(packetid) as packetid from ' tablename ' where ' type_filter ...
	 ' group by ' orig_bytes ') as pidtable where ' tablename ...
	 '.packetid = pidtable.packetid and ' type_filter ';'];

% select b15 from test, (select b31, max(packetid) as packetid from test where b2 = 102 
% group by b31) as pidtable where b2 = 102 and test.packetid = pidtable.packetid;
rsc.final_hop = core('fetch_data', query);
output = -1;

function output = caption
global rsc
core('html_print', ['<p><b>Hop Contour</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.coor ./ 8;
output{2} =  rsc.final_hop;
output{3} = ['Contour map of hop'];
output{4} = ['hop_contour'];
plotlib('hop_contour', output);
pic_name = output{3};