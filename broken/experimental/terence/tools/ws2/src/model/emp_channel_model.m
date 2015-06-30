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
function output=emp_channel_model(varargin)
output = feval(varargin{:});


%%
% Simulation setttings specific to this component
%%
function void = settings
global emp_data_file_name
emp_data_file_name = 'statPower50.dat';
void = -1;


%%
% Initialize fields for each of the simulated motes using this component.
% (Note: this is like init for each mote)
% parameters:  id is the mote id
%%
function void = initialise(id)
void = -1;

%%
% Initialize fileds for this component.  Note: this is called once after initialise is called
% no matter how many motes you are simulating.
%%
function void = global_initialise
global radio_params
% generate probability matrix
if radio_params.prob_predefined
    read_prob_matrix;
else
    generate_prob_matrix;
end
void = -1;

%%
% Generate the adjacency matrix according to the topology.
% The resulting adjacency matrix is stored in radio_params.prob_table.
%
%%
function void = generate_prob_matrix
global radio_params sim_params radio_params emp_data_file_name
stat_table = fileread(emp_data_file_name, 4, 31);
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



%%
%  Quiet function:  this function implements the CSMA mechanism using the probabilistic model.
%
%  We check the current channel if there is any packet that has a probability that is higher than 0.2
%  to decide if the channel is idle or not.
%%
function bool = quiet_function(id)
global all_mote
radio_packet_queue = all_mote.radio_packet_queue{id};
if isempty(radio_packet_queue), bool = 1; return;, end
current_packets = filter_queue(radio_packet_queue);
if isempty(current_packets) bool = 1; return;, end
% if any of them have a noise level of bigger than 0.2 then it isnoisy (0)
loud_packets_index = find([current_packets.prob] > 0.2);
bool = isempty(loud_packets_index);


%%
% Determine corrupt:  
% sender is the source of the packet that has the highest chance of success in reciving.
% colliders are all other senders that are colliding with the sender's packet.
%
% If there is only sender, packet loss is due only to probability of reception.
%
% If there are colliders, all collider's packets deem corrupted.  The probability of 
% whether the sender's packet can be receved is calculated as follow:
% (sender's packet reception probability) * [product_series (i = top four colliders){(1 - probability of receiving packet from i)}]
%   
% We throw a dice against this resulting probability to determine fate of the packet.
%
%%
function corrupt = determine_corrupt(dest, radio_packet)
global all_mote radio_params link_stat app_params
packet_queue = all_mote.radio_packet_queue{dest};
current_packets = filter_queue(packet_queue);
% sort it in ascentding order
radio_probs = sort([current_packets.prob]);
radio_probs_length = length(radio_probs);
highest_prob = radio_probs(radio_probs_length);
is_to_parent_data_packet = (dest == radio_packet.app_packet.parent) & (radio_packet.app_packet.type == app_params.data_packet_type);

if radio_packet.prob < highest_prob
    %radio_params.collision_count = radio_params.collision_count + 1;
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
    %radio_params.corrupt_count = radio_params.corrupt_count + 1;
    if is_to_parent_data_packet
        if radio_probs_length > 1
            link_stat.collided_app_packet(radio_packet.app_packet.data_source) = link_stat.collided_app_packet(radio_packet.app_packet.data_source) + 1;
        else
            link_stat.corrupted_app_packet(radio_packet.app_packet.data_source) = link_stat.corrupted_app_packet(radio_packet.app_packet.data_source) + 1;
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the following are some functions to create a distance and probability matrix

%%
% Filter Queue:
% find the current packets on the channel in the queue.
%
% parameters:  radio_packet_queue contains the receiver's packet queue of all packets occuring 
%              in the channel.
%%
function current_packets = filter_queue(radio_packet_queue)
% radio packet queue is an array of struct
current_time = ws('current_time');

current_index = find([ radio_packet_queue.sendtime ] <= current_time & current_time <= [ radio_packet_queue.donetime ]);
current_packets = radio_packet_queue(current_index);


%%
% Helper function to get the distance between source and destination
%
function dist = get_distance(source, dest)
global radio_params
dist = radio_params.dist_matrix(source, dest);



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
