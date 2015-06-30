function output = avg_hop_dist(varargin)
output = feval(varargin{:});

function output = init
global rsc

output = -1;

function output = caption
global rsc
core('html_print', ['<p><b>Mote Versus Average Hop Histogram</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.avg_hop;
output{2} = 'Average Hop Count';
output{3} = 'Number of Nodes';
output{4} = 'Average Hop Count Distribution';
output{5} = [floor(min(output{1})):ceil(max(output{1}))];
output{6} = 'avg_hop';
plotlib('plot_freq', output);
pic_name = output{6};