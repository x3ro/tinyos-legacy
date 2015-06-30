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

function output=min_trans_path_table(varargin)
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
protocol_params.phase_shift_window = 100000;  % 1 sec phase shift random window to avoid correlated collision
protocol_params.track_info_window = 120;      % XXXXXXXXX Wrong place:  this should be estimator
protocol_params.neighbor_sel_threshold=0.25;  % Set to be 50% threshold for parent selection
protocol_params.min_samples = 10;             % Minimum samples to trust an estimation
protocol_params.neighbor_switch_threshold= 0.5;
%  This is the maximum table size.
protocol_params.route_table_size = 20; % Can be an expected number of good neighbors!

% Don't want this to screw up estimation
%protocol_params.warmup_time = 200*100000;
%protocol_params.route_speed_up = 10;

protocol_params.estimator = 'moving_ave';     % Use moving average as the estimator

%% GUI settings
protocol_params.mote_func = 'square_mote_withno_menu';
protocol_params.parent_line_func = 'parent_line_with_menu';
protocol_params.mote_text_func = 'default_mote_text';

void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is called to initialise this applicaton
function void = initialise(id, start_time)
global all_mote protocol_stat protocol_params sim_params route_phase_shift route_stat;

all_mote.parent(id) = protocol_params.invalid_parent; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize the table
protocol_params.neighbor_list(id).nodeID = [];
protocol_params.neighbor_list(id).in_est = [];
protocol_params.neighbor_list(id).out_est = [];
protocol_params.neighbor_list(id).track_info = [];
protocol_params.neighbor_list(id).hop = [];
protocol_params.neighbor_list(id).route_parent = [];
protocol_params.neighbor_list(id).cost = [];
protocol_params.neighbor_list(id).time_out = [];
protocol_params.neighbor_list(id).freq=[];
protocol_params.neighbor_list(id).size = protocol_params.route_table_size;
%feval(sim_params.table_algo, 'init', id, receive_packet, protocol_params.neighbor_list(id));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
all_mote.parent(id) = protocol_params.invalid_parent; 

if id == sim_params.base_station
    all_mote.hop(id)= 0;
    all_mote.cost(id) = 0;    
else
    all_mote.hop(id)= +Inf;
    all_mote.cost(id) = +Inf;
end
protocol_stat.neighbor_update(id) = 0;
route_phase_shift(id) = 0;

% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_func, id, all_mote.X(id), all_mote.Y(id));, end
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ['Mote ' num2str(id)]);, end

ws('insert_event', 'min_trans_path_table', 'clock_tick', start_time, id, {});
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is same as initialise but this is only called once for all mote. it is called after
% each node is initialise.
function void = global_initialise
global protocol_params radio_params all_mote;
protocol_params.no_save = -2;

for id=1:length(all_mote.parent)
    numNeighbors=length(find(radio_params.prob_table(id,:) > 0));
    numGoodNeighbors=length(find(radio_params.prob_table(id,:) > 0.75));
    protocol_params.neighbor_list(id).downSamplingRate = protocol_params.route_table_size/numNeighbors;
end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clock tick function
function void = clock_tick(id)
global all_mote sim_params protocol_params app_params protocol_stat route_phase_shift;

if id ~= sim_params.base_station
    % Call the route selection algorithm from clock
    route_selection(id);
end

% Create a minTransRoutingPacket.
%   We still dump the table for now.
%   We can round robin later.
packet = shortestpath_routing_packet(id, all_mote.hop(id), all_mote.cost(id), protocol_params.neighbor_list(id), protocol_params.route_packet_length);

% Send out the routing packet
feval(sim_params.protocol_send, 'send_packet', id, packet);

% Schedule to the next clock
interval = protocol_params.route_clock_interval + route_phase_shift(id);


% COLD Phase
% Scale interval by 10 if this is before the warm up phase
%if sim_params.simulation_time <= protocol_params.warmup_time
%    interval = interval / protocol_params.route_speed_up;
%else
    % WARM Phase
    % No need to scale the interval by 10
    
% Have to figure out which neighbor is old
% Should ignore this since we have our routing table management.
%invalid_neighbor_index = find(protocol_params.neighbor_list(id).time_out <= 0);
%protocol_params.neighbor_list(id).in_est(invalid_neighbor_index) = 0;
%protocol_params.neighbor_list(id).out_est(invalid_neighbor_index) = 0;
%for i=1:length(invalid_neighbor_index)
%    protocol_params.neighbor_list(id).track_info(invalid_neighbor_index(i)) = ...
%    feval(protocol_params.estimator, 'reset_estimation', protocol_params.neighbor_list(id).track_info(invalid_neighbor_index(i)));
%end
%protocol_params.neighbor_list(id).hop(invalid_neighbor_index) = +Inf;
%protocol_params.neighbor_list(id).time_out = protocol_params.neighbor_list(id).time_out - 1;

ws('insert_event', 'min_trans_path_table', 'clock_tick', interval, id, {});
route_phase_shift(id) = 0;
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void= send_packet(id, packet)
global all_mote sim_params;
% Why???????????????????????
packet.hop = all_mote.hop(id);
feval(sim_params.protocol_send, 'send_packet', id, packet);
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = send_packet_done(id, packet, num_retrans, result)
global sim_params protocol_params protocol_stat route_phase_shift route_stat all_mote;
if packet.type ~= protocol_params.route_packet_type
    % Application should not send packets over here.  It should use mh_send_packet.
    % If application does send over here (eg. base station since it doesn't have a parent
    % always return 0 retransmission.
    feval(sim_params.application, 'send_packet_done', id, packet, num_retrans, result);
else
    protocol_stat.neighbor_update(id) = protocol_stat.neighbor_update(id) + 1; 
    route_phase_shift(id) = floor(rand * protocol_params.phase_shift_window);
end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = receive_packet(id, receive_packet)
global sim_params protocol_params all_mote

% if this packet is an originated data packet, call insert to table.
% if it is in table, then process it.  Otherwise, just ignore it.
feval(sim_params.table_algo, 'insert', id, receive_packet, sim_params.protocol);

if receive_packet.type ~= protocol_params.route_packet_type
    process_data_packet(id, receive_packet);
    % Upper Layer check to see if the packet received is directed to it.
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

% There is a time out of a neighbor, can ignore it
% There is a hop
% EXP: Need to extract the latest route information 
% and update to neighbor (basically just hop since that's the metric)
% What do you need to save to the neighbor, of course the hop. 

[new, index] = find_neighbor_index(receive_packet.source, protocol_params.neighbor_list(id));
if new
    % Do nothing ;)  Assume the table insertion had done it correctly.
    %save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, receive_packet.parent, ... % hop
    %    0, 0, 0, ...
    %    feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, [])); 
    %    %track_packet(receive_packet.link_seqnum, [])); % track_info
else
    if isempty(protocol_params.neighbor_list(id).track_info)
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, []); 
        %track_info = track_packet(receive_packet.link_seqnum, []);
    else
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index));
        %track_info = track_packet(receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index));
    end

    save_neighbor_list(id, index, receive_packet.source, protocol_params.no_save, receive_packet.parent, ...
        protocol_params.no_save, protocol_params.no_save, feval(protocol_params.estimator, 'calculate_est', track_info), ... %calculate_est(track_info), ... % out_est
        track_info); % track_info
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function route_selection(id)
global protocol_params all_mote sim_params route_stat;

% Current information of the parent
old_parent = all_mote.parent(id);
if all_mote.parent(id) == protocol_params.invalid_parent
    cur_parent_in_est = 0;
    cur_parent_out_est = 0;
    cur_parent_hop = Inf;
    cur_parent_cost = Inf;
else
    [r,c]=find(protocol_params.neighbor_list(id).nodeID == all_mote.parent(id));
    cur_parent_in_est = protocol_params.neighbor_list(id).in_est(c);
    cur_parent_out_est = protocol_params.neighbor_list(id).out_est(c);
    cur_parent_hop = protocol_params.neighbor_list(id).hop(c);
    if (cur_parent_in_est >= protocol_params.neighbor_sel_threshold | cur_parent_out_est >= protocol_params.neighbor_sel_threshold)
        cur_parent_cost = protocol_params.neighbor_list(id).cost(c) + 1./(cur_parent_in_est * cur_parent_out_est);
    else
        cur_parent_cost = Inf;    
    end
end

if isempty(protocol_params.neighbor_list(id).in_est)
    return;    
end

% Find good neighbors greater than threshold for both in_est and out_est
[r,c]=find(protocol_params.neighbor_list(id).in_est >= protocol_params.neighbor_sel_threshold ...
           & protocol_params.neighbor_list(id).out_est >= protocol_params.neighbor_sel_threshold ...
           & protocol_params.neighbor_list(id).route_parent ~= id ...
           & protocol_params.neighbor_list(id).cost ~= Inf);
potential_parents = protocol_params.neighbor_list(id).nodeID(c);
potential_hops = protocol_params.neighbor_list(id).hop(c);
potential_in_est = protocol_params.neighbor_list(id).in_est(c);
potential_out_est = protocol_params.neighbor_list(id).out_est(c);
potential_cost = protocol_params.neighbor_list(id).cost(c);

if ~isempty(potential_parents)    
    % Exclude the current parent
    [r,c] = find(potential_parents ~= all_mote.parent(id));

    potential_parents = potential_parents(c);
    potential_hops = potential_hops(c);
    potential_in_est = potential_in_est(c);
    potential_out_est = potential_out_est(c);
    potential_cost = potential_cost(c);
    actual_cost = potential_cost + 1./(potential_in_est .* potential_out_est);
    
    % No min link cost yet!!!!!!!!!
    
    % Alternative parent
    [min_val, min_index]=min(actual_cost);
    
    if cur_parent_cost - actual_cost(min_index) > protocol_params.neighbor_switch_threshold
        % Switch to this parent
        all_mote.parent(id) = potential_parents(min_index);
        all_mote.hop(id) = potential_hops(min_index) + 1;
        all_mote.cost(id) = actual_cost(min_index);
    else
        % Keep the old parent
        all_mote.parent(id) = old_parent;
        all_mote.hop(id) = cur_parent_hop + 1;
        all_mote.cost(id) = cur_parent_cost;                
    end
else
    % Can't find any parent, declare no route!
    all_mote.parent(id) = protocol_params.invalid_parent;
    all_mote.hop(id) = Inf;
    all_mote.cost(id) = Inf;
end


% COMPILE % if all_mote.parent(id) ~= protocol_params.invalid_parent
% COMPILE %    if sim_params.gui_mode, 
% COMPILE %        feval('gui_layer', protocol_params.parent_line_func, id, all_mote.X(id), all_mote.Y(id), ...
% COMPILE %            all_mote.X(all_mote.parent(id)), all_mote.Y(all_mote.parent(id)), ...
% COMPILE %            'Reliability', ['app_lib(''display_reliability'', ' num2str(id) ');']);
% COMPILE %    end;
% COMPILE % else
% COMPILE %    if sim_params.gui_mode, 
% COMPILE %        feval('gui_layer', protocol_params.parent_line_func, id, all_mote.X(id), all_mote.Y(id), ...
% COMPILE %            all_mote.X(id), all_mote.Y(id), ...
% COMPILE %            'Reliability', ['app_lib(''display_reliability'', ' num2str(id) ');']);
% COMPILE %    end;
% COMPILE % end

% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ...
% COMPILE %        ['Mote ' num2str(id) ' p ' num2str(all_mote.parent(id))]);, end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function process_routing_packet(id, receive_packet)
global all_mote sim_params protocol_params;
%% update the neighbor_list based on the input packet, return the source's neighbor struct
update_neighbor_list(id, receive_packet);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_neighbor_list(id, receive_packet)
global protocol_params all_mote sim_params;

% Is this neighbor not in the table?
[new, index] = find_neighbor_index(receive_packet.source, protocol_params.neighbor_list(id));

% Does this neighbor gives me any feedback?
[neighbor_new, index_feedback] = find_neighbor_index(id, receive_packet.neighbor_list);
in_est = 0;
if ~neighbor_new, in_est = receive_packet.neighbor_list.out_est(index_feedback);, end

%%%  Fix: XXX
if in_est==0 & ~new
    in_est = protocol_params.no_save;    
end

if new
    % If this neighbor is not in table, can't do anything.
    %save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, protocol_params.invalid_parent, ...
    %    receive_packet.route_seq_num, in_est, 0, ...
    %    feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, []));
    %    %track_packet(receive_packet.link_seqnum, []));
else
    if isempty(protocol_params.neighbor_list(id).track_info)
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, []);
        %track_info = track_packet(receive_packet.link_seqnum, []);
    else
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index));
        %track_info = track_packet(receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index));
    end
    
    % XXX:  if the neighbor doesn't have an in_est for me, I should not overwrite the old one with 0.
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, protocol_params.no_save, ...
        receive_packet.cost, in_est, feval(protocol_params.estimator, 'calculate_est', track_info), ... %calculate_est(track_info), ...
        track_info);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void=new_neighbor_entry(entry_index, id, receive_packet)
global protocol_params;

if receive_packet.type ~= protocol_params.route_packet_type
    % Storing a new data entry
    save_neighbor_list(id, entry_index, receive_packet.source, Inf, receive_packet.parent, ... % hop
                   Inf, 0, 0, feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, [])); 
else               
    % Storing a new route entry
    save_neighbor_list(id, entry_index, receive_packet.source, receive_packet.hop, protocol_params.invalid_parent, ...
    Inf, 0, 0, feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, []));
end

void=-1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function shortestpath_packet = shortestpath_routing_packet(source, hop, cost, neighbor_list, length)
global protocol_params radio_params;
shortestpath_packet.source = source;
shortestpath_packet.hop = hop;
shortestpath_packet.cost = cost;
shortestpath_packet.neighbor_list = neighbor_list;
shortestpath_packet.type = protocol_params.route_packet_type;
shortestpath_packet.length = length;
shortestpath_packet.parent = radio_params.broadcast_addr;


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
function save_neighbor_list(id, index, nodeID, hop, route_parent, cost, in_est, out_est, track_info)
global protocol_params
protocol_params.neighbor_list(id).nodeID(index) = nodeID;
if in_est ~= protocol_params.no_save, protocol_params.neighbor_list(id).in_est(index) = in_est;, end;
if hop ~= protocol_params.no_save, protocol_params.neighbor_list(id).hop(index) = hop;, end;
if cost ~= protocol_params.no_save, protocol_params.neighbor_list(id).cost(index) = cost;, end;
if cost == 0 & nodeID ~= 1
    cost;    
end
if out_est ~= protocol_params.no_save, protocol_params.neighbor_list(id).out_est(index) = out_est;, end;
if route_parent ~= protocol_params.no_save, protocol_params.neighbor_list(id).route_parent(index) = route_parent;, end;

% No reason to check for seqnum is a field in track info
%
%no_save_track_info = isfield(track_info, 'seqnum');
%if isempty(protocol_params.neighbor_list(id).track_info) & no_save_track_info
%    protocol_params.neighbor_list(id).track_info = [track_info];
%elseif no_save_track_info
%    protocol_params.neighbor_list(id).track_info(index) = track_info;
%end

if isempty(protocol_params.neighbor_list(id).track_info)
    protocol_params.neighbor_list(id).track_info = [track_info];
else
    protocol_params.neighbor_list(id).track_info(index) = track_info;
end

% Update the time out.
protocol_params.neighbor_list(id).time_out(index) = protocol_params.list_time_out;
