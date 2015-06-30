function output=dsr_broadcast(varargin)
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
% Define the packet length
protocol_params.route_packet_length =  666; % In bits
% Define GUI options
protocol_params.mote_func = 'square_mote_withno_menu';
protocol_params.parent_line_func = 'parent_line_withno_menu';
protocol_params.mote_text_func = 'default_mote_text';

% Return value
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = initialise(id, start_time)
global all_mote protocol_stat protocol_params sim_params route_stat;
% Set parent to invalid
forget_parent(id);

% Record number of "routing" packets sent so far
% Initialize it to 0
protocol_stat.route_sent(id) = 0;

% Variable to keep track of the current parent to see if it is gone
% Initialize it to 0
all_mote.parent_expired(id) = 0;

% Flag to make sure at most once broadcast
all_mote.route_count(id) = 0;

% Initialize parent to be invalid
all_mote.parent(id) = protocol_params.invalid_parent; 

% Variable to avoid forwarding duplicated packet
all_mote.packet_seq_num(id) = 0;

% For link failure detection. Used to count number of retransmissions. 
route_stat.cur_num_retrans(id) = 0;

% Initialize hop count of each node.
if id == sim_params.base_station
    all_mote.hop(id)= 0;
else
    all_mote.hop(id)= +Inf;
end

% Start the clock event
ws('insert_event', 'dsr_broadcast', 'clock_tick', start_time, id, {});
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
function void = clock_tick(id)
global all_mote sim_params protocol_params app_params protocol_stat;

% For each clock tick, if parent is invalid, broadcast a request
% If parent is valid, do nothing.
% Since base-station has a route, it doesn't need to do any broadcast.

if id ~= sim_params.base_station & all_mote.parent(id) == protocol_params.invalid_parent
    % Send routing packet
    packet = dsr_broadcast_routing_packet(id, 0, protocol_params.route_packet_length);
    feval(sim_params.protocol_send, 'send_packet', id, packet);
end

% Insert the next clock tick event
interval = protocol_params.route_clock_interval;
ws('insert_event', 'dsr_broadcast', 'clock_tick', interval, id, {});

void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% give the upper layer a way to send packet
function void = send_packet(id, packet)
global sim_params;
% Insert packet_seq_num to avoid duplicated packet retransmission
packet.packet_seq_num = all_mote.packet_seq_num(id);
all_mote.packet_seq_num(id) = all_mote.packet_seq_num(id) + 1;

% Send the packet
feval(sim_params.protocol_send, 'send_packet', id, packet);
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% when done, radio will called this function
% we signal the upper layer if it is not routing packet
function void = send_packet_done(id, packet, num_retrans, result)
global sim_params protocol_params protocol_stat route_stat;

if packet.type ~= protocol_params.route_packet_type
    %  Need to check if there is link failure.
    if (all_mote.parent(id) ~= protocol_params.invalid_parent)
        route_stat.cur_num_retrans(id) = route_stat.cur_num_retrans(id) + num_retrans;
        if (route_stat.cur_num_retrans(id) > protocol_params.link_failure_retrans)
            % determine that this is link failure
            route_selection(id, 'link');
        end
    end
    if (num_retrans < protocol_params.number_of_retransmission)
        route_stat.cur_num_retrans(id)=0;    
    end
    feval(sim_params.application, 'send_packet_done', id, packet, result);
else
    % Only keep statistics.  Don't need to perform anything special.
    protocol_stat.route_sent(id) = protocol_stat.route_sent(id) + 1;
end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% when sucucessfulyl receive, radio will call this function
% we signal the upper layer if it is not routing packet, otherwise we called 
% receive_routing packet to process the routing packet
function void = receive_packet(id, receive_packet)
global sim_params protocol_params all_mote;

if receive_packet.type ~= protocol_params.route_packet_type
    % Signal packet reception to application if it is not a duplicated packet
    ret=isDuplicatedPacket(id, receive_packet);
    if ret ~= 0
        regsiterPacket(id, receive_packet);
        feval(sim_params.application, 'receive_packet', id, receive_packet);
    end
else
    % COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ['Mote ' num2str(id) ' r ' num2str(receive_packet.source)]);, end

    % Receive a routing packet.  Handle it!
    receive_routing_packet(id, receive_packet);    
end
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prepare a routing specific packet to be sent out
function dsr_broadcast_packet = dsr_broadcast_routing_packet(source, hop, length)
global protocol_params radio_params;
dsr_broadcast_packet.source = source;
dsr_broadcast_packet.hop = hop;
dsr_broadcast_packet.type = protocol_params.route_packet_type;
dsr_broadcast_packet.length = length;
dsr_broadcast_packet.parent = radio_params.broadcast_addr;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% so what are we going to do when we get a routing packet
% we see if it has a shorter hop, if it does, set that to parent, if it is expire. time to 
% forget the parents, then we set the parent, 
% we relay routing packet only once
function receive_routing_packet(id, receive_packet)
global all_mote sim_params protocol_params protocol_stat

% if I have a route, reply with a broadcast.
% Local broadcast storm problem?

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
    dsr_broadcast_packet = dsr_broadcast_routing_packet(id, all_mote.hop(id), length);
    feval(sim_params.protocol_send,'send_packet', id, dsr_broadcast_packet);
    all_mote.route_count(id) = 1;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function forget_parent(id)
global all_mote
% Parent is gone. Keep the same parent but open for parent relearning.
all_mote.route_count(id) = 0;
all_mote.parent_expired(id) = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret=isDuplicatedPacket(id, packet)
global protocol_params;

% Find the index to the array which stores the children and its last packet seq number heard
index = find(protocol_params.neighbor_list(id).nodeID == packet.source);
if isempty(index)
    ret = 0;
else
    ret = packet.packet_seq_num <= protocol_params.neighbor_list(id).packet_seq_num(index);
end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function registerPacket(id, packet)
global protocol_params;

% Find the index to the array which stores the children and its last packet seq number heard
index = find(protocol_params.neighbor_list(id).nodeID == packet.source);
if isempty(index)
    % the children is new
    protocol_params.neighbor_list(id).nodeID = [protocol_params.neighbor_list(id).nodeID packet.source];
    protocol_params.neighbor_list(id).packet_seq_num = [protocol_params.neighbor_list(id).packet_seq_num packet.packet_seq_num];    
else
    % the children is already in the list    
    protocol_params.neighbor_list(id).packet_seq_num(index) = packet.packet_seq_num;    
end
