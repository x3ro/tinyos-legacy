function output = estimate(varargin)
output = feval(varargin{:});


function output = init
global rsc
rsc.nodeIdx = [];
rsc.receive_est = [];
rsc.send_est = [];
rsc.cost = [];
tablename = rsc.tablename;
type_filter = table_packet('type_filter');
query = ['select min(extract(epoch from time)) from ' tablename ' where ' type_filter ';'];
rsc.first_packet_time = core('fetch_data', query);


for i = 1:4
    id_byte = table_packet('byte_offset', ['id' num2str(i)]);    
    receive_byte = table_packet('byte_offset', ['receiveEst' num2str(i)]);    
    send_byte = table_packet('byte_offset', ['sendEst' num2str(i)]);    
    cost_byte = table_packet('byte_offset', ['cost' num2str(i)]);    
    query = ['select extract(epoch from time), ' id_byte ', ' receive_byte ', ' send_byte ', ' cost_byte ...
            ' from ' tablename ' where ' type_filter ';'];
    result = core('fetch_data', query);
    parse_result(result);
end
output = -1;

for i = 1:length(rsc.nodeIdx)
    [blah, order] = sort(rsc.time{i});
    rsc.time{i} = rsc.time{i}(order);
    rsc.receive_est{i} = rsc.receive_est{i}(order);
    rsc.send_est{i} = rsc.send_est{i}(order);
    rsc.cost{i} = rsc.cost{i}(order);
end

function parse_result(result)
global rsc
for i = 1:length(result)
    time = result(i, 1) - rsc.first_packet_time;
    id = result(i, 2);
    receive_est = result(i, 3);
    send_est = result(i, 4);
    cost = result(i, 5);
    if (id == 255)
        continue;
    end
    [index, new] = get_node_index(id);
    if new == 1, 
        rsc.receive_est{index} = receive_est; 
        rsc.send_est{index} = send_est; 
        rsc.cost{index} = cost; 
        rsc.time{index} = time;
    else
        rsc.receive_est{index} = [rsc.receive_est{index} receive_est];
        rsc.send_est{index} = [rsc.send_est{index} send_est];
        rsc.cost{index} = [rsc.cost{index} cost]; 
        rsc.time{index} = [rsc.time{index} time];
    end
end

function [index, new] = get_node_index(nodeID)
global rsc
index = find(rsc.nodeIdx == nodeID);
new = 0;
if length(index) == 0
    index = length(rsc.nodeIdx) + 1;
    rsc.nodeIdx(index) = nodeID;
    new = 1;
end

function output = caption_send_est(i)
global rsc
core('html_print', ['<p><b>Send Estimate for node ' num2str(rsc.nodeIdx(i))]); core('print_br');;
output = -1;

function pic_name = graph_send_est(i)
global rsc
time = rsc.time{i};
output{1} = time;
output{2} = rsc.send_est{i} * 100 / 255;
output{3} = 'Time';
output{4} = 'Send Estimation';
output{5} = 'Send Estimation Over Time';
output{6} = [time(1) time(length(time)) 0 100];
output{7} = ['node_' num2str(rsc.nodeIdx(i)) '_send_estimate'];
plotlib('graph', output);
pic_name = output{7};

function output = caption_receive_est(i)
global rsc
core('html_print', ['<p><b>Receive Esimate for node ' num2str(rsc.nodeIdx(i))]); core('print_br');;
output = -1;

function pic_name = graph_receive_est(i)
global rsc
time = rsc.time{i};
output{1} = time;
output{2} = rsc.receive_est{i} * 100 / 255;
output{3} = 'Time';
output{4} = 'Receive Estimation';
output{5} = 'Receive Estimation Over Time';
output{6} = [time(1) time(length(time)) 0 100];
output{7} = ['node_' num2str(rsc.nodeIdx(i)) '_receive_estimate'];
plotlib('graph', output);
pic_name = output{7};

function output = caption_cost(i)
global rsc
core('html_print', ['<p><b>Cost for node ' num2str(rsc.nodeIdx(i))]); core('print_br');;
output = -1;

function pic_name = graph_cost(i)
global rsc
time = rsc.time{i};
output{1} = time;
output{2} = rsc.cost{i} / 4;
output{3} = 'Time';
output{4} = 'Cost';
output{5} = 'Cost Over Time';
output{6} = [time(1) time(length(time)) 0 max(output{2})];
output{7} = ['node_' num2str(rsc.nodeIdx(i)) '_cost'];
plotlib('graph', output);
pic_name = output{7};

