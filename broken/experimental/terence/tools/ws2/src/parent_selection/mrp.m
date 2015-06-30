function output = mrp(varargin)
output = feval(varargin{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Public Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is called to initialise this applicaton
function void = settings
global protocol_params;
protocol_params.list_time_out = 2;
protocol_params.route_packet_length =  666;% In bits
protocol_params.phase_shift_window = 100000; % 1sec
protocol_params.track_info_window = 80;
protocol_params.parent_sel_threshold = 0.20;%0.15;
protocol_params.expire_round_ratio = 10;
protocol_params.min_samples = 8;
protocol_params.parent_penalty = 0.5;
protocol_params.link_scale = 1;
void = -1;

function void = initialise(id, start_time)
global all_mote protocol_stat protocol_params sim_params route_phase_shift;

all_mote.parent(id) = protocol_params.invalid_parent; 
protocol_params.neighbor_list(id).nodeID = [];
protocol_params.neighbor_list(id).in_est = [];
protocol_params.neighbor_list(id).out_est = [];
protocol_params.neighbor_list(id).path_est = [];
protocol_params.neighbor_list(id).track_info = [];
protocol_params.neighbor_list(id).hop = [];
protocol_params.neighbor_list(id).time_out = [];
protocol_params.round_update(id) = 0;
if id == sim_params.base_station
    all_mote.hop(id) = 0;
    all_mote.path_est(id) = 1;
else
    all_mote.path_est(id) = 0;
    all_mote.hop(id) = +Inf;
end
protocol_stat.neighbor_update(id) = 0;
void = -1;
protocol_params.mote_func = 'square_mote_withno_menu';
protocol_params.parent_line_func = 'parent_line_with_menu';
protocol_params.mote_text_func = 'default_mote_text';
route_phase_shift(id) = 0;
ws('insert_event', 'mrp', 'clock_tick', start_time, id, {});

% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_func, id, all_mote.X(id), all_mote.Y(id));, end
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ...
% COMPILE %        ['Mote ' num2str(id)]);, end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is same as initialise but this is only called once for all mote. it is called after
% each node is initialise.
function void = global_initialise
global protocol_params
protocol_params.no_save = -2;
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clock tick function
function void = clock_tick(id)
global all_mote sim_params protocol_params app_params protocol_stat route_phase_shift;

packet = mrp_routing_packet(id, all_mote.hop(id), all_mote.path_est(id), protocol_params.neighbor_list(id), protocol_params.route_packet_length);
feval(sim_params.radio, 'send_packet', id, packet);
interval = protocol_params.route_clock_interval + route_phase_shift(id);
invalid_neighbor_index = find(protocol_params.neighbor_list(id).time_out <= 0);
protocol_params.neighbor_list(id).in_est(invalid_neighbor_index) = 0;
protocol_params.neighbor_list(id).time_out = protocol_params.neighbor_list(id).time_out - 1;
route_select(id);

ws('insert_event', 'mrp', 'clock_tick', interval, id, {});
route_phase_shift(id) = 0;
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = send_packet(id, packet)
global sim_params;
feval(sim_params.radio, 'send_packet', id, packet);
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = send_packet_done(id, packet, result)
global sim_params protocol_params protocol_stat route_phase_shift;
if packet.type ~= protocol_params.route_packet_type
    feval(sim_params.application, 'send_packet_done', id, packet, result);
    route_phase_shift(id) = floor(rand * protocol_params.phase_shift_window);
else
    protocol_stat.neighbor_update(id) = protocol_stat.neighbor_update(id) + 1; 
end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = receive_packet(id, receive_packet)
global sim_params protocol_params all_mote

if receive_packet.type ~= protocol_params.route_packet_type
    process_data_packet(id, receive_packet);
    feval(sim_params.application, 'receive_packet', id, receive_packet);
else
    process_routing_packet(id, receive_packet);    
end
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ...
% COMPILE %        ['Mote ' num2str(id) ' p ' num2str(all_mote.parent(id))]);, end

void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function process_data_packet(id, receive_packet)
global protocol_params all_mote
[new, index] = find_neighbor_index(receive_packet.source, protocol_params.neighbor_list(id));
if new
    save_neighbor_list(id, index, receive_packet.source, +Inf, ... % hop
        0, 0, ...
        0, track_packet(receive_packet.link_seqnum, [])); % track_info
else
    save_neighbor_list(id, index, receive_packet.source, protocol_params.no_save, ...
        protocol_params.no_save, calculate_est(protocol_params.neighbor_list(id).track_info(index)), ... % out_est
        protocol_params.no_save, track_packet(receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index))); % track_info
end

%% If there is a cycle, try to give the current parent a penality.
if receive_packet.data_source == id & receive_packet.parent == id
    [parent_new, parent_index] = find_neighbor_index(all_mote.parent(id), protocol_params.neighbor_list(id));
    protocol_params.neighbor_list(id).path_est(parent_index) = protocol_params.neighbor_list(id).path_est(parent_index) * protocol_params.parent_penalty;
    route_select(id);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function process_routing_packet(id, receive_packet)
%% update the neighbor_list based on the input packet, return the source's neighbor struct
update_neighbor_list(id, receive_packet);
route_select(id);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function route_select(id)
global all_mote sim_params protocol_params;
if id == sim_params.base_station, return;, end
protocol_params.round_update(id) = protocol_params.round_update(id) + 1;
% Find the best path_est and in_est product
tmp_path_est = protocol_params.neighbor_list(id).path_est .* protocol_params.neighbor_list(id).in_est;
% from bad to good
[best_path, best_index] = max(tmp_path_est);

% Find the current estimation of the parent
cur_parent_path_est = 0;
cur_parent_hop = +Inf;
if ~isempty(protocol_params.neighbor_list(id).nodeID)
    [cur_parent, cur_parentindex] = find(protocol_params.neighbor_list(id).nodeID==all_mote.parent(id));
    if ~isempty(cur_parentindex) & protocol_params.neighbor_list(id).time_out > 0
        cur_parent_path_est = protocol_params.neighbor_list(id).in_est(cur_parentindex) * protocol_params.neighbor_list(id).path_est(cur_parentindex);
        cur_parent_hop = protocol_params.neighbor_list(id).hop(cur_parentindex) + 1;
    end
end

% Scaling
%cur_parent_path_est = cur_parent_path_est / protocol_params.link_scale;
%best_path = best_path / protocol_params.link_scale;

% Update my current estimation with my parent information
%if (abs(all_mote.path_est(id) - cur_parent_path_est) > 0.1)
%all_mote.path_est(id) = cur_parent_path_est;
%end
all_mote.path_est(id) = cur_parent_path_est;
all_mote.hop(id) = cur_parent_hop;


if (best_path - cur_parent_path_est > protocol_params.parent_sel_threshold)
    if best_path > 0        
        all_mote.parent(id) = protocol_params.neighbor_list(id).nodeID(best_index);
        all_mote.path_est(id) = best_path;
        all_mote.hop(id) = protocol_params.neighbor_list(id).hop(best_index) + 1;
        
        % COMPILE %if sim_params.gui_mode, 
        % COMPILE %    feval('gui_layer', protocol_params.parent_line_func, id, all_mote.X(id), all_mote.Y(id), ...
        % COMPILE %        all_mote.X(all_mote.parent(id)), all_mote.Y(all_mote.parent(id)), ...
        % COMPILE %        'Reliability', ['app_lib(''display_reliability'', ' num2str(id) ');']);
        % COMPILE %end;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_neighbor_list(id, receive_packet)
global protocol_params;

[new, index] = find_neighbor_index(receive_packet.source, protocol_params.neighbor_list(id));
[neighbor_new, index_feedback] = find_neighbor_index(id, receive_packet.neighbor_list);
in_est = 0;
if ~neighbor_new, in_est = receive_packet.neighbor_list.out_est(index_feedback);, end

if new
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, ...
        in_est, 0, ...
        receive_packet.path_est, track_packet(receive_packet.link_seqnum, []));
else
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, ...
        in_est, calculate_est(protocol_params.neighbor_list(id).track_info(index)), ...
        receive_packet.path_est, track_packet(receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index)));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function track_info = track_packet(seq_num, track_info)
%% calculate how many packet we missed by subtracting the seqnum of the current packet to
%% the sequence number of the packet i receive
if isempty(track_info)
    track_info.seqnum = seq_num - 1;
    track_info.missed_packets = 0;
    track_info.got_packets = 0;
end

if seq_num <= track_info.seqnum
    return;
end

missed_packet = seq_num - track_info.seqnum - 1;
%% update missed packet
track_info.missed_packets = track_info.missed_packets + missed_packet;
%% increment got_packets
track_info.got_packets = track_info.got_packets + 1;
%% save down the sequence number
track_info.seqnum = seq_num;

function prob = calculate_est(track_info)
global protocol_params;
if track_info.got_packets > protocol_params.min_samples
    %% receive estimation will be how many packet we receive over the total packet that we got. 
    prob = track_info.got_packets / ( track_info.got_packets + track_info.missed_packets);
else
    prob = 0;
end

prob = prob * protocol_params.link_scale;

% Put bound on probability estimate
%if prob >= 1
%    prob = .8;
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mrp_packet = mrp_routing_packet(source, hop, path_est, neighbor_list, length)
global protocol_params radio_params;
mrp_packet.source = source;
mrp_packet.hop = hop;
mrp_packet.path_est = path_est;
mrp_packet.neighbor_list = neighbor_list;
mrp_packet.type = protocol_params.route_packet_type;
mrp_packet.length = length;
mrp_packet.parent = radio_params.broadcast_addr;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function est = link_est(source, dest)
global protocol_params
dest_index = find(protocol_params.neighbor_list(source).nodeID == dest);
est = protocol_params.neighbor_list(source).in_est(dest_index) / protocol_params.link_scale;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [new, index] = find_neighbor_index(nodeID, neighbor_list)
index = [];
if ~isempty(neighbor_list.nodeID)
    index = find(nodeID == neighbor_list.nodeID);
end
new = 0;
if isempty(index), index = length(neighbor_list.nodeID) + 1; new = 1;, end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function save_neighbor_list(id, index, nodeID, hop, in_est, out_est, path_est, track_info)
global protocol_params
protocol_params.neighbor_list(id).nodeID(index) = nodeID;
if in_est ~= protocol_params.no_save, protocol_params.neighbor_list(id).in_est(index) = in_est;, end;
if path_est ~= protocol_params.no_save, protocol_params.neighbor_list(id).path_est(index) = path_est;, end;
if hop ~= protocol_params.no_save, protocol_params.neighbor_list(id).hop(index) = hop;, end;
if out_est ~= protocol_params.no_save, protocol_params.neighbor_list(id).out_est(index) = out_est;, end;
no_save_track_info = isfield(track_info, 'seqnum');
if isempty(protocol_params.neighbor_list(id).track_info) & no_save_track_info
    protocol_params.neighbor_list(id).track_info = [track_info];
elseif no_save_track_info
    protocol_params.neighbor_list(id).track_info(index) = track_info;
end
protocol_params.neighbor_list(id).time_out(index) = protocol_params.list_time_out;