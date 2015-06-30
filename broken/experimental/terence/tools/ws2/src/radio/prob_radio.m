function output = prob_radio(varargin)
output = feval(varargin{:});

% this file is really the core of this program, rewriting this will almost rewrite the whole thing
% this provide send_packet function for the application layer and it needs to called send_packet_done
% and receive in the application layer somehow
% it is important to make this file as fast as possible, because it is called very very often

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PUBLIC FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is called to initialise this generic layer
% put all your stuff in this structure. args for this function is empty
function void = settings
global radio_params
radio_params.ack_packet_length = 144;  % Assume it's only 6 bytes for ack (src(2), dest(2), ack_type(1), groupID(1))
radio_params.ack_wait_time = 432;  % 1.5 times the ack transmission time  (1.5) * 144/0.5
radio_params.number_of_retransmission = 3;
void = -1;

function void = initialise(id)
global all_mote radio_params link_stat;
radio_params.radio_seqNo = 0;
all_mote.radio_packet_queue{id} = []; % array of struct
all_mote.radio_disable(id) = 0;
all_mote.link_seqnum(id) = 1;
radio_params.collision_count = 0;
radio_params.corrupt_count = 0;
link_stat.collided_app_packet(id) = 0;
link_stat.corrupted_app_packet(id) = 0;
link_stat.num_retransmit(id) = 0;
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is called once after initialise is called
function void = global_initialise(id)
global radio_params
% generate the distance matrix and probability matrix
generate_dist_matrix;
if radio_params.prob_predefined
    read_prob_matrix;
else
    generate_prob_matrix;
end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% when an application need to send something, it called this function
% it try to randomize the send time
function void = send_packet(id, app_packet)
global all_mote radio_params
send_time = ceil(rand * radio_params.schedule_send_time);
ws('insert_event', 'prob_radio', 'check_idle', send_time, id, { app_packet });
void = -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% so send packet will post a check idle event, it will check if it is quiet enought to 
% send, otherwise, it will post send packet event after certain backoff time.
function void = check_idle(id, app_packet)
global radio_params
if alec_threshold_quiet_function(id)
    % ws('db', ['mote ' num2str(id) ' is quiet enough to send packet. now sending... ']);
    send_packet_helper(id, app_packet);
else
    % ws('db', ['mote ' num2str(id) ' backoff']);
    backoff_time = ceil(rand * radio_params.backoff_time);
    ws('insert_event', 'prob_radio', 'send_packet', backoff_time, id, { app_packet });
end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = send_packet_done(id, radio_packet)
global all_mote sim_params
clean_up_channel(id);
feval(sim_params.protocol, 'send_packet_done', id, radio_packet.app_packet, 1);
void = -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% after we get a packet, we determine if it is corrupt
% if we successfully receive the packet, we post a event to the applicaton layer
% that the packet is there
function void = receive_packet_done(id, radio_packet)
global all_mote radio_params sim_params
packet_queue = all_mote.radio_packet_queue{id};
corrupt = alec_maxpacket_determine_corrupt(id, radio_packet);
% the processing time is neccessary because other nodes need to be adjust their packet queue, otherwise mote
% will try to send while others are still receiving...
processing_time = 1;
random_error = rand > radio_params.random_fail_rate;

if ~corrupt & random_error
    % ws('db', ['receive_packet_done: succeed sending packet from ', num2str(app_packet.radio_source) ' to ' num2str(app_packet.radio_dest)]);
    ws('insert_event', sim_params.protocol, 'receive_packet', processing_time, id, { radio_packet.app_packet });
else
    % ws('db', ['receive_packet_done: fail sending packet from ' num2str(app_packet.radio_source) ' to ' num2str(app_packet.radio_dest)]);
end

void = -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PRIVATE FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% really send the packet
% we put in a lot of radio header to the packet (usefuly to this file only)
% we post send_packet_done and receive_packet done accordingly
% then we corrupt the channel, increase the serial number
function send_packet_helper(source, app_packet)
global all_mote radio_params sim_params
% if sender is disable, should not be able to send
if all_mote.radio_disable(source), return, end
packet_length = app_packet.length;
current_time = ws('current_time');
send_time = packet_length/radio_params.radio_speed;%radio_params.send_time;
receive_time = packet_length/radio_params.radio_speed + 10; %radio_params.receive_time;
% app_seqnum is the number of packets you send. application need this sequence number to keep track of things
app_packet.link_seqnum = all_mote.link_seqnum(source);
all_mote.link_seqnum(source) = all_mote.link_seqnum(source) + 1;
radio_packet.app_packet = app_packet;
for dest = 1:sim_params.total_mote
    % if it is diable, should not get it!
    if all_mote.radio_disable(dest), continue;, end
    probability = get_probability(source, dest);
    % save it down to the packet
    radio_packet.prob = probability;
    radio_packet.source = source;
    radio_packet.dest = dest;
    radio_packet.seqNo = radio_params.radio_seqNo;
    radio_packet.sendtime = current_time;
    % if this is too small, discard, just a optimization
    if probability < 0.01
        continue;
    elseif source == dest
        radio_packet.donetime = current_time + send_time;
        ws('insert_event', 'prob_radio', 'send_packet_done', send_time, source, { radio_packet });
    else
        radio_packet.donetime = current_time + receive_time;
        ws('insert_event', 'prob_radio', 'receive_packet_done', receive_time, dest, { radio_packet });
    end
    corrupt_channel(dest, radio_packet);
    radio_params.radio_seqNo = radio_params.radio_seqNo + 1;
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we check the current channel if there is any packet that has a probilibyt that higher than 0.2
function bool = alec_threshold_quiet_function(id)
global all_mote
radio_packet_queue = all_mote.radio_packet_queue{id};
if isempty(radio_packet_queue), bool = 1; return;, end
current_packets = filter_queue(radio_packet_queue);
if isempty(current_packets) bool = 1; return;, end
% if any of them have a noise level of bigger than 0.2 then it isnoisy (0)
loud_packets_index = find([current_packets.prob] > 0.2);
bool = isempty(loud_packets_index);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if this is not the packet that has the hgihest cahnce, discard
% otherwise, maxpacket * product (from 2 to 5) of (1 - probability of receiving packet i) = probabilyt of success
% throw a dice and determine fate
function corrupt = alec_maxpacket_determine_corrupt(dest, radio_packet)
global all_mote radio_params link_stat app_params
packet_queue = all_mote.radio_packet_queue{dest};
current_packets = filter_queue(packet_queue);
% sort it in ascentding order
radio_probs = sort([current_packets.prob]);
radio_probs_length = length(radio_probs);
highest_prob = radio_probs(radio_probs_length);
is_to_parent_data_packet = (dest == radio_packet.app_packet.parent) & (radio_packet.app_packet.type == app_params.data_packet_type);

if radio_packet.prob < highest_prob
    radio_params.collision_count = radio_params.collision_count + 1;
    corrupt = 1;
    if is_to_parent_data_packet
        link_stat.collided_app_packet(radio_packet.app_packet.data_source) = link_stat.collided_app_packet(radio_packet.app_packet.data_source) + 1;
    end
    return;
end
%% if it is, calulate prob and throw dice on that prob
four_probs = [0];
if radio_probs_length ~= 1, 
    four_probs = radio_probs(max(1, (radio_probs_length - 5)):(radio_probs_length - 1));
end
success_prob = highest_prob * prod(1 - four_probs);
corrupt = (rand > success_prob);
if corrupt
    radio_params.corrupt_count = radio_params.corrupt_count + 1;
    if is_to_parent_data_packet
        if radio_probs_length > 1
            link_stat.collided_app_packet(radio_packet.app_packet.data_source) = link_stat.collided_app_packet(radio_packet.app_packet.data_source) + 1;
        else
            link_stat.corrupted_app_packet(radio_packet.app_packet.data_source) = link_stat.corrupted_app_packet(radio_packet.app_packet.data_source) + 1;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function current_packets = filter_queue(radio_packet_queue)
% radio packet queue is an array of struct
current_time = ws('current_time');

current_index = find([ radio_packet_queue.sendtime ] <= current_time & current_time <= [ radio_packet_queue.donetime ]);
current_packets = radio_packet_queue(current_index);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dist = get_distance(source, dest)
global radio_params
dist = radio_params.dist_matrix(source, dest);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the following is some functions to create a distance and probability matrix
function void = generate_dist_matrix
global radio_params all_mote
[x1, x2] = meshgrid(all_mote.X);
diffX = abs(x1 - x2);
[y1, y2] = meshgrid(all_mote.Y);
diffY = abs(y1 - y2);
radio_params.dist_matrix = sqrt(diffX.^2 + diffY.^2);
void = -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function prob = get_probability(source, dest)
global radio_params
prob = radio_params.prob_table(source, dest);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = generate_prob_matrix
global radio_params sim_params radio_params
stat_table = fileread('statPower50.dat', 4, 31);
for source = 1:sim_params.total_mote
    for dest = 1:sim_params.total_mote
        dist = get_distance(source, dest);
        dist = ceil(dist / 2) * 2; % round up
        dist = min(dist, 62); % make sure it does not go above 62
        dist = max(dist, 2); % below 2
        % What's the mean and variance? 
        stat_data = stat_table(find(stat_table(:, 1) == dist), :); 
        prob = random('norm', stat_data(1, 2), stat_data(1, 3), 1, 1); 
        prob = max(0, prob);
        prob = min(1, prob);
        radio_params.prob_table(source, dest) = prob;
    end
end
void = -1;

function void = create_prob_matrix
initial_default;
radio_params.prob_predefined = 0;
ws('initial');
save_prob_matrix;
void = -1;

function void = read_prob_matrix
global radio_params sim_params
radio_params.prob_table = fileread(radio_params.prob_predefined_file, sim_params.total_mote, sim_params.total_mote);
% radio_params.prob_table = dlmread(radio_params.prob_predefined_file, ' ');
void = -1;

function void = save_prob_matrix
global radio_params
dlmwrite(radio_params.prob_predefined_file, radio_params.prob_table, ' ');
void = -1;

function matrix = fileread(filename, width, height)
fid = fopen(filename);
column = fscanf(fid, '%f', [1 Inf]);
matrix = reshape(column, width, height)';
fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% just deposit to the packet queue
function corrupt_channel(dest, radio_packet)
global all_mote
packet_queue = all_mote.radio_packet_queue{dest};
if isempty(packet_queue)
    packet_queue = [radio_packet];
else
    packet_queue(length(packet_queue) + 1) = radio_packet;
end
all_mote.radio_packet_queue{dest} = packet_queue; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean up the queue. if the stuff is too old, we discard it
function clean_up_channel(id);
global all_mote
packet_queue = all_mote.radio_packet_queue{id};
if isempty(packet_queue), return;, end
current_time = ws('current_time');
still_useful_packets_index = find([packet_queue.donetime] >= current_time);
all_mote.radio_packet_queue{id} = packet_queue(still_useful_packets_index);

