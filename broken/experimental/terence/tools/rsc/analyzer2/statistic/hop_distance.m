function output = hop_distance(varargin)
output = feval(varargin{:});

function output = init
global rsc
output = -1;

function output = caption
global rsc
core('html_print', ['<p><b>Average Hop Count Versus Distance</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.nodesID;
output{2} = rsc.avg_hop;
output{3} = 'Distance';
output{4} = 'Average Hop Count';
output{5} = 'Distance Versus Average Hop Count';
output{6} = [0 max(output{2})];
output{7} = 'average_hop_vs_distance';
plotlib('distance', output);
pic_name = output{7};