%									tab:4
%
%
% "Copyright (c) 2000-2002 The Regents of the University  of California.  
% All rights reserved.
%
% Permission to use, copy, modify, and distribute this software and its
% documentation for any purpose, without fee, and without written agreement is
% hereby granted, provided that the above copyright notice, the following
% two paragraphs and the author appear in all copies of this software.
% 
% IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
% DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
% OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
% CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
% INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
% AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
% ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
% PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
%
%
%									tab:4
%  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
%  downloading, copying, installing or using the software you agree to
%  this license.  If you do not agree to this license, do not download,
%  install, copy or use the software.
%
%  Intel Open Source License 
%
%  Copyright (c) 2002 Intel Corporation 
%  All rights reserved. 
%  Redistribution and use in source and binary forms, with or without
%  modification, are permitted provided that the following conditions are
%  met:
% 
%	Redistributions of source code must retain the above copyright
%  notice, this list of conditions and the following disclaimer.
%	Redistributions in binary form must reproduce the above copyright
%  notice, this list of conditions and the following disclaimer in the
%  documentation and/or other materials provided with the distribution.
%      Neither the name of the Intel Corporation nor the names of its
%  contributors may be used to endorse or promote products derived from
%  this software without specific prior written permission.
%  
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
%  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
%  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
%  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
%  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
%  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
%  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
%  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
%  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
%  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
%  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
%  Authors:  Alec Woo, Terence Tong 
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this file is really the core of this program, rewriting this will almost rewrite the whole thing
% this provide send_packet function for the application layer and it needs to called send_packet_done
% and receive in the application layer somehow
% it is important to make this file as fast as possible, because it is called very very often
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function output = route_prob_radio_ack(varargin)
output = feval(varargin{:});

%%
% Simulation setttings specific to this component
%%
function void = settings
global radio_params;
radio_params.ack_packet_length = 144;      % Assume it's only 6 bytes for ack (src(2), dest(2), ack_type(1), groupID(1))
radio_params.ack_wait_time = 432;          % timeout = 1.5 times the ack transmission time  (1.5) * 144/0.5
radio_params.number_of_retransmission = 3; % number of retransmission to try
void = -1;

%%
% Initialize fields for each of the simulated motes using this component.
% (Note: this is like init for each mote)
% parameters:  id is the mote id
%%
function void = initialise(id)
global all_mote radio_params link_stat ack_list transmit_list;
radio_params.radio_seqNo = 0;
all_mote.radio_packet_queue{id} = [];  % array of struct to model the channel for each mote as a queue
all_mote.radio_disable(id) = 0;        % set this bit to zero will disable the mote's radio
all_mote.link_seqnum(id) = 1;          % starting sequence number of the link seq_num for each mote
transmit_list.parent(id) = -1;         % parent of the outstanding packet to be transmitted
transmit_list.ack_recv(id) = 0;        % ack received for the outstanding packet for each mote

% Statistics capture by this component
link_stat.collided_app_packet(id) = 0;  % number of packets got collided along the way to bs for each node
link_stat.corrupted_app_packet(id) = 0; % number of packets got corrupted along the way to bs for each node
void = -1;

%%
% Initialize fileds for this component.  Note: this is called once after initialise is called
% no matter how many motes you are simulating.
%%
function void = global_initialise
void = -1;

%% 
% Send packet: when upper layer needs to send a packet, it calls this function
% parameters: id is the source, app_packet is the packet
%
%
%%
function void = send_packet(id, app_packet)
global radio_params transmit_list;
if transmit_list.parent(id)== -1
    send_time = ceil(rand * radio_params.schedule_send_time);
    ws('insert_event', 'route_prob_radio_ack', 'check_idle', send_time, id, { app_packet });
    void = -1;
else
    void = 0;
end

%%
% Check_Idle:  implements a model of CSMA simulating the TinyOS MAC layer 
% It checks if it is quiet enough to send, otherwise, it will post an event for itself 
% after a randomized backoff time.
% 
% parameters: id is the source, app_packet is the packet
%%
function void = check_idle(id, app_packet)
global radio_params sim_params;

%if alec_threshold_quiet_function(id)
if feval(sim_params.model, 'quiet_function', id)
    send_packet_helper(id, app_packet);
else
    backoff_time = ceil(rand * radio_params.backoff_time);
    ws('insert_event', 'route_prob_radio_ack', 'check_idle', backoff_time, id, { app_packet });
end
void = -1;


%%
% Send packet done:
%
% parameters:   id is the sender
%               radio_packet is the packet that was sent
%%
function void = send_packet_done(id, radio_packet)
global sim_params protocol_params transmit_list radio_params;

if radio_packet.app_packet.parent == radio_params.broadcast_addr | radio_packet.app_packet.parent == protocol_params.invalid_parent
    result = 1;    
else
    result = transmit_list.ack_recv(id);
end
clean_up_channel(id);
transmit_list.parent(id) = -1;
transmit_list.ack_recv(id) = 0;
feval(sim_params.protocol_send, 'send_packet_done', id, radio_packet.app_packet, result);

void = -1;

%% 
% Receive packet done:  after a mote gets a packet, it determines if it is corrupt
% if it successfully receives the packet, it posts an event to the upper layer
% that the packet is there and sends an ack.
%
% parameters:  id is the id of the receiver, radio_packet is the packet being received.
%
%%
function void = receive_packet_done(id, radio_packet)
global all_mote radio_params sim_params protocol_params
packet_queue = all_mote.radio_packet_queue{id};
%corrupt = alec_maxpacket_determine_corrupt(id, radio_packet);
corrupt = feval(sim_params.model, 'determine_corrupt', id, radio_packet);
% the processing time is neccessary because other nodes need to be adjust their packet queue, otherwise mote
% will try to send while others are still receiving...
processing_time = 1;
random_error = rand > radio_params.random_fail_rate;

if ~corrupt & random_error
    % ws('db', ['receive_packet_done: succeed sending packet from ', num2str(app_packet.radio_source) ' to ' num2str(app_packet.radio_dest)]);
    ws('insert_event', sim_params.protocol, 'receive_packet', processing_time, id, { radio_packet.app_packet });
    % Send Acknowledgement Packet only for non-broadcast packets and I have a parent
    if radio_packet.app_packet.parent == id & (all_mote.parent(id) ~= protocol_params.invalid_parent | id == sim_params.base_station)
        ack_packet = create_ack_packet(id, radio_packet.app_packet.source, all_mote.sink_seq_num(id), radio_params.ack_packet_length);
        send_ack(id, ack_packet);
    end
else
    % ws('db', ['receive_packet_done: fail sending packet from ' num2str(app_packet.radio_source) ' to ' num2str(app_packet.radio_dest)]);
end
void = -1;

%%
% Receive_Ack_Done:  check to see if ACK is received or not
%
% parameters: id is the id of the receiver, radio_packet is the ACK.
%%
function void = receive_ack_done(id, radio_packet)
global transmit_list all_mote;
%% Is this ack for me?
if transmit_list.parent(id) ~= -1
    right_ack_source = radio_packet.app_packet.source == transmit_list.parent(id);    
    if radio_packet.app_packet.parent == id & right_ack_source
        %disp([num2str(id) ' got Ack from ' num2str(radio_packet.app_packet.source)]);
        % Update sink_seq_num
        if radio_packet.app_packet.sink_seq_num > all_mote.sink_seq_num(id)
            all_mote.sink_seq_num(id) = radio_packet.app_packet.sink_seq_num;
        end
        transmit_list.ack_recv(id) = 1;
    end
end
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PRIVATE FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%  Create Ack Packet:
%
%  parameters:  source is the mote that sends the ack, 
%               dest is the mote that the ack is destined to
%               length is the length of the ack packet
%%
function ack_packet = create_ack_packet(source, dest, sink_seq_num, length)
ack_packet.source = source;
ack_packet.parent = dest;
ack_packet.sink_seq_num = sink_seq_num;
ack_packet.length = length;

%%
% Send Ack Packet:
%
% parameters: source is the ack sender
%             ack_packet is the ack
%%
function send_ack(source, ack_packet)
global all_mote radio_params sim_params

% if sender is disable, should not be able to send
if all_mote.radio_disable(source), return, end

receive_time = floor(ack_packet.length/radio_params.radio_speed)+10;  % Calculate the reception time of the packet (10 is the processing time)
current_time = ws('current_time');          % Extract current simulation time
radio_packet.app_packet = ack_packet;       % Fill in the ack_packet as the payload of the link packet
radio_packet.source = source;               % Save down the source as a header of the link layer packet
radio_packet.sendtime = current_time;       % Save down the current time as a header of the link layer packet

% Deposit the packet into each mote's queue
for dest = 1:sim_params.total_mote
    %if the receiver's radio is disable, shouldn't get it
    if all_mote.radio_disable(dest), continue; end
    
    probability = get_probability(source, dest);  % Extract the reception probability of this pair

    % save information down to the header of the link packet
    radio_packet.prob = probability;
    radio_packet.dest = dest;
    radio_packet.seqNo = radio_params.radio_seqNo;
    
    % if this is too small, discard the receiver, just a optimization
    if probability < 0.01
        continue;
    elseif source ~= dest
        % Signal Receive Ack Done to the destination
        radio_packet.donetime = current_time + receive_time;
        ws('insert_event', 'route_prob_radio_ack', 'receive_ack_done', receive_time, dest, { radio_packet });
    else
        % Skip, insert nothing back to itself for ack packet
        continue;
    end
    % Send the packet to the channel model
    send_to_channel(dest, radio_packet);
    radio_params.radio_seqNo = radio_params.radio_seqNo + 1;
end


%%
% Send out the packet over our channel model.
% 
% We put in radio header to the packet (useful to this file only).
% We post send_packet_done and receive_packet done accordingly.
% For each receiver we run our probabilistic model to see if it
% will receive the packet or not, and 
% increase the serial number of the packets appearing at the channel.
%
%%
function send_packet_helper(source, app_packet)
global all_mote radio_params sim_params ack_list transmit_list

% if sender is disable, should not be able to send
if all_mote.radio_disable(source), return, end

%%%%%%%%%%%
% XXXXXXXXXXXXXXXXXXXXXX
% app_seqnum is the number of packets you send. 
% application need this sequence number to keep track of things
%
app_packet.link_seqnum = all_mote.link_seqnum(source);
all_mote.link_seqnum(source) = all_mote.link_seqnum(source) + 1;


packet_length = app_packet.length;      % Extract the packet length from the packet
current_time = ws('current_time');      % Extract current simulation time
send_time = floor(packet_length/radio_params.radio_speed);   % Calculate the transmission time of the packet
receive_time = floor(packet_length/radio_params.radio_speed) + 10;  % Calculate the reception time of the packet (10 is the processing time)
radio_packet.app_packet = app_packet;   % Add in the payload to the link layer packet
radio_packet.source = source;           % Save down the source as a header of the link layer packet
radio_packet.sendtime = current_time;   % Save down the current time to the header
transmit_list.parent(source) = app_packet.parent;   % sniff the destination field of the outgoing packet
transmit_list.ack_recv(source) = 0;                 % clear the ack field



% Deposit the packet into each mote's queue
for dest = 1:sim_params.total_mote
    % if it is diable, should not get it!
    if all_mote.radio_disable(dest), continue;, end
    
    probability = get_probability(source, dest);  % Extract the reception probability for this pair

    % save it down to the info to the header of the link layer packet
    radio_packet.prob = probability;
    radio_packet.dest = dest;
    radio_packet.seqNo = radio_params.radio_seqNo;
    
    % if probability is too small, discard this destination, just for optimization
    if probability < 0.01
        continue;
    elseif source == dest
        % Invoke a send done event to the source
        radio_packet.donetime = current_time + send_time;
        ws('insert_event', 'route_prob_radio_ack', 'send_packet_done', send_time + radio_params.ack_wait_time, source, { radio_packet });            
    else
        % Invoke a receive done event to the receiver
        radio_packet.donetime = current_time + receive_time;
        ws('insert_event', 'route_prob_radio_ack', 'receive_packet_done', receive_time, dest, { radio_packet });
    end
    % Send the packet to the channel model
    send_to_channel(dest, radio_packet);
    radio_params.radio_seqNo = radio_params.radio_seqNo + 1;
end


%%
% Helpler function to get the probability of reception from source to dest
%
%%
function prob = get_probability(source, dest)
global radio_params
prob = radio_params.prob_table(source, dest);


%%
% Send to channel just deposits the packet to the channel packet queue
%
% parameters:   dest is the receiver
%               radio_packet is the packet
%%
function send_to_channel(dest, radio_packet)
global all_mote
packet_queue = all_mote.radio_packet_queue{dest};
if isempty(packet_queue)
    packet_queue = [radio_packet];
else
    packet_queue(length(packet_queue) + 1) = radio_packet;
end
all_mote.radio_packet_queue{dest} = packet_queue; 


%%
% Clean up the channel queue.
% If the queue has packets that are stale in time, we discard them.
% parameters:  id is the id of the mote
%%
function clean_up_channel(id);
global all_mote;
packet_queue = all_mote.radio_packet_queue{id};
if isempty(packet_queue), return;, end
current_time = ws('current_time');
still_useful_packets_index = find([packet_queue.donetime] >= current_time);
all_mote.radio_packet_queue{id} = packet_queue(still_useful_packets_index);

