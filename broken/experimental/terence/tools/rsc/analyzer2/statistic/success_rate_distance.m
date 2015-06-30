function output = success_rate_distance(varargin)
output = feval(varargin{:});

function output = init
global rsc
output = -1;

function output = caption
global rsc
core('html_print', ['<p><b>Distance Versus Sucess Rate</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.nodesID;
output{2} = rsc.success_rate * 100;
output{3} = 'Distance (Feet)';
output{4} = 'Success Rate (%)';
output{5} = 'Distance Versus End to End Success Rate';
output{6} = [0 max(output{2})];
output{7} = 'success_rate_vs_distance';
plotlib('distance', output);
pic_name = output{7};


