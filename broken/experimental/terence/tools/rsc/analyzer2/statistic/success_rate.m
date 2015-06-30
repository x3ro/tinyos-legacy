function output = success_rate(varargin)
output = feval(varargin{:});

function output = init
global rsc
rsc.success_rate = rsc.data_received ./ rsc.data_generated;
output = -1;

function output = caption
global rsc
core('html_print', ['<b>Total Success Rate</b>: ' num2str(sum(rsc.data_received) / sum(rsc.data_generated))]);
core('print_br');
core('html_print', ['<p><b>Mote Versus Sucess Rate</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
output{1} = rsc.nodesID;
output{2} = rsc.success_rate;
output{3} = 'Mote Id';
output{4} = 'Success Rate';
output{5} = 'Mote Versus Success Rate';
output{6} = [min(output{1}) max(output{1}) 0 1];
output{7} = 'success_rate';
plotlib('graph', output);
pic_name = output{7};

