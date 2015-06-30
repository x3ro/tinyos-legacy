function output=broadcast(varargin)
output = feval(varargin{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Public Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is called to initialise this applicaton
% you need to specify what kind of gui functions you want. choices of gui function is provided in gui_layer
% assumption: initialise all the necessary field before calling draw_mote
function void = settings
global protocol_params;
protocol_params.route_packet_length =  666; % In bits
protocol_params.retransmit_probability = 1;
protocol_params.mote_func = 'square_mote_withno_menu';
protocol_params.parent_line_func = 'parent_line_withno_menu';
protocol_params.mote_text_func = 'default_mote_text';
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = initialise(id, start_time)
global all_mote protocol_stat protocol_params sim_params;
% reset to forget parents
forget_parent(id);
% Store number of routing packet sent
protocol_stat.route_sent(id) = 0;

% keep track of the current parent to see if it is expired
all_mote.parent_expired(id) = 0;

% keep track to see if this node has received a broadcast message or not
all_mote.route_count(id) = 0;

% all nodes have invalid parents
all_mote.parent(id) = protocol_params.invalid_parent; 

% all mote's packet seq num are initialized to 0
all_mote.packet_seq_num(id) = 0;

% if this is a base station, 0 hop; otherwise, hop = Inf.
if id == sim_params.base_station
    all_mote.hop(id)= 0;
else
    all_mote.hop(id)= +Inf;
end

% neighborhood table to store seq num to avoid duplicated packets
protocol_params.neighbor_list(id).nodeID = [];
protocol_params.neighbor_list(id).packet_seq_num = [];

% schedule clock tick
ws('insert_event', 'broadcast', 'clock_tick', start_time, id, {});
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_func, id, all_mote.X(id), all_mote.Y(id));, end
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ['Mote ' num2str(id)]);, end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is same as initialise but this is only called once for all mote. it is called after
% each node is initialise.
function void = global_initialise
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clock tick function
% only the base station broadcast the routing packet
function void = clock_tick(id)
global all_mote sim_params protocol_params app_params protocol_stat;

% For base station, we periodically send routing packet
if id == sim_params.base_station
    % Send routing packet
    packet = broadcast_routing_packet(id, 0, protocol_params.route_packet_length);
    feval(sim_params.protocol_send, 'send_packet', id, packet);
end
interval = protocol_params.route_clock_interval;
ws('insert_event', 'broadcast', 'clock_tick', interval, id, {});
forget_parent(id);
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% give the upper layer a way to send packet
function void = send_packet(id, packet)
global sim_params all_mote;
packet.packet_seq_num = all_mote.packet_seq_num(id);
feval(sim_params.protocol_send, 'send_packet', id, packet);
all_mote.packet_seq_num(id) = all_mote.packet_seq_num(id) + 1;
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% when done, radio will called this function
% we signal the upper layer if it is not routing packet
function void = send_packet_done(id, packet, num_retrans, result)
global sim_params protocol_params protocol_stat;
if packet.type ~= protocol_params.route_packet_type
    feval(sim_params.application, 'send_packet_done', id, packet, num_retrans, result);
else
    protocol_stat.route_sent(id) = protocol_stat.route_sent(id) + 1;
end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% when sucucessfulyl receive, radio will call this function
% we signal the upper layer if it is not routing packet, otherwise we called 
% receive_routing packet to process the routing packet
function void = receive_packet(id, receive_packet)
global sim_params protocol_params all_mote;

old_packet=0;
if receive_packet.type ~= protocol_params.route_packet_type
    old_packet = process_data_packet(id, receive_packet);
    if old_packet == 0
        feval(sim_params.application, 'receive_packet', id, receive_packet);
    end
else
    % COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ['Mote ' num2str(id) ' r ' num2str(receive_packet.source)]);, end
    receive_routing_packet(id, receive_packet);    
end
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function broadcast_packet = broadcast_routing_packet(source, hop, length)
global protocol_params radio_params;
broadcast_packet.source = source;
broadcast_packet.hop = hop;
broadcast_packet.type = protocol_params.route_packet_type;
broadcast_packet.length = length;
broadcast_packet.parent = radio_params.broadcast_addr;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function old_packet = process_data_packet(id, receive_packet)    
global protocol_params;
old_packet = 0;
if isempty(protocol_params.neighbor_list(id).nodeID)
    return;
end
index = find(protocol_params.neighbor_list(id).nodeID == receive_packet.source);
if isempty(index)
    protocol_params.neighbor_list(id).nodeID(length(protocol_params.neighbor_list(id).nodeID)+1) = receive_packet.source;
else
    if receive_packet.packet_seq_num <= protocol_params.neighbor_list(id).packet_seq_num(index)
        old_packet=1;
    end
    protocol_params.neighbor_list(id).nodeID(index) = receive_packet.source;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% so what are we going to do when we get a routing packet
% we see if it has a shorter hop, if it does, set that to parent, if it is expire. time to 
% forget the parents, then we set the parent, 
% we relay routing packet only once
function receive_routing_packet(id, receive_packet)
global all_mote sim_params protocol_params protocol_stat
%% if this is base station , return, do nothing
if id == sim_params.base_station
    return;
end

% hop indicated by the receive_packet
current_hop = receive_packet.hop + 1;

% if this is smaller that what i have before than i set this to my parent
if (all_mote.parent_expired(id) | (all_mote.hop(id) > current_hop & id ~= sim_params.base_station))
    all_mote.hop(id)= current_hop;
    all_mote.parent(id) = receive_packet.source;
    all_mote.parent_expired(id) = 0;
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.parent_line_func, id, all_mote.X(id), all_mote.Y(id), all_mote.X(all_mote.parent(id)), all_mote.Y(all_mote.parent(id)));, end
end

% probabilistic broadcasting
prob = protocol_params.retransmit_probability;
if rand < prob & all_mote.route_count(id) == 0
    length = protocol_params.route_packet_length;
    % create a new packet with this Id and this number of hop
    broadcast_packet = broadcast_routing_packet(id, all_mote.hop(id), length);
    feval(sim_params.protocol_send,'send_packet', id, broadcast_packet);
    all_mote.route_count(id) = 1;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function forget_parent(id)
global all_mote
% ws('db', ['Mote ' num2str(id) ' forget its parent']);
all_mote.route_count(id) = 0;
all_mote.parent_expired(id) = 1;


