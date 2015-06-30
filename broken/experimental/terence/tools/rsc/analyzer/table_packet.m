function value = table_packet(varargin)
value = feval(varargin{:});


function void = initialise
global table
table = [];
table.source = 12;
void = -1;

function value = fetch_data(expname);
global rsc table
tp = TablePacket;
source_offset = num2str(tp.offset_source);
amtype_offset = num2str(tp.offset_amtype);
data_length = tp.DEFAULT_MESSAGE_SIZE - rsc.amsize;
length_offset = num2str(tp.offset_length);
amtype = num2str(tp.AM_TYPE);
numnode = num2str(rsc.numnode);
value = analyzer('fetch_data', ['select * from ' expname ' where ' ...
        'b' source_offset ' = ' num2str(table.source) ' and ' ...
        'b' amtype_offset ' = ' amtype ' ; ']);

function [value, new] = get_index(num)
global table
node_field = ['node' num2str(num)];
try 
   table.node_index;
catch
   node_index = [];
   value = 1;
   table.node_index = setfield(node_index, node_field, value);
   new = 1;
   return;
end

%%% if it is not there
if isfield(table.node_index, node_field) == 0
    value = size(fieldnames(table.node_index), 1) + 1;
    new = 1;
    table.node_index = setfield(table.node_index, node_field, value);
else
    new = 0;
    %% get the value
    value = getfield(table.node_index, node_field);
end



function add_neighbor(num, table_packet, time)
global table
id = javaMethod(['get_id' num2str(num)], table_packet);
receive_estimate = javaMethod(['get_receiveEst' num2str(num)], table_packet);
send_estimate = javaMethod(['get_sendEst' num2str(num)], table_packet);
cost = javaMethod(['get_cost' num2str(num)], table_packet);

[index, new] = get_index(id);
receive_estimate = receive_estimate / 255 * 100;
send_estimate = send_estimate / 255 * 100;
%% this is to make it invalid
if (cost == 65535)
    cost = -1;
else
    cost = cost / 4;
end


if (new == 1)
    table.receive_estimates{index} = [receive_estimate];
    table.send_estimates{index} = [send_estimate];
    table.costs{index} = [cost];
    table.ids{index} = id;
    table.time{index} = time;
else
    receive_estimates = table.receive_estimates{index};
    table.receive_estimates{index} = [receive_estimates(1:length(receive_estimates)), receive_estimate];
    send_estimates = table.send_estimates{index};
    table.send_estimates{index} = [send_estimates(1:length(send_estimates)), send_estimate];
    costs = table.costs{index};
    table.costs{index} = [costs(1:length(costs)), cost];
    table.time{index} = [table.time{index} time];
end


function value = big_loop(result)
global table
value = -1;
for i = 1:size(result, 1)
    raw_packet = result(i, :);
    
    time = analyzer('get_epoch', raw_packet);
    
    packet = analyzer('get_packet', raw_packet);
    tp = TablePacket(packet);
    add_neighbor(1, tp, time);    
    add_neighbor(2, tp, time);    
    add_neighbor(3, tp, time);    
    add_neighbor(4, tp, time);    
    add_neighbor(5, tp, time);    
end
value = -1;




for i = 1:length(table.ids)
    time = table.time{i};
    time = time - time(1);

    receive_estimates = table.receive_estimates{i};
    analyzer('html_print', ['<b>Mote ' num2str(table.source) ' Receive Estimate to Mote Versus Time To ' num2str(table.ids{i})]);
    analyzer('print_br');;
    
    try
        output{1} = time;
        output{2} = receive_estimates;
        output{3} = 'Time';
        output{4} = 'Receive Estimation';
        output{5} = 'Receive Estimation Over Time';
        output{6} = [time(1) time(length(time)) 0 100];
        output{7} = ['node_' num2str(table.source) '_receive_estimate_to_' num2str(table.ids{i})];
        analyzer('plot_graph', output);
    catch
    end
    
    try
        send_estimates = table.send_estimates{i};
        analyzer('html_print', ['<b>Mote ' num2str(table.source) ' Send Estimate to Mote Versus Time To ' num2str(table.ids{i})]);
        analyzer('print_br');;
        output{1} = time;
        output{2} = send_estimates;
        output{3} = 'Time';
        output{4} = 'Send Estimation';
        output{5} = 'Send Estimation Over Time';
        output{6} = [time(1) time(length(time)) 0 100];
        output{7} = ['node_' num2str(table.source) '_send_estimate_to_' num2str(table.ids{i})];
        analyzer('plot_graph', output);
    catch
    end
    try
        costs = table.costs{i};
        analyzer('html_print', ['<b>Mote ' num2str(table.source) ' Cost Estimate to Mote Versus Time To ' num2str(table.ids{i})]);
        analyzer('print_br');;
        output{1} = time;
        output{2} = costs;
        output{3} = 'Time';
        output{4} = 'Cost Estimation';
        output{5} = 'Cost Estimation Over Time';
        output{6} = [time(1) time(length(time)) 0 max(costs)];
        output{7} = ['node_' num2str(table.source) '_cost_estimate_to_' num2str(table.ids{i})];
        analyzer('plot_graph', output);
    catch
    end
end




function void = general_info(result)
void = -1;