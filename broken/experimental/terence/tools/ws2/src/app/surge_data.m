function output = surge_data(varargin)
output = feval(varargin{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PUBLIC FUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = settings
global app_params;
app_params.data_packet_type = 2;
app_params.data_clock_interval = 0.5 *100000;
app_params.packet_length = 666; % In bits
app_params.phase_shift_window = 1*100000; % 1 sec
void = -1;

% intialise everything you have, don't forget to insert a clock event
function void = initialise(id, start_time)
global mote_stat bs_stat app_params sim_params phase_shift
mote_stat.data_sent(id) = 0;   % all data packet sent
mote_stat.app_seqnum(id) = 0; % application sequence number
mote_stat.drop_cycle_packet(id) = 0; % number of packets dropped because of cycles
bs_stat.data_received = zeros(1, sim_params.total_mote);
phase_shift(id) = 0;
ws('insert_event', 'surge_data', 'clock_tick', start_time, id, {});
void = -1;

function void = global_initialise(id)
global app_params
%app_params.packet_length = 36;
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we just periodically send data packets
% Clock tick function
function void = clock_tick(id)
global all_mote sim_params protocol_params app_params phase_shift;

void = -1;

% If there is a route, then send a data packet or its a base station
if id == sim_params.base_station | all_mote.parent(id) ~= protocol_params.invalid_parent
    packet = send_data_packet(id, id, all_mote.parent(id), all_mote.hop(id), app_params.packet_length);
    feval(sim_params.protocol, 'send_packet', id, packet);
end

interval = app_params.data_clock_interval;
ws('insert_event', 'surge_data', 'clock_tick', interval + phase_shift(id), id, {});
if (phase_shift(id) ~= 0)
    phase_shift(id) = 0;
end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% protocol layer is going to called this after it is done, we don't do anything
% otherthen collect statistics
function void = send_packet_done(id, packet, num_retrans, result)
global mote_stat sim_params app_params protocol_params all_mote phase_shift;
if packet.type == app_params.data_packet_type
    mote_stat.data_sent(id) = mote_stat.data_sent(id) + 1;
    if packet.data_source == id
        mote_stat.app_seqnum(id) = mote_stat.app_seqnum(id) + 1;
    end
    if ((result == 0 | num_retrans > 0) & packet.data_source == id)  % Send Failure
        phase_shift(id) = floor(rand * app_params.phase_shift_window);
        %disp([num2str(id) ' phase shfits']);
    end
end
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% protocol layer is going to called this after it is done, we don't do anything
% otherthen collect statistics, except the fact that the mote will send data packet
% if the parent is this mote
function void = receive_packet(id, receive_packet)
global sim_params protocol_params all_mote bs_stat mote_stat;

right_parent = (receive_packet.parent == id);
valid_parent = (all_mote.parent(id) ~= protocol_params.invalid_parent);
not_bs = (id ~= sim_params.base_station);
cycle = (id == receive_packet.data_source) & (receive_packet.parent == id);

if cycle
    mote_stat.drop_cycle_packet(receive_packet.data_source) = mote_stat.drop_cycle_packet(receive_packet.data_source) + 1;
end

if right_parent & valid_parent & not_bs & ~cycle
    receive_packet.source = id;
    receive_packet.parent = all_mote.parent(id);
    feval(sim_params.protocol, 'send_packet', id, receive_packet);    
end

if id == sim_params.base_station & receive_packet.parent == id
    bs_stat.data_received(receive_packet.data_source) = bs_stat.data_received(receive_packet.data_source) + 1;
end

void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PRIVATE FUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data_packet = send_data_packet(data_source, source, parent, hop, length)
global app_params
data_packet.data_source = data_source;
data_packet.source = source;
data_packet.parent = parent;
data_packet.hop = hop;
data_packet.type = app_params.data_packet_type;
data_packet.length = length;
