function output = app_lib(varargin)
output = feval(varargin{:});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is called to see what stats funciton is available
function choices = get_stat_funcs
choices = {'Cumulative_Hop_Count', ...
        'Hop_Count', ...
        'Cumulative_Path_Est', ...
        'Actual_Path', ...
        'Cumulative_Actual_Path',...
        'Data_Packet_BS_Received', ...
        'Total_Packet_Sent', ...
        'Data_With_Relaying', ...
        'Data_Generated',...
        'Collided_Packets', ...
        'Corrupted_Packets', ...
        'Number_Parents_Over_Time', ...
        'Stability_Over_Time', ...
        'Actual_Link_Quality', ...
        'Link_Estimate_Error', ...
        'Link_Estimate_Error_SD', ...
        'Path_Estimate_Error', ...
        'Path_Estimate_Error_SD', ...
        'Effort', ...
        'Yield', ...
        'Deliver_Cost', ...
        'Average_Hop_Over_Time'...
        'Yield_Versus_Hop'};

function output = get_distance_to_base_station_for_all_motes
global sim_params radio_params;
distance_to_base_station=[];
for i=1:sim_params.total_mote
    distance_to_base_station = [distance_to_base_station radio_params.dist_matrix(i,sim_params.base_station)];
end
output = distance_to_base_station;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Yield_Versus_Hop
global mote_stat link_stat bs_stat sim_params all_mote
data_generated = mote_stat.app_seqnum;
data_received = bs_stat.data_received;
success_rate =  data_received ./ data_generated;
sum_success_rate = []
success_rate_counter = [];

hops = calculate_hop_count(all_mote.parent);%all_mote.hop;
no_hop_index = find(hops == +Inf);
hops(no_hop_index) = -1;

for i = 1:length(all_mote.id)
  current_hop = hops(i);
  if (current_hop == -1) continue;
  try
    sum_success_rate(current_hop);
  catch
    sum_success_rate(current_hop) = success_rate(i);
    success_rate_counter(current_hop) = 1;
    continue;
  end
  sum_success_rate(current_hop) = sum_success_rate(current_hop) + success_rate(i);
  success_rate_counter(current_hop) = success_rate_counter(current_hop) + 1;
end

avg_success_rate_over_hop = success_rate_counter ./ sum_success_rate;
output{1} = 1:length(success_rate_counter);
output{2} = avg_success_rate_over_hop;
output{3} = 'Hop Count';
output{4} = 'Average Success Rate';
output{5} = 'Average Success Rate Over Hop Count';
output{6} = [0 max(success_rate_counter) 0 max(avg_success_rate_over_hop)];
output{7} = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Effort_Versus_Hop
global mote_stat link_stat bs_stat sim_params all_mote
data_generated = mote_stat.app_seqnum;
effort = (mote_stat.data_sent + link_stat.num_retransmit) ./ data_generated;

sum_effort = []
effort_counter = [];

hops = calculate_hop_count(all_mote.parent);%all_mote.hop;
no_hop_index = find(hops == +Inf);
hops(no_hop_index) = -1;

for i = 1:length(all_mote.id)
  current_hop = hops(i);
  if (current_hop == -1) continue;
  try
    sum_effort(current_hop);
  catch
    sum_effort(current_hop) = effort(i);
    effort_counter(current_hop) = 1;
    continue;
  end
  sum_effort(current_hop) = sum_effort(current_hop) + effort(i);
  effort_counter(current_hop) = effort_counter(current_hop) + 1;
end

avg_effort_over_hop = sum_effort ./ effort_counter;
output{1} = 1:length(effort_counter);
output{2} = avg_effort_over_hop;
output{3} = 'Hop Count';
output{4} = 'Average Effort (originated + forwarding + retranmssion) / received';
output{5} = 'Average Effort Over Hop Count';
output{6} = [0 max(effort_counter) 0 max(avg_effort_over_hop)];
output{7} = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Actual_Path_Reliablity_Versus_Hop
global mote_stat link_stat bs_stat sim_params all_mote radio_params sim_params protocol_params
parents = all_mote.parent;
probs = zeros(1, sim_params.total_mote);
for i = 1:sim_params.total_mote
    if parents(i) ~= protocol_params.invalid_parent
        probs(i) = radio_params.prob_table(i, parents(i));
    end
end
result = calculate_actual_path(parents, probs);

sum_path_reliability = []
counter = [];

hops = calculate_hop_count(all_mote.parent);%all_mote.hop;
no_hop_index = find(hops == +Inf);
hops(no_hop_index) = -1;

for i = 1:length(all_mote.id)
  current_hop = hops(i);
  if (current_hop == -1) continue;
  try
    sum_path_reliability(current_hop);
  catch
    sum_path_reliability(current_hop) = result(i);
    counter(current_hop) = 1;
    continue;
  end
  sum_path_reliability(current_hop) = sum_path_reliability(current_hop) + result(i);
  counter(current_hop) = counter(current_hop) + 1;
end

avg_path_reliability = sum_path_reliability ./ counter;
output{1} = 1:length(counter);
output{2} = avg_path_reliability;
output{3} = 'Hop Count';
output{4} = 'Average Actual Path Reliability';
output{5} = 'Average Actual Path Reliability Over Hop Count';
output{6} = [0 max(counter) 0 max(avg_path_reliability)];
output{7} = 1;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Effort
global mote_stat link_stat bs_stat sim_params
data_generated = mote_stat.app_seqnum;
effort = (mote_stat.data_sent + link_stat.num_retransmit) ./ data_generated;
output{1} = 1:sim_params.total_mote; 
output{2} = effort;
output{3} = 'Mote ID (Source)';
output{4} = 'Effort = (originated + forwarding + retransmission) / received';
output{5} = 'Effort Versus Mote';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Yield
global mote_stat bs_stat sim_params
data_generated = mote_stat.app_seqnum;
data_received = bs_stat.data_received;
success_rate =  data_received ./ data_generated;
output{1} = 1:sim_params.total_mote; 
output{2} = success_rate;
output{3} = 'Mote ID (Source)';
output{4} = 'Yield = (Data Generated / Data Received)';
output{5} = 'Yield Versus Mote';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Deliver_Cost
global mote_stat link_stat bs_stat all_mote sim_params
data_generated = mote_stat.app_seqnum;
effort = (mote_stat.data_sent + link_stat.num_retransmit) ./ data_generated;
data_generated = mote_stat.app_seqnum;
data_received = bs_stat.data_received;
success_rate =  data_received ./ data_generated;
cost = effort ./ success_rate;
output{1} = 1:sim_params.total_mote; 
output{2} = cost;
output{3} = 'Mote ID (Source)';
output{4} = 'Deliver Cost = Effor * Yield';
output{5} = 'Deliever Cost Versus Mote';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Average_Hop_Over_Time
global time_series sim_params all_mote sim_params protocol_params
simulation_time_length = size(time_series.simulation_time, 1);
hops = time_series.hop;
avg = [];
j = 1;
granularity = protocol_params.route_clock_interval / sim_params.time_series_tick;
num_slots = size(hops, 1) / granularity;
for n=0:ceil(num_slots) - 1
    max_index = min((n + 1)* granularity, size(hops, 1));
    sub_hops = hops(n * granularity + 1:max_index , :);
    sub_hops = sub_hops(find (sub_hops ~= Inf));
    avg = [avg (sum(sub_hops(:)) / (size(sub_hops, 1) * size(sub_hops, 2)))];
    j = j + protocol_params.route_clock_interval / sim_params.time_series_tick;
end

  
output{1} = 1:(protocol_params.route_clock_interval/100000):(max(time_series.simulation_time)/100000);%1:(time_series.simulation_time / protocol_params.route_clock_interval);%time_series.simulation_time' / 100000;
output{2} = avg;
output{3} = 'Simulation Time';
output{4} = 'Average Network Hop Count';
output{5} = 'Average Network Hop Count Over Time';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Cumulative_In_Degree
global all_mote;
in_degree = zeros(1,length(all_mote.id));
for parent=1:length(all_mote.id)
    for child=1:length(all_mote.id)
        if parent == all_mote.parent(child)
            in_degree(parent) = in_degree(parent) + 1;
        end
    end
end
output{1} = 1:10;
output{2} = hist(in_degree, output{1});%./(length(all_mote.id)/100);
output{3} = 'In Degree';
output{4} = 'Percent number of nodes';
output{5} = 'In Degree Histogram';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = In_Degree
global all_mote;
in_degree = zeros(1,length(all_mote.id));
for parent=1:length(all_mote.id)
    for child=1:length(all_mote.id)
        if parent == all_mote.parent(child)
            in_degree(parent) = in_degree(parent) + 1;
        end
    end
end
output{1} = get_distance_to_base_station_for_all_motes;
output{2} = in_degree;
output{3} = 'Distance(ft)';
output{4} = 'In Degree';
output{5} = 'In Degree vs Distance';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% this is teh cumulative hop count function from the plot data
%% this is just going to generate a vector of hop for plot_data to 
%% produce a cumulative graph
%% REQUIRE: mote have to have a field called hop
function output = Cumulative_Hop_Count
global all_mote sim_params
hops = calculate_hop_count(all_mote.parent);%all_mote.hop;
no_hop_index = find(hops == +Inf);
hops(no_hop_index) = -1;
output{1} = min(hops):max(hops);
output{2} = hist(hops, output{1});
output{3} = 'Hops';
output{4} = 'Frequency';
output{5} = 'Cumulative Hop Frequency Graph';
output{6} = [min(output{1}) max(output{1}) min(output{2}) max(output{2})];
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This plots the histogram of the parent link quality of the entire network
%
function output = Actual_Link_Quality
global all_mote protocol_params radio_params protocol_params;
link_dist=[];
for i=2:max(all_mote.id)
    if (all_mote.parent(i) ~= protocol_params.invalid_parent)
        link_dist = [link_dist; radio_params.prob_table(i, all_mote.parent(i))];
    end
end
output{1} = 0:0.1:1;
output{2} = hist(link_dist, 0:0.1:1);
output{3} = 'Link Quality to Parent';
output{4} = 'Frequency';
output{5} = 'Edge Quality Frequency Graph';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% this is teh cumulative hop count function from the plot data
%% this is just going to generate a vector of hop for plot_data to 
%% produce a cumulative graph
%% REQUIRE: mote have to have a field called hop
function output = Hop_Count
global all_mote sim_params radio_params
hops = calculate_hop_count(all_mote.parent);%all_mote.hop;
no_hop_index = find(hops == +Inf);
hops(no_hop_index) = -1;
%output{1} = 1:sim_params.total_mote;
output{1} = get_distance_to_base_station_for_all_motes;
output{2} = hops;
output{3} = 'Distance(ft)';%'Mode ID';
output{4} = 'Hops';
output{5} = 'Distance vs Hops';%'Mote ID vs Hops';
output{6} = 'auto';
output{7} = 0;
output{8} = 'scatter';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% REQUIRE: basestation mote have to have field called data_received
function output = Data_Packet_BS_Received
global bs_stat sim_params
output{1} = 1:sim_params.total_mote; 
output{2} = bs_stat.data_received;
output{3} = 'Mote ID (Source)';
output{4} = 'Data Packet Base Station Received';
output{5} = 'Data Packet Received From Source';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% REQUIRE: field path_est on mote
%% this is the cumulative path est curve
function output = Cumulative_Path_Est
global all_mote sim_params
path_est = all_mote.path_est;

output{1} = get_distance_to_base_station_for_all_motes;%1:sim_params.total_mote;
output{2} = all_mote.path_est;
output{3} = 'Distance(ft)';%'Mote ID';
output{4} = 'Path Est';
output{5} = 'Distance vs Path Est';%'Mote ID vs Path Est';
output{6} = [0 max(output{1}) 0 1];
output{7} = 0;
output{8} = 'scatter';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% REQUIRE: field reliability path on mote
%% this is the cumulative acutal reliability of the path, this take O(n)!
%% D.F.S. baby!
function output = Actual_Path
global all_mote radio_params sim_params protocol_params
parents = all_mote.parent;
probs = zeros(1, sim_params.total_mote);
for i = 1:sim_params.total_mote
    if parents(i) ~= protocol_params.invalid_parent
        probs(i) = radio_params.prob_table(i, parents(i));
    end
end
result = calculate_actual_path(parents, probs);
output{1} = get_distance_to_base_station_for_all_motes;%1:sim_params.total_mote;
output{2} = result;
output{3} = 'Distance(ft)';%'Mote ID';
output{4} = 'Probability';
output{5} = 'Actual Path Reliabiliity';
output{6} = [0 max(output{1}) 0 1];
output{7} = 0;
output{8} = 'scatter';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Cumulative_Actual_Path
global all_mote radio_params sim_params protocol_params
parents = all_mote.parent;
probs = zeros(1, sim_params.total_mote);
for i = 1:sim_params.total_mote
    if parents(i) ~= protocol_params.invalid_parent
        probs(i) = radio_params.prob_table(i, parents(i));
    end
end
result = calculate_actual_path(parents, probs);
output{1} = 0:0.1:1;
output{2} = hist(result, 0:0.1:1);
output{3} = 'Probability';
output{4} = 'Frequency';
output{5} = 'Cumulative Actual Path Reliabiliity';
output{6} = [0 max(output{1}) 0 max(output{2})];
output{7} = 0;
output{8} = 'plot';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = calculate_actual_path(parents, probs)
global sim_params all_mote protocol_params
defined = zeros(1, sim_params.total_mote);
defined(sim_params.base_station) = 1;
result = ones(1, sim_params.total_mote);
% find invalid parent
invalid_parent_index = find(parents == protocol_params.invalid_parent);
result(invalid_parent_index) = 0;
result(sim_params.base_station) = 1;
defined(invalid_parent_index) = 1;
clean_visited = zeros(1, sim_params.total_mote);

for i = 1:sim_params.total_mote
    visited = clean_visited;
    [path_est, defined, parents, result, visited, probs] = calculate_actual_path_helper(i, defined, parents, result, visited, probs);
end

function [path_est, defined, parents, result, visited, probs] = calculate_actual_path_helper(current, defined, parents, result, visited, probs)
global sim_params radio_params
if defined(current)
    path_est = result(current);
elseif visited(current)
    % cycle!
    result(current) = 0;
    defined(current) = 1;
    path_est = 0;
else
    visited(current) = 1;
    [parent_est, defined, parents, result, visited, probs] = calculate_actual_path_helper(parents(current), defined, parents, result, visited, probs);
    defined(current) = 1;
    result(current) = probs(current) * parent_est;
    path_est = result(current);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = calculate_hop_count(parents)
global sim_params all_mote protocol_params
defined = zeros(1, sim_params.total_mote);
defined(sim_params.base_station) = 1;
result = ones(1, sim_params.total_mote);
% find invalid parent
invalid_parent_index = find(parents == protocol_params.invalid_parent);
result(invalid_parent_index) = +Inf;
result(sim_params.base_station) = 0;
defined(invalid_parent_index) = 1;
clean_visited = zeros(1, sim_params.total_mote);

for i = 1:sim_params.total_mote
    visited = clean_visited;
    [hop_count, defined, parents, result, visited] = calculate_hop_count_helper(i, defined, parents, result, visited);
end

function [hop_count, defined, parents, result, visited] = calculate_hop_count_helper(current, defined, parents, result, visited)
global sim_params radio_params
if defined(current)
    hop_count = result(current);
elseif visited(current)
    % cycle!
    result(current) = +Inf;
    defined(current) = 1;
    hop_count = +Inf;
else
    visited(current) = 1;
    [parent_est, defined, parents, result, visited] = calculate_hop_count_helper(parents(current), defined, parents, result, visited);
    defined(current) = 1;
    result(current) = parent_est + 1;
    hop_count = result(current);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Data_Generated
global mote_stat sim_params
data_generated = mote_stat.app_seqnum;
output{1} = 1:sim_params.total_mote;
output{2} = data_generated(1:sim_params.total_mote);
output{3} = 'Mote ID';
output{4} = 'Data Packets Generated';
output{5} = 'Mote ID vs. Data Packet Generated';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Data_With_Relaying
global mote_stat sim_params
data_with_relay = mote_stat.data_sent;
output{1} = 1:sim_params.total_mote;
output{2} = data_with_relay(1:sim_params.total_mote);
output{3} = 'Mote ID';
output{4} = 'Numbers of Data Packets Going Through With Relaying';
output{5} = 'Mote ID vs Data Packets';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Total_Packet_Sent
global all_mote sim_params
packets = all_mote.link_seqnum;
output{1} = 1:sim_params.total_mote;
output{2} = packets(1:sim_params.total_mote);
output{3} = 'Mote ID';
output{4} = 'Total Packet Sent';
output{5} = 'Mote ID vs Packets';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Collided_Packets
global link_stat sim_params
packets = link_stat.collided_app_packet;
output{1} = get_distance_to_base_station_for_all_motes;%1:sim_params.total_mote;
output{2} = packets(1:sim_params.total_mote);
output{3} = 'Distance(ft)';%'Mote ID';
output{4} = 'Total Packet Sent';
output{5} = 'Distance vs Pakcets';%'Mote ID vs Packets';
output{6} = 'auto';
output{7} = 0;
output{8} = 'scatter';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Corrupted_Packets
global link_stat sim_params
packets = link_stat.corrupted_app_packet;
output{1} = get_distance_to_base_station_for_all_motes;%1:sim_params.total_mote;
output{2} = packets(1:sim_params.total_mote);
output{3} = 'Distance(ft)';%'Mote ID';
output{4} = 'Total Packet Sent';
output{5} = 'Distance vs Pakcets';%'Mote ID vs Packets';
output{6} = 'auto';
output{7} = 0;
output{8} = 'scatter';



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Stability_Over_Time
global time_series sim_params all_mote sim_params protocol_params
simulation_time_length = size(time_series.simulation_time, 1);
hops = time_series.hop;
avg = [];
j = 1;
granularity = protocol_params.route_clock_interval / sim_params.time_series_tick;
num_slots = size(hops, 1) / granularity;
parents = time_series.routes;
changes = [];
past_parent = parents(1,:);
count = 0;
stability = [];
j = 0;
for i = 1:length(parents)
    current_parent = parents(i,:);
    count = count + sum(current_parent - past_parent ~= 0);
    past_parent = current_parent;
    j = j + 1;
    if j == granularity
        stability = [stability count];
        count = 0;
        j = 0;    
    end
end
output{1} = 1:(protocol_params.route_clock_interval/100000):(max(time_series.simulation_time)/100000);%1:(time_series.simulation_time / protocol_params.route_clock_interval);%time_series.simulation_time' / 100000;
output{2} = stability;
output{3} = 'Simulation Time';
output{4} = 'Stability';
output{5} = 'Stability Over Time';
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Number_Parents_Over_Time
global time_series sim_params protocol_params
parents = time_series.routes;
num_parents = sum((parents ~= protocol_params.invalid_parent)');
[array, index] = find(num_parents == (sim_params.total_mote - 1));
first_index = Inf;
first_time = Inf;
if ~isempty(index)
    first_index = index(1);
    first_time = time_series.simulation_time(first_index) / 100000;
end
time_series.first_time_index=first_index;
output{1} = time_series.simulation_time' / 100000;
output{2} = num_parents;
output{3} = 'Simulation Time';
output{4} = 'Number of Valid Parents';
output{5} = ['Number of Valid Parents Over Time. First Tree Formed when Time = ' num2str(first_time)];
output{6} = 'auto';
output{7} = 0;
output{8} = 'plot';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Link_Estimate_Error
global time_series sim_params;
time_series.actual_link = time_series_actual_link_cal(time_series);
err = abs(time_series.link_est - time_series.actual_link);
mean_err=[];
for i=1:size(time_series.simulation_time,1)
    all_positive_index = find(err(i,:) > 0);
    cur_err = err(i, all_positive_index);
    if ~isempty(cur_err)
        mean_err = [mean_err; [time_series.simulation_time(i) / 100000, mean(cur_err)]];
    end
end
simulation_time = [];
percent_error = [];
if ~isempty(mean_err)
    simulation_time = mean_err(:, 1);
    percent_error = mean_err(:, 2) * 100;
end
output{1} = simulation_time';
output{2} = percent_error';
output{3} = 'Simulation Time (s)';
output{4} = 'Mean Link Estimation Error';
output{5} = 'Link Estimation Error over Time';
output{6} = [0 max(time_series.simulation_time)/100000 0 100];
output{7} = 1;
output{8} = 'plot';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Link_Estimate_Error_SD
global time_series sim_params;
time_series.actual_link = time_series_actual_link_cal(time_series);
err = abs(time_series.link_est - time_series.actual_link);
sd_err=[];
for i=1:size(time_series.simulation_time,1)
    all_positive_index = find(err(i,:) > 0);
    cur_err = err(i, all_positive_index);
    if ~isempty(cur_err)
        sd_err = [sd_err; [time_series.simulation_time(i) / 100000, std(cur_err)]];
    end
end
simulation_time = [];
percent_error = [];
if ~isempty(sd_err)
    simulation_time = sd_err(:, 1);
    percent_error = sd_err(:, 2) * 100;
end
output{1} = simulation_time';
output{2} = percent_error';
output{3} = 'Simulation Time (s)';
output{4} = 'Link Estimation Error SD';
output{5} = 'Link Estimation Error SD over Time';
output{6} = [0 max(time_series.simulation_time)/100000 0 100];
output{7} = 1;
output{8} = 'plot';



function time_series_actual_link = time_series_actual_link_cal(time_series)
global sim_params protocol_params radio_params;
time_series_actual_link = [];
for steps=1:length(time_series.simulation_time);    
    parents = time_series.routes(steps,:);
    for i = 1:sim_params.total_mote
        if(parents(i) == protocol_params.invalid_parent)
            result(i) = -1;
        else
            result(i) = radio_params.prob_table(i, parents(i));
        end
    end
    time_series_actual_link = [time_series_actual_link; result];
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function output = Path_Estimate_Error
global time_series sim_params

time_series_actual_path_cal;
actual_path = time_series.actual_path;
%err = abs(time_series.path_est - actual_path)./actual_path;
err = abs(time_series.path_est - actual_path);
mean_err = [];
for i = 1:size(time_series.simulation_time,1)
    cur_err = err(i,find(err(i,:)>0));
    if ~isempty(cur_err)
        mean_err = [mean_err; [time_series.simulation_time(i)/100000, mean(cur_err)]];
    end
end
simulation_time = [];
percent_error = [];
if ~isempty(mean_err)
    simulation_time = mean_err(:, 1);
    percent_error = mean_err(:, 2) * 100;
end

output{1} = simulation_time';
output{2} = percent_error';
output{3} = 'Simulation Time (s)';
output{4} = 'Mean Path Estimation Error';
output{5} = 'Path Estimation Error over Time';
output{6} = [0 max(time_series.simulation_time)/100000 0 100];
output{7} = 1;
output{8} = 'plot';

function void = time_series_actual_path_cal
global sim_params protocol_params radio_params time_series
void = -1;
time_series.actual_path = [];

for steps = 1:length(time_series.simulation_time);
    defined = zeros(1, sim_params.total_mote);
    defined(sim_params.base_station) = 1;
    parents = time_series.routes(steps,:);
    result = ones(1, sim_params.total_mote);
    % find invalid parent
    invalid_parent_index = find(parents == protocol_params.invalid_parent);
    result(invalid_parent_index) = 0;
    result(sim_params.base_station) = 1;
    defined(invalid_parent_index) = 1;
    clean_visited = zeros(1, sim_params.total_mote);
    probs = zeros(1, sim_params.total_mote);
    for i = 1:sim_params.total_mote
        if parents(i) ~= protocol_params.invalid_parent
            probs(i) = radio_params.prob_table(i, parents(i));
        end
    end
    for i = 1:sim_params.total_mote
        visited = clean_visited;
        [path_est, defined, parents, result, visited, probs] = calculate_actual_path_helper(i, defined, parents, result, visited, probs);
    end
    time_series.actual_path = [time_series.actual_path; result];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function output = Path_Estimate_Error_SD
global time_series sim_params

if isempty(time_series.actual_path)
    time_series_actual_path_cal;
end
actual_path = time_series.actual_path;
%err = abs(time_series.path_est - actual_path)./actual_path;
err = abs(time_series.path_est - actual_path);
sd_err = [];
for i = 1:size(time_series.simulation_time,1)
    cur_err = err(i,find(err(i,:)>0));
    if ~isempty(cur_err)
        sd_err = [sd_err; [time_series.simulation_time(i)/100000, std(cur_err)]];
    end
end
simulation_time = [];
percent_error = [];
if ~isempty(sd_err)
    simulation_time = sd_err(:, 1);
    percent_error = sd_err(:, 2) * 100;
end

output{1} = simulation_time';
output{2} = percent_error';
output{3} = 'Simulation Time (s)';
output{4} = 'Path Estimation Error SD';
output{5} = 'Path Estimation Error SD over Time';
output{6} = [0 max(time_series.simulation_time)/100000 0 100];
output{7} = 1;
output{8} = 'plot';



    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SUB STAT FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function choices = sub_report_stat_funcs
choices = {'Path_Reliability_Over_Time', ...
    'Packet_Sent_Over_Time'};

function void = Path_Reliability_Over_Time(id)
global time_series
void = -1;
id_actual_path = time_series.actual_path(:, id) .* 100;
output{1} = (time_series.simulation_time / 100000)';
output{2} = id_actual_path';
output{3} = 'Simulation Time (s)';
output{4} = ['Acutal Path Prob for Mote ' num2str(id) ];
output{5} = ['Acutal Path Prob for Mote ' num2str(id) ' Over Time'];
output{6} = [0 max(time_series.simulation_time)/100000 0 100];
output{7} = 1;
output{8} = 'plot';

plot_data('plot_graph_helper', output);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Packet_Sent_Over_Time(id)
global time_series sim_params
id_data_sent = time_series.data_sent(:, id);
output{1} = (time_series.simulation_time / 100000)';
output{2} = id_data_sent';
output{3} = 'Simulation Time (s)';
output{4} = ['Data Sent With Relaying for Mote ' num2str(id) ];
output{5} = ['Data Sent With Relaying for Mote ' num2str(id) ' Over Time'];
output{6} = [0 max(time_series.simulation_time)/100000 0 max(output{2})];
output{7} = 1;
output{8} = 'plot';

plot_data('plot_graph_helper', output);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = Hop_Count_Over_Time(id)
global time_series sim_params
id_hop=[];
for i=1:length(time_series.simulation_time)
    hop_list = calculate_hop_count(time_series.routes(i,:));
    id_hop = [id_hop; hop_list(id)];
end

output{1} = (time_series.simulation_time / 100000)';
output{2} = id_hop';
output{3} = 'Simulation Time (s)';
output{4} = ['Hop Count for Mote ' num2str(id) ];
output{5} = ['Hop Count for Mote ' num2str(id) ' Over Time'];
output{6} = [0 max(time_series.simulation_time)/100000 0 max(output{2})];
output{7} = 1;
output{8} = 'plot';

plot_data('plot_graph_helper', output);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% REPORT FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = sub_report(id)
global all_mote mote_stat bs_stat link_stat sim_params protocol_params app_params
void = -1;
temp_dir = tempdir;
[blah1, html_dir, blah2] = fileparts(tempname);
htmlfilename = 'index.html';
fullhtmlpath = [temp_dir html_dir '\' htmlfilename];
mkdir(temp_dir, html_dir);
filefid = fopen(fullhtmlpath, 'w'); 
fprintf(filefid, '<html><head>'); 
fprintf(filefid, ['<title>Simulation Sub Report for Mote ' num2str(id) '</title>']); 
fprintf(filefid, '<body>'); 
fprintf(filefid, ['<h2><font color=red><title>Simulation Sub Report for Mote ' num2str(id) '</title></font></h2>']); 

choices = app_lib('sub_report_stat_funcs'); 
dirpath = [temp_dir html_dir];
for i = 1:length(choices) 
   current_func = choices{i}; 
   try 
       feval(current_func, id)
       img_fname = [current_func '.jpg']; 
       saveas(gcf, [dirpath '\' img_fname]);
       delete(gcf);
       fprintf(filefid, ['<b><font color=blue>' current_func '</font></b>']); print_br(filefid); 
       fprintf(filefid, ['<img src=''' img_fname ''' height=450 width=600>']); print_br(filefid); 
   catch 
       1;
   end 
end 

fprintf(filefid, '</body></html>'); 
fclose(filefid); 
status = web(fullhtmlpath,'-browser'); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = report
global all_mote mote_stat bs_stat link_stat sim_params protocol_params app_params time_series
void = -1;
temp_dir = tempdir;
[blah1, html_dir, blah2] = fileparts(tempname);
htmlfilename = 'index.html';
fullhtmlpath = [temp_dir html_dir '\' htmlfilename];
mkdir(temp_dir, html_dir);
filefid = fopen(fullhtmlpath, 'w'); 
fprintf(filefid, '<html><head>'); 
fprintf(filefid, '<title>Simulation Report</title>'); 
fprintf(filefid, '<body>'); 
fprintf(filefid, '<h2><font color=red>Simulation Report </font></h2>'); 
fprintf(filefid, ['<b><font color=blue>Protocol</font></b>: ' sim_params.protocol]); print_br(filefid); 
if isfield(protocol_params,'warmup_time')
    fprintf(filefid, ['<b><font color=blue>Warm Up Time</font></b>: ' num2str(protocol_params.warmup_time)]); print_br(filefid);
    fprintf(filefid, ['<b><font color=blue>Warm Up Rate</font></b>: ' num2str(protocol_params.route_clock_interval/protocol_params.route_speed_up)]); print_br(filefid);
end
if isfield(protocol_params,'estimator')
    fprintf(filefid, ['<b><font color=blue>Estimator</font></b>: ' protocol_params.estimator]); print_br(filefid);
    fprintf(filefid, ['<b><font color=blue>Number of Neighbors to Feedback</font></b>: ' num2str(protocol_params.num_neighbor_to_feedback)]); print_br(filefid);    
end
fprintf(filefid, ['<b><font color=blue>Simulation Duration</font></b>: ' num2str(sim_params.simulation_duration)]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Application</font></b>: ' sim_params.application]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Radio</font></b>: ' sim_params.radio]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Topology</font></b>: ' sim_params.topology_style]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Total Mote</font></b>: ' num2str(sim_params.total_mote)]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Range</font></b>: ' num2str(sim_params.range)]); print_br(filefid); 
neighbor_size = cal_neighbor_size;
fprintf(filefid, ['<b><font color=blue>Neighbor Density</font></b>: ' 'mean=' num2str(neighbor_size.mean) ' min=' num2str(neighbor_size.min) ' max=' num2str(neighbor_size.max)]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Data Clock Rate</font></b>: ' num2str(app_params.data_clock_interval)]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Route Clock Rate</font></b>: ' num2str(protocol_params.route_clock_interval)]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Total Packets Sent</font></b>: ' num2str(sum(all_mote.link_seqnum))]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Total Data Packets With Relaying</font></b>: ' num2str(sum(mote_stat.data_sent))]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Total Packets Generated</font></b>: ' num2str(sum(mote_stat.app_seqnum))]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Total Data Packet Base Station Received</font></b>: ' num2str(sum(bs_stat.data_received))]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Total Collided Packet</font></b>: ' num2str(sum(link_stat.collided_app_packet))]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Total Corrupt Packet</font></b>: ' num2str(sum(link_stat.corrupted_app_packet))]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Total Drop Cycle Packet</font></b>: ' num2str(sum(mote_stat.drop_cycle_packet))]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Overall Success Rate</font></b>: ' num2str(100*sum(bs_stat.data_received)/sum(mote_stat.app_seqnum)) '&#37']); print_br(filefid); 
num_retransmit=sum(time_series.num_retransmit(length(time_series.simulation_time),:));
fprintf(filefid, ['<b><font color=blue>Retransmission Overhead per packet received by BS</font></b>: ' num2str(num_retransmit/sum(bs_stat.data_received))]); print_br(filefid); 
fprintf(filefid, ['<b><font color=blue>Message Overhead per packet received by BS</font></b>: ' num2str((sum(mote_stat.data_sent)+num_retransmit)/sum(bs_stat.data_received))]); print_br(filefid); 

choices = app_lib('get_stat_funcs'); 
dirpath = [temp_dir html_dir];
for i = 1:length(choices) 
   current_func = choices{i}; 
   try 
       plot_data('plot_graph', current_func); 
       img_fname = [current_func '.jpg']; 
       saveas(gcf, [dirpath '\' img_fname]);
       delete(gcf);
       fprintf(filefid, ['<b><font color=blue>' current_func '</font></b>']); print_br(filefid); 
       fprintf(filefid, ['<img src=''' img_fname ''' height=450 width=600>']); print_br(filefid); 
   catch 
       1;
   end 
end 

fprintf(filefid, '</body></html>'); 
fclose(filefid); 
status = web(fullhtmlpath,'-browser'); 
%!c:\Program Files\Internet Explorer\IEXPLORE.EXE fullhtmlpath



function print_br(filefid) 
fprintf(filefid, '\n<br>'); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function output = cal_neighbor_size
global protocol_params sim_params
if ~isfield(protocol_params, 'neighbor_list')
    output.max = -1;
    output.min = -1;
    output.mean = -1;
    return;
end
neighbor_size=[];
for i=1:sim_params.total_mote
    neighbor_size = [neighbor_size length(protocol_params.neighbor_list(i).nodeID)];
end
output.mean = mean(neighbor_size);
output.min = min(neighbor_size);
output.max = max(neighbor_size);

%% REQUIRE: protocol has link_est funciton and radaio had get_probablity function
%%          allmote has parent field
function void = display_reliability(id)
global sim_params all_mote
link_est = feval(sim_params.protocol, 'link_est', id, all_mote.parent(id));
actual = feval(sim_params.radio, 'get_probability', id, all_mote.parent(id));
gui_layer('textbox_display', ['Estimate Reliability: ' num2str(link_est) 'Actual Reliability: ' num2str(actual)]);
void = -1;
