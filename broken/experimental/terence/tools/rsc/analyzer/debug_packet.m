function value = debug_packet(varargin)
value = feval(varargin{:});


function void = initialise
global debug
debug.source = 7;
void = -1;

function value = fetch_data(expname);
global rsc debug
mdbmsg = RouteDBMsg;
source_offset = num2str(mdbmsg.offset_source);
amtype_offset = num2str(mdbmsg.offset_amtype);
data_length = mdbmsg.DEFAULT_MESSAGE_SIZE - rsc.amsize;
length_offset = num2str(mdbmsg.offset_length);
amtype = num2str(mdbmsg.AM_TYPE);
numnode = num2str(rsc.numnode);
value = analyzer('fetch_data', ['select * from ' expname ' where ' ...
        'b' source_offset ' = ' num2str(debug.source) ' and ' ...
        'b' amtype_offset ' = ' amtype ' ; ']);

function value = big_loop(result)
global debug
parent = [];
times = [];
costs = [];
value = -1;
parent_cumulative = [];
decision_cumulative=[];
for i = 1:size(result, 1)
    raw_packet = result(i, :);
    time = analyzer('get_epoch', raw_packet);
    packet = analyzer('get_packet', raw_packet);
    mdbmsg = RouteDBMsg(packet);
    parent(length(parent) + 1) = mdbmsg.get_parent;
    times(length(times) + 1) = time;
    best_parent = mdbmsg.get_bestParent;
    old_parent = mdbmsg.get_oldParent;

    if (mdbmsg.get_parent == old_parent)
        cost = mdbmsg.get_oldParentCost;    
    elseif (mdbmsg.get_parent == best_parent)
        cost = mdbmsg.get_bestParentCost;    
    elseif (mdbmsg.get_parent == 255)
        cost = 65535;
    end
    costs(length(costs) + 1) = cost;
    parent_cumulative = [parent_cumulative mdbmsg.get_parent];
    decision_cumulative = [decision_cumulative mdbmsg.get_decision];
end
debug.costs = costs;
debug.times = times;
debug.parent = parent;
debug.parent_cumulative = parent_cumulative;
debug.decision_cumulative = decision_cumulative;

% x = load('parent_selection')
times = times - times(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55
% kill those invalid parent to -1
parent([find(parent == 255)]) = -1;

analyzer('html_print', ['<b>Mote ' num2str(debug.source) ' Parent Selection Over Time']);
analyzer('print_br');;
output{1} = times;
output{2} = parent;
output{3} = 'Time';
output{4} = 'Parent';
output{5} = 'Parent Selection Over Time';
output{6} = [times(1) times(length(times)) min(parent) max(parent)+1];
output{7} = ['node_' num2str(debug.source) '_parent'];
analyzer('plot_graph', output);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
analyzer('html_print', ['<b>Mote ' num2str(debug.source) ' Parent Histogram']);
analyzer('print_br');;
parent_cumulative(find(parent_cumulative==255))=-1;
output{1} = parent_cumulative;
output{2} = min(parent_cumulative):max(parent_cumulative);
output{3} = 'Parent';
output{4} = 'Frequency';
output{5} = 'Parent Histogram';
output{6} = ['parent_cumulative_n' num2str(debug.source)];
analyzer('plot_histogram', output);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

analyzer('html_print', ['<b>Mote ' num2str(debug.source) ' Decision Histogram']);
analyzer('print_br');;
output{1} = decision_cumulative;
output{2} = min(decision_cumulative):max(decision_cumulative);
output{3} = 'Decision';
output{4} = 'Frequency';
output{5} = 'Decision Histogram';
output{6} = ['decision_cumulative_n' num2str(debug.source)];
analyzer('plot_histogram', output);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
costs = costs / 256;
costs([find(costs ==  65535 / 256)]) = -1;
analyzer('html_print', ['<b>Mote ' num2str(debug.source) ' Cost Over Time']);
analyzer('print_br');;
output{1} = times;
output{2} = costs;
output{3} = 'Time';
output{4} = 'Cost';
output{5} = 'Resulting Cost Over Time';
output{6} = [times(1) times(length(times)) min(costs) max(costs)];
output{7} = ['node_' num2str(debug.source) '_cost'];
analyzer('plot_graph', output);



function void = general_info(result)
void = -1;
