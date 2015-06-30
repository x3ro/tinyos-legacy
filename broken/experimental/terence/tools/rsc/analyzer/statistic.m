function value = statistic(varargin)
value = feval(varargin{:});


function value = initialise
value = -1;
function value = fetch_data(expname);
global rsc
sp = StatPacket;
source_offset = num2str(sp.offset_source);
amtype_offset = num2str(sp.offset_amtype);
data_length = sp.DEFAULT_MESSAGE_SIZE - rsc.amsize;
length_offset = num2str(sp.offset_length);
amtype = num2str(sp.AM_TYPE);
numnode = num2str(rsc.numnode);
value = analyzer('fetch_data', ['select * from ' expname ' where ' ...
        'b' source_offset ' = 1 and ' ...
        'b' amtype_offset ' = ' amtype ' ; ']);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function initialise_stability(result)
global stability
first_raw_packet = result(1, :);
stability.last_time = analyzer('get_epoch', first_raw_packet);
stability.granularity = 60;
stability.time_index = 1;
stability.old_parent = [];
stability.freq = [0];
stability.visited = [];

% source here is id + 1; to prevent matlab weird indexing
function report_stability_parent(source, parent, time)
global stability

% if we never see this mote before then....
if isempty(stability.visited) | isempty(find(stability.visited == source))
    stability.old_parent(source) = parent;
    stability.visited = [stability.visited source];
    stability.freq(stability.time_index) = stability.freq(stability.time_index) + 1;
    % if parent changed then....
elseif (stability.old_parent(source) ~= parent) 
    stability.old_parent(source) = parent;
    stability.freq(stability.time_index) = stability.freq(stability.time_index) + 1;
end

if (stability.last_time + stability.granularity < time) 
    stability.last_time = stability.last_time + stability.granularity;
    stability.time_index = stability.time_index + 1;
    stability.freq = [stability.freq 0];
end

function plot_stability
global stability
analyzer('html_print', ['<p><b>Stability Versus Time</b>']); analyzer('print_br');;
output{1} = (1:length(stability.freq)) * stability.granularity;
output{2} = stability.freq;
output{3} = 'Time';
output{4} = 'Stability';
output{5} = 'Timer Versus Stabililty';
output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
output{7} = 'stability';
analyzer('plot_graph', output);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% average blah over time
function [final_result, final_time] = generic_time_fetch(data_offset, result, moteid)
setdbprefs('DataReturnFormat', 'cellarray');
global rsc
first_raw_packet = result(1 ,:);
current_time = analyzer('get_epoch', first_raw_packet);
end_time = analyzer('get_epoch', result(size(result, 1), :));
granularity = 60;

sp = StatPacket;
source_offset = num2str(sp.offset_source);
amtype_offset = num2str(sp.offset_amtype);
data_length = sp.DEFAULT_MESSAGE_SIZE - rsc.amsize;
length_offset = num2str(sp.offset_length);
amtype = num2str(sp.AM_TYPE);
real_source_offset = num2str(sp.offset_realSource);
final_time = [];
final_result = [];

setdbprefs('DataReturnFormat', 'numeric');

while current_time < end_time
  query = ['select b' real_source_offset ', avg(b' data_offset ') from ' ...
	   rsc.expname ' where extract(epoch from time) > ' ...
	   num2str(current_time) ' and extract(epoch from' ...
	   ' time) <= ' num2str(current_time + granularity) ' and b' amtype_offset ' = ' amtype ' group by b' ...
	   real_source_offset ';'];
  value = analyzer('fetch_data', query);
  final_result_row(1:length(moteid)) = -1;
  final_result_row(value(:, 1)) = value(:, 2);
  final_result = [final_result; final_result_row];
  final_time = [final_time current_time];  
  current_time = current_time + granularity;
end
setdbprefs('DataReturnFormat', 'cellarray');


function [return_result, return_time] = generic_time_filter(moteid, final_result, final_time)

for i=1:length(moteid)
  this_time = final_time;
  this_data = final_result(:, i);
  this_data = this_data';
  valid_index = find(this_data ~= -1);
  this_time = this_time(valid_index);
  this_data = this_data(valid_index);
  return_result{i} = this_data;
  return_time{i} = this_time;
end


function [moteid, result] = generic_max_fetch(data_offset, size_data)
global rsc
sp = StatPacket;
source_offset = num2str(sp.offset_source);
amtype_offset = num2str(sp.offset_amtype);
data_length = sp.DEFAULT_MESSAGE_SIZE - rsc.amsize;
length_offset = num2str(sp.offset_length);
amtype = num2str(sp.AM_TYPE);
real_source_offset = num2str(sp.offset_realSource);
if (size_data == 2)
    data_offset = ['b' num2str(data_offset) ' + b' num2str(data_offset + 1) ' * 256'];
elseif (size_data == 1)
    data_offset = ['b' num2str(data_offset)];
end
setdbprefs('DataReturnFormat', 'numeric');
query = ['select b' real_source_offset ', max(' data_offset ') from ' rsc.expname ' where b' amtype_offset ' = ' amtype ' group by b' real_source_offset ';'];
value = analyzer('fetch_data', query);
setdbprefs('DataReturnFormat', 'cellarray');
result = value(:, 2)';
moteid = value(:, 1)';

    
function [moteid, result] = packet_received
global rsc
sp = StatPacket;
source_offset = num2str(sp.offset_source);
amtype_offset = num2str(sp.offset_amtype);
data_length = sp.DEFAULT_MESSAGE_SIZE - rsc.amsize;
length_offset = num2str(sp.offset_length);
amtype = num2str(sp.AM_TYPE);
real_source_offset = num2str(sp.offset_realSource);
setdbprefs('DataReturnFormat', 'numeric');
query = ['select b' real_source_offset ', count(*) from ' rsc.expname ' where b' amtype_offset ' = ' amtype ' group by b' real_source_offset ';'];
value = analyzer('fetch_data', query);
setdbprefs('DataReturnFormat', 'cellarray');
result = value(:, 2)';
moteid = value(:, 1)';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% how long does it takes
function void = general_info(result)
%%%% PRESET %%%%
protocol = 'Minium Transmission';
radio = 'TOS Radio Stack Dated January 2003';
topology = 'random';
power = 65;
total_mote = 6;
range = 40;
location = 'Intel Lab';
data_clock_rate = 0.5;
route_clock_rate = 1;
void = -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

initialise_stability(result);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
analyzer('html_print', ['<h3>General Info</h3>']);
% simulation duration
first_raw_packet = result(1, :);
last_raw_packet = result(size(result, 1), :);
duration = analyzer('get_epoch', last_raw_packet) - analyzer('get_epoch', first_raw_packet);
analyzer('html_print', ['<b>Duration</b>: ' num2str(duration) ' seconds']); analyzer('print_br');;
% protocol
analyzer('html_print', ['<b>Protocol</b>: ' protocol]); analyzer('print_br');;
% radio
analyzer('html_print', ['<b>Radio</b>: ' radio]); analyzer('print_br');;
% topology
analyzer('html_print', ['<b>Topology</b>: ' topology]); analyzer('print_br');;
% power
analyzer('html_print', ['<b>Power</b>: ' num2str(power)]); analyzer('print_br');;
% location
analyzer('html_print', ['<b>Location</b>: ' location]); analyzer('print_br');;
% total mote
analyzer('html_print', ['<b>Total Number of Mote</b>: ' num2str(total_mote)]); analyzer('print_br');;
% range
%% WARNING
% analyzer('html_print', ['<b>Range</b>: ' num2str(range) ' feets']); analyzer('print_br');;
% date clock rate
analyzer('html_print', ['<b>Data Clock Rate</b>: ' num2str(data_clock_rate) ' secs per msg']); analyzer('print_br');;
% route clock rate
analyzer('html_print', ['<b>Route Clock Rate</b>: ' num2str(route_clock_rate) ' secs per msg']); analyzer('print_br');;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function value = big_loop(result)
value = -1;
analyzer('html_print', ['<h3>Network Statistics</h3>']);
total_packets = 0;
data_received_result = [];
for i = 1:size(result, 1)
    raw_packet = result(i, :);
    packet = analyzer('get_packet', raw_packet);
    sp = StatPacket(packet);
    source = sp.get_realSource;
    if source == 0
        continue;
    end
    index = source + 1;
    moteid(index) = source;
    data_generated_result(index) = sp.get_dataGenerated;
    if size(data_received_result, 2) < index
        data_received_result(index) = 0;    
        hop_cumulative{index} = [];    
    end
    data_received_result(index) = data_received_result(index) + 1;
    total_retransmission_result(index) = sp.get_totalRetransmission;
    packet_forward_result(index) = sp.get_forwardPacket;
    hop_count_result(index) = sp.get_hop;
    
    hop_cumulative{index} = [hop_cumulative{index} sp.get_hop];
    parent_result(index) = sp.get_parent;
    report_stability_parent(index, parent_result(index), analyzer('get_epoch', raw_packet));
    
    actual_transmission_result(index) = sp.get_numTrans;
    estimated_transmission_result(index) = sp.get_cost;
    no_parent_count(index) = sp.get_noParentCount;
    num_cycle(index) = sp.get_numCycles;
end
source_offset = num2str(sp.offset_source);
moteid = 0:max(moteid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load('C:\Documents and Settings\Administrator\Desktop\hm_test14.mat')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





analyzer('html_print', ['<b>Total Number of Data Packet Generated</b>: ' num2str(sum(data_generated_result))]);
analyzer('print_br');;

analyzer('html_print', ['<p><b>Mote Versus Number of Data Packet Generated</b>']); analyzer('print_br');;

try
    output{1} = moteid;
    output{2} = data_generated_result;
    output{3} = 'Mote Id';
    output{4} = 'Number of Data Packet Generated';
    output{5} = 'Mote Versus Number of Data Packet Generated';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'data_packet_generated';
    analyzer('plot_graph', output);
catch
end

analyzer('html_print', ['<p><b>Distance Versus Number of Data Packet Generated</b>']); analyzer('print_br');;
try 
    output{1} = moteid;
    output{2} = data_generated_result;
    output{3} = 'Distance';
    output{4} = 'Number of Data Packet Generated';
    output{5} = 'Distance Versus Number of Data Packet Generated';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];    
    output{7} = 'data_packet_generated_vs_distance';
    analyzer('plot_distance_scatter', output);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

analyzer('html_print', ['<b>Total Number of Data Packet BaseStation Received</b>: ' num2str(sum(data_received_result))]);
analyzer('print_br');;

analyzer('html_print', ['<p><b>Mote Versus Number of Data Packet BaseStation Received</b>']); analyzer('print_br');;
try
    output{1} = moteid;
    output{2} = data_received_result;
    output{3} = 'Mote Id';
    output{4} = 'Number of Data Packet BaseStation Received';
    output{5} = 'Mote Versus Number of Data Packet BaseStation Received';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'data_received_result';
    analyzer('plot_graph', output);
catch
end

analyzer('html_print', ['<p><b>Distance Versus Number of Data Packet BaseStation Received</b>']); analyzer('print_br');;
try
    output{1} = moteid;
    output{2} = data_received_result;
    output{3} = 'Distance';
    output{4} = 'Number of Data Packet BaseStation Received';
    output{5} = 'Distance Versus Number of Data Packet BaseStation Received';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'data_received_result_vs_distance';
    analyzer('plot_distance_scatter', output);
catch
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

analyzer('html_print', ['<b>Total Success Rate</b>: ' num2str(sum(data_received_result) / sum(data_generated_result))]);
analyzer('print_br');;

analyzer('html_print', ['<p><b>Mote Versus Sucess Rate</b>']); analyzer('print_br');;
success_rate = data_received_result ./ data_generated_result;
try
    output{1} = moteid;
    output{2} = success_rate;
    output{3} = 'Mote Id';
    output{4} = 'Success Rate';
    output{5} = 'Mote Versus Success Rate';
    output{6} = [min(output{1}) max(output{1}) 0 1];
    output{7} = 'success_rate';
    analyzer('plot_graph', output);
catch
end

analyzer('html_print', ['<p><b>Distance Versus Sucess Rate</b>']); analyzer('print_br');;
try
    output{1} = moteid;
    output{2} = success_rate;
    output{3} = 'Distance';
    output{4} = 'Success Rate';
    output{5} = 'Distance Versus Success Rate';
    output{6} = [min(output{1}) max(output{1}) 0 1];
    output{7} = 'success_rate_vs_distance';
    analyzer('plot_distance_scatter', output);
catch
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

analyzer('html_print', ['<b>Total Number of Retransmission</b>: ' num2str(sum(total_retransmission_result))]);
analyzer('print_br');;
analyzer('html_print', ['<p><b>Mote Versus Total Number of Retransmission</b>']); analyzer('print_br');;

try
    output{1} = moteid;
    output{2} = total_retransmission_result;
    output{3} = 'Mote Id';
    output{4} = 'Total Number of Retransmission';
    output{5} = 'Mote Versus Total Number of Retransmission';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'total_retransmission';
    analyzer('plot_graph', output);
catch
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
analyzer('html_print', ['<b>Total Number of Forwarding Packet</b>: ' num2str(sum(packet_forward_result)) '<br>']);
analyzer('print_br');;
analyzer('html_print', ['<p><b>Mote Versus Number of Forwarding Packets</b>']); analyzer('print_br');;
try
    output{1} = moteid;
    output{2} = packet_forward_result;
    output{3} = 'Mote Id';
    output{4} = 'Number of Forwarding Packets';
    output{5} = 'Mote Versus Number of Forwarding Packets';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'forward_packets';
    analyzer('plot_graph', output);
catch
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

analyzer('html_print', ['<b>Total Number of Transmissions</b>: ' num2str(sum(packet_forward_result) + sum(total_retransmission_result) + sum(data_generated_result)) '<br>']);
analyzer('print_br');;
analyzer('html_print', ['<p><b>Mote Versus Number of Transmission</b>']); analyzer('print_br');;
try
    output{1} = moteid;
    output{2} = packet_forward_result + total_retransmission_result + data_generated_result;
    output{3} = 'Mote Id';
    output{4} = 'Number of Transmission';
    output{5} = 'Mote Versus Number of Transmission';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'total_transmission';
    analyzer('plot_graph', output);
catch
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
total_wo_retrans = packet_forward_result + data_generated_result;
retran_ave = total_retransmission_result ./ total_wo_retrans;
analyzer('html_print', ['<p><b>Mote Versus Number of Retransmission/Packet Transmission</b>']); analyzer('print_br');;
try
    output{1} = moteid;
    output{2} = retran_ave;
    output{3} = 'Mote Id';
    output{4} = 'Number of Retransmission / Packet Transmission';
    output{5} = 'Mote Versus Number of Retransmission / Packet Transmission';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'retrans_per_transmission';
    analyzer('plot_graph', output);
catch
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
analyzer('html_print', ['<p><b>Mote Versus Effort</b>']); analyzer('print_br');
total_transmissions = packet_forward_result + total_retransmission_result + data_generated_result;
effort = total_transmissions ./ data_generated_result;
try
    output{1} = moteid;
    output{2} = effort;
    output{3} = 'Mote Id';
    output{4} = 'Effort = Total Transmission / Data Generated';
    output{5} = 'Mote Versus Effort';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'effort';
    analyzer('plot_graph', output);
catch
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
analyzer('html_print', ['<p><b>Deliver Cost</b>']); analyzer('print_br');
deliver_cost = effort ./ success_rate;
try
    output{1} = moteid;
    output{2} = deliver_cost;
    output{3} = 'Mote Id';
    output{4} = 'Deliver Cost = Effort / Success Rate';
    output{5} = 'Mote Versus Deliver Cost';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'deliver_cost';
    analyzer('plot_graph', output);
catch
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
analyzer('html_print', ['<p><b>Routing Tree</b>']); analyzer('print_br');;
analyzer('html_print', ['<table><tr>']);
analyzer('html_print', ['<td width=100 valign=top><b>Mote Id<br>Parent</b></td>']);
for i = 1:length(moteid)
    analyzer('html_print', ['<td width=100 valign=top>']);
    analyzer('html_print', [num2str(moteid(i))]);
    analyzer('print_br');;
    analyzer('html_print', [num2str(parent_result(i))]);
    analyzer('html_print', ['</td>']);
end
analyzer('html_print', ['</tr></table>']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
try
    plot_stability;
catch
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
analyzer('html_print', ['<p><b> Mote Vesus Their Hops </b>']); analyzer('print_br');;
try
    output{1} = moteid;
    output{2} = hop_count_result;
    output{3} = 'Mote Id';
    output{4} = 'Number of Hops';
    output{5} = 'Mote Versus Their Hop';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'hop_count';
    analyzer('plot_graph', output);
catch
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
analyzer('html_print', ['<p><b>Mote Vesus Number of Expected Transmission</b>']); analyzer('print_br');;
try
    output{1} = moteid;
    output{2} = estimated_transmission_result ./ 4;
    output{3} = 'Mote Id';
    output{4} = 'Number of Expected Transmission';
    output{5} = 'Mote Versus Number of Expected Transmission';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'estimated_transmission';
    analyzer('plot_graph', output);
catch
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

analyzer('html_print', ['<p><b>Mote Vesus Number of Actual Transmission</b>']); analyzer('print_br');;
try
    output{1} = moteid;
    output{2} = actual_transmission_result;
    output{3} = 'Mote Id';
    output{4} = 'Number of Actual Transmission';
    output{5} = 'Mote Versus Number of Actual Transmission';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'actual_transmission';
    analyzer('plot_graph', output);
catch
end

analyzer('html_print', ['<b>Total Number of Cycles Detected</b>: ' num2str(sum(num_cycle))]);
analyzer('print_br');;
try
    output{1} = moteid;
    output{2} = num_cycle;
    output{3} = 'Mote Id';
    output{4} = 'Number of Cycle Detected';
    output{5} = 'Mote Versus Number of Cycle Detected';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'cycle_detected';
    analyzer('plot_graph', output);
catch
end

analyzer('html_print', ['<b>Total Number of Packet Send Without A Valid Parent</b>: ' num2str(sum(no_parent_count))]);
analyzer('print_br');;
try
    output{1} = moteid;
    output{2} = no_parent_count;
    output{3} = 'Mote Id';
    output{4} = 'Number of Packet Send Without A Valid Parent';
    output{5} = 'Mote Versus Number of Packet Send Without A Valid Parent';
    output{6} = [min(output{1}) max(output{1}) 0 max(output{2})];
    output{7} = 'packet_withno_parent';
    analyzer('plot_graph', output);
catch
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% stability from real data
sp = StatPacket;
[final_result, final_time] = generic_time_fetch(num2str(sp.offset_parentChange), result, moteid);
analyzer('html_print', ['<p><b>Stability From Real Data Over Time </b>']); analyzer('print_br');;
stability = sum(final_result, 2);
stability = stability';
% stability here is cumulative, so need to do a diff
stability = stability - [0 stability(1:(length(stability) - 1))];
output{1} = final_time;
output{2} = stability;
output{3} = 'Time';
output{4} = ['Number of Changes in parent'];
output{5} = ['Time Versus Number of Changes in parent'];
output{6} = [min(output{1}) max(output{1}) 0 max(output{2}) + 1];
output{7} = ['accurate_stability'];
analyzer('plot_graph', output);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
analyzer('html_print', ['<p><b>Hop Contour </b>']); analyzer('print_br');;
output{1} = moteid;
output{2} =  hop_count_result;
output{3} = 'Mote Id';
output{4} = '';
output{5} = ['Contour map of hop'];
output{6} = [min(output{1}) max(output{1}) 0 max(output{2}) + 1]; % this doesn't matter
output{7} = ['hop_contour'];
analyzer('plot_hop_contour', output);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% for i = 2:length(moteid)
%     try
%         analyzer('html_print', ['<p><b>Hop Histogram for mote ' num2str(moteid(i)) '</b>']); analyzer('print_br');;
%         output{1} = hop_cumulative{i};
%         min_hop = min(output{1});
%         max_hop = max(output{1});
%         if min_hop == max_hop
%             output{2} = min_hop;
%         else
%             output{2} = min(hop_cumulative{i}):max(hop_cumulative{i});
%         end
%         output{3} = 'Hop';
%         output{4} = 'Frequency';
%         output{5} = 'Hop Histogram';
%         output{6} = ['hop_histogram_n' num2str(moteid(i))];
%         analyzer('plot_histogram', output);
%     catch
%     end
% end
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% average forwardQueueSize over time
% 
% analyzer('html_print', ['<p><b>Average Forward QueueSize Over Time</b>']); analyzer('print_br');;
% 
% sp = StatPacket;
% [final_result, final_time] = generic_time_fetch(num2str(sp.offset_forwardQueueSize), result, moteid);
% [return_result, return_time] = generic_time_filter(moteid, final_result, final_time);
% for i =2:length(moteid)
%   analyzer('html_print', ['<p><b>Average Forward QueueSize Over Time for node ' num2str(i) '</b>']); analyzer('print_br');;
%   this_time = return_time{i};
%   this_data = return_result{i};
%   if (isempty(this_data)), continue;,  end
%   output{1} = this_time;
%   output{2} = this_data;
%   output{3} = 'Time';
%   output{4} = ['Average Queue Size for node ' num2str(i)];
%   output{5} = ['Time Versus Average Queue Size for node ' num2str(i)];
%   output{6} = [min(output{1}) max(output{1}) 0 max(output{2}) + 1];
%   output{7} = ['queuesize' num2str(i)];
%   analyzer('plot_graph', output);
% end
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% mean % of descendent in our neighbor table
% sp = StatPacket;
% [final_result, final_time] = generic_time_fetch(num2str(sp.offset_numChildren), result, moteid);
% [return_result, return_time] = generic_time_filter(moteid, final_result, final_time);
% for i = 2:length(moteid)
%   analyzer('html_print', ['<p><b>Number of Descendent Over Time for node ' num2str(i) '</b>']); analyzer('print_br');;
%   this_time = return_time{i};
%   this_data = return_result{i};
%   if (isempty(this_data)), continue;,  end
%   output{1} = this_time;
%   output{2} = this_data;
%   output{3} = 'Time';
%   output{4} = ['Number of Descendent in Table for node ' num2str(i)];
%   output{5} = ['Time Versus Number of Descendent in Table for node ' num2str(i)];
%   output{6} = [min(output{1}) max(output{1}) 0 max(output{2}) + 1];
%   output{7} = ['childrenintable' num2str(i)];
%   analyzer('plot_graph', output);
% end





