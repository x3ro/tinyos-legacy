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

function output=shortest_path_route_stack(varargin)
output = feval(varargin{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Public Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ******************* SETTINGS ***********************
% This function defines various settings of this protocol
%
function void = settings
global protocol_params;
protocol_params.list_time_out = 2;            % This specifies timeout of a neighboring node
protocol_params.route_packet_length =  666;   % Packet length in bits
protocol_params.phase_shift_window = 100000;  %  1sec phase shift random window to avoid correlated collision
protocol_params.track_info_window = 120;      % XXXXXXXXX Wrong place:  this should be estimator
protocol_params.neighbor_sel_threshold = 6;   % Set to be 6 retransmission
protocol_params.min_samples = 8;              % Minimum samples to trust an estimation
protocol_params.num_neighbor_to_feedback = 200; % specify the number of neighbors to feedback
protocol_params.warmup_time = 200*100000;       % Warm up time to speed up route broadcasts
protocol_params.route_speed_up = 5;             % Speed up the route updates
protocol_params.estimator = 'moving_ave';       % Use moving average as the estimator

%% GUI settings
protocol_params.mote_func = 'square_mote_withno_menu';
protocol_params.parent_line_func = 'parent_line_with_menu';
protocol_params.mote_text_func = 'default_mote_text';

void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is called to initialise this applicaton
function void = initialise(id, start_time)
global all_mote protocol_stat protocol_params sim_params route_phase_shift;

% initialize all motes to have invalid addresses
all_mote.parent(id) = protocol_params.invalid_parent; 

% Sequence number to 0
all_mote.packet_seq_num(id) = 0;

% Initialize the neighborhood table
protocol_params.neighbor_list(id).nodeID = [];
protocol_params.neighbor_list(id).in_est = [];
protocol_params.neighbor_list(id).out_est = [];
protocol_params.neighbor_list(id).track_info = [];
protocol_params.neighbor_list(id).hop = [];
protocol_params.neighbor_list(id).route_parent = [];
protocol_params.neighbor_list(id).packet_seq_num = [];
protocol_params.neighbor_list(id).time_out = [];
%% TERENCE: add in child field
protocol_params.neighbor_list(id).child = [];

% If this is the base station, hop is 0.
if id == sim_params.base_station
    all_mote.hop(id)= 0;
else
    % otherwise, initialize to Inf
    all_mote.hop(id)= +Inf;
end

% Reset route phase shift
route_phase_shift(id) = 0;

% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_func, id, all_mote.X(id), all_mote.Y(id));, end
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ['Mote ' num2str(id)]);, end

% Schedule the clock event
ws('insert_event', sim_params.protocol, 'clock_tick', start_time, id, {});
void = -1;

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

% Send the route broadcast message.
% Include: ID, HOP, ENTIRE_NEIGHBORHOOD_TABLE
packet = shortestpath_routing_packet(id, all_mote.hop(id), protocol_params.neighbor_list(id), protocol_params.route_packet_length);

% Send the next packet
feval(sim_params.protocol_send, 'send_packet', id, packet);

% Compute the next clock interval including possible phase shift
interval = protocol_params.route_clock_interval + route_phase_shift(id);

% Warm up phase
if sim_params.simulation_time <= protocol_params.warmup_time
    interval = interval / protocol_params.route_speed_up;
end

% Remove neighbors that may have moved.  
% NOTE:  in the warm up phase, the TIME_OUT threshold has to be tuned
invalid_neighbor_index = find(protocol_params.neighbor_list(id).time_out <= 0);
protocol_params.neighbor_list(id).in_est(invalid_neighbor_index) = 0;
protocol_params.neighbor_list(id).out_est(invalid_neighbor_index) = 0;
for i=1:length(invalid_neighbor_index)
    protocol_params.neighbor_list(id).track_info(invalid_neighbor_index(i)) = ...
    feval(protocol_params.estimator, 'reset_estimation', protocol_params.neighbor_list(id).track_info(invalid_neighbor_index(i)));
end
protocol_params.neighbor_list(id).hop(invalid_neighbor_index) = +Inf;
protocol_params.neighbor_list(id).time_out = protocol_params.neighbor_list(id).time_out - 1;

% TERENCE: reset child field
protocol_params.neighbor_list(id).child(invalid_neighbor_index) = 0;

% Reset the phase_shift flag
route_phase_shift(id) = 0;

% TERENCE: choose parent when clock tick
choose_parent(id);

% Schedule the next clock tick
ws('insert_event', sim_params.protocol, 'clock_tick', interval, id, {});

void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void= send_packet(id, packet)
global sim_params all_mote;
% Just send the packet.
packet.packet_seq_num = all_mote.packet_seq_num(id);
feval(sim_params.protocol_send, 'send_packet', id, packet);
all_mote.packet_seq_num(id) = all_mote.packet_seq_num(id) + 1;
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = send_packet_done(id, packet, num_retrans, result)
global sim_params protocol_params protocol_stat route_phase_shift;
if packet.type ~= protocol_params.route_packet_type
    % If the packet type is application, just propagate the send done to the above
    feval(sim_params.application, 'send_packet_done', id, packet, num_retrans, result);
else
    % Compute ROUTE broadcast phase shift to avoid repeated collisions.
    route_phase_shift(id) = floor(rand * protocol_params.phase_shift_window);
end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = receive_packet(id, receive_packet)
global sim_params protocol_params all_mote

old_packet = 0;

% if the packet is received, 
if receive_packet.type ~= protocol_params.route_packet_type
    % process the packet and check to see if it is a duplicated packet
    old_pacaket = process_data_packet(id, receive_packet);
    if old_packet == 0
        feval(sim_params.application, 'receive_packet', id, receive_packet);
    end
else
    process_routing_packet(id, receive_packet);
end
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ...
% COMPILE %        ['Mote ' num2str(id) ' p ' num2str(all_mote.parent(id))]);, end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function old_packet=process_data_packet(id, receive_packet)
global protocol_params all_mote

old_packet = 0;
[new, index] = find_neighbor_index(receive_packet.source, protocol_params.neighbor_list(id));

% TERENCE: add in child field
% the parent of this packet is me, it is valid
right_parent = (receive_packet.parent == id);
valid_parent = (all_mote.parent(id) ~= protocol_params.invalid_parent);

%
%  ALec:  Not sure whether you need to feedback by sending more messages???
%  Well base station can send more route update messages!
child = (right_parent & valid_parent);

if new
    %id, index, nodeID, hop, route_parent, packet_seq_num, in_est, out_est, track_info, child
    save_neighbor_list(id, index, receive_packet.source, +Inf, receive_packet.parent, ... % hop
        receive_packet.packet_seq_num, 0, 0, ...
        feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, []), child); 
else
    % is this an old packet?
    if receive_packet.packet_seq_num <= protocol_params.neighbor_list(id).packet_seq_num(index)
        old_packet=1;
    end
    
    % keep track of link estimation
    if isempty(protocol_params.neighbor_list(id).track_info)
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, []); 
    else
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index));
    end

    % store the neighbors
    save_neighbor_list(id, index, receive_packet.source, protocol_params.no_save, receive_packet.parent, receive_packet.packet_seq_num, ...
        protocol_params.no_save, feval(protocol_params.estimator, 'calculate_est', track_info), ... %calculate_est(track_info), ... % out_est
        track_info, child); % track_info
end

% TERENCE: add link evaluation
function value = calculate_link_cost(cost, in_est, out_est)
global protocol_params;
trans_est = in_est * out_est;
value = cost + 1 / trans_est;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = choose_parent(id)
global all_mote sim_params protocol_params;
void = -1;
if id == sim_params.base_station, return;, end
%% for all the neighbors, kill those whose parent is me
current_min_hop = Inf;
current_min_link_cost = Inf;
best_index = -1;
neighbor_size = length(protocol_params.neighbor_list(id).nodeID);
if neighbor_size == 0, return;, end
for index = 1:neighbor_size
    nodeID = protocol_params.neighbor_list(id).nodeID(index);
    if (nodeID ~= sim_params.base_station & protocol_params.neighbor_list(id).route_parent(index) == protocol_params.invalid_parent), continue;, end
    if protocol_params.neighbor_list(id).in_est(index) < 0.1, continue;, end
    if protocol_params.neighbor_list(id).out_est(index) < 0.1, continue;, end
    if protocol_params.neighbor_list(id).child(index) == 1, continue;, end
    if protocol_params.neighbor_list(id).hop(index) == Inf, continue;, end
    
    link_cost = calculate_link_cost(0, protocol_params.neighbor_list(id).in_est(index), protocol_params.neighbor_list(id).out_est(index));
    if link_cost > protocol_params.neighbor_sel_threshold, continue;, end
    
    hop = protocol_params.neighbor_list(id).hop(index);
    small_hop = hop < current_min_hop;
    equal_hop_better_estimate = hop == current_min_hop & current_min_link_cost > link_cost;
    if (small_hop | equal_hop_better_estimate) 
        current_min_hop = hop;
        current_min_link_cost = link_cost;
        best_index = index;
    end
end
if best_index ~= -1 
    all_mote.parent(id) = protocol_params.neighbor_list(id).nodeID(best_index);
    all_mote.hop(id) = protocol_params.neighbor_list(id).hop(best_index) + 1;
% COMPILE %    if sim_params.gui_mode, 
% COMPILE %        feval('gui_layer', protocol_params.parent_line_func, id, all_mote.X(id), all_mote.Y(id), ...
% COMPILE %            all_mote.X(all_mote.parent(id)), all_mote.Y(all_mote.parent(id)), ...
% COMPILE %            'Reliability', ['app_lib(''display_reliability'', ' num2str(id) ');']);
% COMPILE %    end;
end

%% kill all those sendest, receiveest is less than 10%

%% kill those parent is invalid
%% kill those hop is invalid
%% kill those who are my children
%% find the one with best shortest hop
%% if cannot find anyone, set invalid
%% set the right infomation
    
    
    % Find good neighbors greater than threshold for the forward direction
    
%     [r,c]=find(protocol_params.neighbor_list(id).in_est >= protocol_params.neighbor_sel_threshold);
%     potential_parents = protocol_params.neighbor_list(id).nodeID(c);
%     potential_hops = protocol_params.neighbor_list(id).hop(c);
%     potential_in_est = protocol_params.neighbor_list(id).in_est(c);
    
    % Avoid routing using immediate children as parent
    %if ~isempty(protocol_params.neighbor_list(id).route_parent)
%     potential_route_parent = protocol_params.neighbor_list(id).route_parent(c);    
%     if ~isempty(potential_route_parent)
%         [r,c] = find(potential_route_parent ~= id);
%         potential_parents = potential_parents(c);
%         potential_hops = potential_hops(c);
%         potential_in_est = potential_in_est(c);
%     end
    %end
    
    % Find the min hop among these good neighbors
    %[shortest_hop, shortest_index] = min(protocol_params.neighbor_list(id).hop(c));
%     [shortest_hop, shortest_index] = min(potential_hops);
    %% find all nodes that have the min hop counts > threshold
%     if ~isempty(potential_parents) & shortest_hop ~= +Inf
%         [r,c]=find(potential_hops == shortest_hop);
%         potential_parents = potential_parents(c);
%         potential_in_est = potential_in_est(c);
%         [r,c]=max(potential_in_est);
%         if ~isempty(c)
            %[a,b]=find(protocol_params.neighbor_list(potential_parents(c)).nodeID==id);
            %if abs(protocol_params.neighbor_list(potential_parents(c)).out_est(b) - r) > 0.5
            %    disp('0.99');    
            %end
%             all_mote.parent(id) = potential_parents(c);
%             all_mote.hop(id) = shortest_hop + 1;
% % COMPILE %    if sim_params.gui_mode, 
% % COMPILE %        feval('gui_layer', protocol_params.parent_line_func, id, all_mote.X(id), all_mote.Y(id), ...
% % COMPILE %            all_mote.X(all_mote.parent(id)), all_mote.Y(all_mote.parent(id)), ...
% % COMPILE %            'Reliability', ['app_lib(''display_reliability'', ' num2str(id) ');']);
% % COMPILE %    end;
%         end
%     end
% end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function process_routing_packet(id, receive_packet)
global all_mote sim_params protocol_params;

%% TERENCE: don't do choose parent when receive route packet
[new, index] = find_neighbor_index(receive_packet.source, protocol_params.neighbor_list(id));
[neighbor_new, index_feedback] = find_neighbor_index(id, receive_packet.neighbor_list);
in_est = 0;
if ~neighbor_new, in_est = receive_packet.neighbor_list.out_est(index_feedback);, end


if new
    %id, index, nodeID, hop, route_parent, packet_seq_num, in_est, out_est, track_info
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, protocol_params.invalid_parent, ...
        0, in_est, 0, ...
        feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, []), protocol_params.no_save);
else
    if isempty(protocol_params.neighbor_list(id).track_info)
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, []);
    else
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index));
    end
    %id, index, nodeID, hop, route_parent, packet_seq_num, in_est, out_est, track_info
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, protocol_params.no_save, ...
        protocol_params.no_save, in_est, feval(protocol_params.estimator, 'calculate_est', track_info), ... %calculate_est(track_info), ...
        track_info, protocol_params.no_save);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function shortestpath_packet = shortestpath_routing_packet(source, hop, neighbor_list, length)
global protocol_params radio_params;
shortestpath_packet.source = source;
shortestpath_packet.hop = hop;
shortestpath_packet.neighbor_list = neighbor_list;%neighbor_list_filtering(neighbor_list, protocol_params.num_neighbor_to_feedback);
shortestpath_packet.type = protocol_params.route_packet_type;
shortestpath_packet.length = length;
shortestpath_packet.parent = radio_params.broadcast_addr;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function result=neighbor_list_filtering(neighbor_list, num_neighbor)
% if length(neighbor_list.out_est) > num_neighbor    
%     [list,index] = sort(-1*neighbor_list.out_est);
%     list = list * -1;
%     result.out_est = list(1:num_neighbor);
%     result.nodeID = neighbor_list.nodeID(index(1:num_neighbor));
%     %result.hop = neighbor_list.hop(index(1:num_neighbor));
% else
%     result = neighbor_list;    
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function est = link_est(source, dest)
global protocol_params
dest_index = find(protocol_params.neighbor_list(source).nodeID == dest);
est = protocol_params.neighbor_list(source).in_est(dest_index);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [new, index] = find_neighbor_index(nodeID, neighbor_list)
index = [];
if ~isempty(neighbor_list.nodeID)
    index = find(nodeID == neighbor_list.nodeID);
end
new = 0;
if isempty(index), index = length(neighbor_list.nodeID) + 1; new = 1;, end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function save_neighbor_list(id, index, nodeID, hop, route_parent, packet_seq_num, in_est, out_est, track_info, child)
global protocol_params
protocol_params.neighbor_list(id).nodeID(index) = nodeID;
if in_est ~= protocol_params.no_save, protocol_params.neighbor_list(id).in_est(index) = in_est;, end;
if hop ~= protocol_params.no_save, protocol_params.neighbor_list(id).hop(index) = hop;, end;
if out_est ~= protocol_params.no_save, protocol_params.neighbor_list(id).out_est(index) = out_est;, end;
if route_parent ~= protocol_params.no_save, protocol_params.neighbor_list(id).route_parent(index) = route_parent;, end;
if packet_seq_num ~= protocol_params.no_save, protocol_params.neighbor_list(id).packet_seq_num(index) = packet_seq_num;, end;
% TERENCE: add in the child field
if child ~= protocol_params.no_save, protocol_params.neighbor_list(id).child(index) = child;, end;
if isempty(protocol_params.neighbor_list(id).track_info)
    protocol_params.neighbor_list(id).track_info = [track_info];
else
    protocol_params.neighbor_list(id).track_info(index) = track_info;
end

protocol_params.neighbor_list(id).time_out(index) = protocol_params.list_time_out;

