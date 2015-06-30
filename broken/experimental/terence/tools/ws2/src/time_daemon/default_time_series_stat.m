function output = default_time_series_stat(varargin)
output = feval(varargin{:});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = initialise
global time_series all_mote sim_params;
time_series.simulation_time = [];
time_series.hop = [];
time_series.path_est = [];
time_series.link_est = [];
time_series.routes = [];
time_series.data_bs_received = [];
time_series.data_sent = [];
time_series.num_retransmit=[];
time_series.collided_packet=[];
time_series.corrupted_packet=[];
% below are not statistics
time_series.clock_count = 0;
time_series.changed = 0;

ws('insert_event', sim_params.time_series_stat, 'time_series_tick', sim_params.time_series_tick, 0, {});
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = time_series_tick(id)
global sim_params time_series all_mote protocol_params radio_params bs_stat mote_stat link_stat
void = -1;
time_series.simulation_time = [ time_series.simulation_time; sim_params.simulation_time ];
time_series.hop = [time_series.hop; all_mote.hop];
time_series.routes = [time_series.routes; all_mote.parent];
time_series.data_bs_received = [ time_series.data_bs_received; bs_stat.data_received ];
time_series.data_sent = [ time_series.data_sent; mote_stat.data_sent ];
time_series.num_retransmit = [ time_series.num_retransmit;  link_stat.num_retransmit];
time_series.collided_packet = [ time_series.collided_packet; link_stat.collided_app_packet];
time_series.corrupted_packet = [ time_series.corrupted_packet; link_stat.corrupted_app_packet];


% statistic collect based on protocol
feval([sim_params.protocol '_series_tick'], id);
% change at specific time
if ~time_series.changed & sim_params.simulation_time > sim_params.apply_change_time
    feval(sim_params.time_change_func);
    time_series.changed = 1;
end

ws('insert_event', sim_params.time_series_stat, 'time_series_tick', sim_params.time_series_tick, 0, {});
% COMPILE %if sim_params.gui_mode & mod(time_series.clock_count, 5) == 0, gui_layer('textbox_display', ['Current Simulation Time is ' num2str(sim_params.simulation_time/100000) ' secs.']);,end;
if ~sim_params.gui_mode & mod(time_series.clock_count, 10) == 0, disp(['Current Simulation Time is ' num2str(sim_params.simulation_time/100000) ' secs.']);, end
time_series.clock_count = time_series.clock_count + 1;

function broadcast_series_tick(id)

function mrp_series_tick(id)
global time_series all_mote protocol_params
time_series.path_est = [time_series.path_est; all_mote.path_est];    
save_link_est;
time_series.link_est(size(time_series.link_est,1),:) = time_series.link_est(size(time_series.link_est,1),:) ./ protocol_params.link_scale;


function mrp_shortest_path_series_tick(id)
global time_series all_mote protocol_params
time_series.path_est = [time_series.path_est; all_mote.path_est];    
save_link_est;
time_series.link_est(size(time_series.link_est,1),:) = time_series.link_est(size(time_series.link_est,1),:) ./ protocol_params.link_scale;


function shortest_path_route_stack_series_tick(id)
save_link_est;

function least_trans_path_route_stack_series_tick(id)
save_link_est;

function shortest_path_series_tick(id)
save_link_est;

function least_trans_path_series_tick(id)
save_link_est;

function least_trans_path_ticket_feedback_series_tick(id)
save_link_est;

function exp_shortest_path_series_tick(id)
save_link_est;

function dsdv_shortest_path_series_tick(id)
%save_link_est;
return;

function change_base_station
global all_mote sim_params protocol_params;
all_mote.radio_disable(1) = 1;
sim_params.base_station = 49;
all_mote.hop(49) = 0;
all_mote.parent(49) = protocol_params.invalid_parent;
all_mote.route_seq_num(49) = all_mote.route_seq_num(1);

function surge_demo_series_tick(id)
save_link_est;

function save_link_est
global sim_params all_mote protocol_params time_series
neighbor_list = protocol_params.neighbor_list;
link_est = [];
for i = 1:sim_params.total_mote
    parent = all_mote.parent(i);
    parent_index = [];
    nodeID = protocol_params.neighbor_list(i).nodeID;
    if ~isempty(nodeID), parent_index = find([protocol_params.neighbor_list(i).nodeID] == parent);, end
    link_est_value = 0;
    if ~isempty(parent_index), link_est_value = neighbor_list(i).in_est(parent_index);, end
    link_est = [link_est link_est_value];
end
time_series.link_est = [ time_series.link_est; link_est ];


function disable_mote_ten
global all_mote
all_mote.radio_disable(10) = 1;
disp(['Mote 10 is disabled']);

function do_nothing


function disable_three_motes
global all_mote
mote_to_disable = [5, 10, 30];
for i=1:length(mote_to_disable)
    all_mote.radio_disable(mote_to_disable(i)) = 1;
end

function change_connectivity
global radio_params sim_params;
radio_params.prob_predefined_file = 'defaults\49on126';
feval(sim_params.model,'read_prob_matrix');
