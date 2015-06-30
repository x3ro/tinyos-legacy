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

function output=exp_shortest_path(varargin)
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
protocol_params.neighbor_sel_threshold=0.75;   % Set to be 50% threshold for parent selection
protocol_params.min_samples = 8;              % Minimum samples to trust an estimation
protocol_params.num_neighbor_to_feedback = 200;
protocol_params.warmup_time = 200*100000;
protocol_params.route_speed_up = 10;
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
protocol_params.neighbor_list(id).nodeID = [];
protocol_params.neighbor_list(id).in_est = [];
protocol_params.neighbor_list(id).out_est = [];
protocol_params.neighbor_list(id).track_info = [];
protocol_params.neighbor_list(id).hop = [];
protocol_params.neighbor_list(id).route_parent = [];
protocol_params.neighbor_list(id).route_seq_num = [];
protocol_params.neighbor_list(id).time_out = [];
protocol_params.round_update(id) = 0;
if id == sim_params.base_station
    all_mote.hop(id)= 0;
    all_mote.route_seq_num(id)=0;
else
    all_mote.hop(id)= +Inf;
    all_mote.route_seq_num(id)=-1;
end
all_mote.last_failed_seq_num(id)=0;
protocol_stat.neighbor_update(id) = 0;
route_phase_shift(id) = 0;
route_stat.cur_num_retrans(id)=0;

% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_func, id, all_mote.X(id), all_mote.Y(id));, end
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ['Mote ' num2str(id)]);, end

ws('insert_event', 'exp_shortest_path', 'clock_tick', start_time, id, {});
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

route_selection(id,'clock');
packet = shortestpath_routing_packet(id, all_mote.hop(id), all_mote.route_seq_num(id), protocol_params.neighbor_list(id), protocol_params.route_packet_length);
feval(sim_params.protocol_send, 'send_packet', id, packet);
interval = protocol_params.route_clock_interval + route_phase_shift(id);

if id == sim_params.base_station
    all_mote.route_seq_num(id)= all_mote.route_seq_num(id) + 1;
end

% COLD Phase
% Scale interval by 10 if this is before the warm up phase
if sim_params.simulation_time <= protocol_params.warmup_time
    interval = interval / protocol_params.route_speed_up;
else
    % WARM Phase
    % No need to scale the interval by 10
    % Have to figure out which neighbor is old
    invalid_neighbor_index = find(protocol_params.neighbor_list(id).time_out <= 0);
    protocol_params.neighbor_list(id).in_est(invalid_neighbor_index) = 0;
    protocol_params.neighbor_list(id).out_est(invalid_neighbor_index) = 0;
    for i=1:length(invalid_neighbor_index)
        protocol_params.neighbor_list(id).track_info(invalid_neighbor_index(i)) = ...
            feval(protocol_params.estimator, 'reset_estimation', protocol_params.neighbor_list(id).track_info(invalid_neighbor_index(i)));
    end
    protocol_params.neighbor_list(id).hop(invalid_neighbor_index) = +Inf;
    protocol_params.neighbor_list(id).time_out = protocol_params.neighbor_list(id).time_out - 1;
end

ws('insert_event', 'exp_shortest_path', 'clock_tick', interval, id, {});
route_phase_shift(id) = 0;
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void= send_packet(id, packet)
global all_mote sim_params;
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
    feval(sim_params.application, 'send_packet_done', id, packet, num_retrans, result);
else
    protocol_stat.neighbor_update(id) = protocol_stat.neighbor_update(id) + 1; 
    route_phase_shift(id) = floor(rand * protocol_params.phase_shift_window);
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

% There is a time out of a neighbor, can ignore it
% There is a hop
% EXP: Need to extract the latest route information 
% and update to neighbor (basically just hop since that's the metric)
% What do you need to save to the neighbor, of course the hop. 

[new, index] = find_neighbor_index(receive_packet.source, protocol_params.neighbor_list(id));
if new
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, receive_packet.parent, ... % hop
        0, 0, 0, ...
        feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, [])); 
        %track_packet(receive_packet.link_seqnum, [])); % track_info
else
    if isempty(protocol_params.neighbor_list(id).track_info)
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, []); 
        %track_info = track_packet(receive_packet.link_seqnum, []);
    else
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index));
        %track_info = track_packet(receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index));
    end

    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, receive_packet.parent, ...
        protocol_params.no_save, protocol_params.no_save, feval(protocol_params.estimator, 'calculate_est', track_info), ... %calculate_est(track_info), ... % out_est
        track_info); % track_info
end

% don't know if this is a good idea
if receive_packet.source == all_mote.parent(id)
    if receive_packet.hop == Inf
        % This is path failure
        route_selection(id,'link');
        %elseif receive_packet.hop ~= all_mote.hop(id) - 1
        % My parent find a shorter path
        %all_mote.hop(id) = receive_packet.hop + 1;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function route_selection(id, type)
global protocol_params all_mote sim_params route_stat;

shortest_hop = Inf;

% Current information of the parent
old_parent = all_mote.parent(id);
if all_mote.parent(id) == protocol_params.invalid_parent
    cur_parent_in_est = 0;
    cur_parent_hop = Inf;
else
    [r,c]=find(protocol_params.neighbor_list(id).nodeID == all_mote.parent(id));
    cur_parent_in_est = protocol_params.neighbor_list(id).in_est(c);
    cur_parent_hop = protocol_params.neighbor_list(id).hop(c);
    % don't know if this is a good idea to update my info
    if cur_parent_hop + 1 < all_mote.hop(id)
        all_mote.hop(id) = cur_parent_hop + 1;
    end
end

% Find good neighbors greater than threshold
[r,c]=find(protocol_params.neighbor_list(id).in_est >= protocol_params.neighbor_sel_threshold);
potential_parents = protocol_params.neighbor_list(id).nodeID(c);
potential_hops = protocol_params.neighbor_list(id).hop(c);
potential_in_est = protocol_params.neighbor_list(id).in_est(c);
potential_route_seq_num = protocol_params.neighbor_list(id).route_seq_num(c);

% Like DSDV.
% find all nodes in the neighborhood table that have sequence number greater 
% than last failed sequence number found in neighborhood table.
% All subsequent parents must have seq number greater than this number

if ~isempty(potential_parents)
    % Find all potential parents that have seq number larger than last_failed_seq_num
    [r,c]=find(potential_route_seq_num > all_mote.last_failed_seq_num(id));
    potential_parents = potential_parents(c);
    potential_hops = potential_hops(c);
    potential_in_est = potential_in_est(c);
    
    % Exclude the current parent
    if ~isempty(potential_parents)
        [r,c] = find(potential_parents ~= all_mote.parent(id));

            potential_parents = potential_parents(c);
            potential_hops = potential_hops(c);
            potential_in_est = potential_in_est(c);
            % Find the min hop among these good alternative neighbors
            [shortest_hop, shortest_index] = min(potential_hops);
    end     
end


% Hop is the metric here, can I find a better hop from alternatives
if all_mote.hop(id) > shortest_hop + 1
    %  find all nodes that have the min hop counts > threshold
    if ~isempty(potential_parents) & shortest_hop ~= +Inf
        [r,c]=find(potential_hops == shortest_hop);
        potential_parents = potential_parents(c);
        potential_in_est = potential_in_est(c);        
        [r,c]=max(potential_in_est);
        if ~isempty(c)
            % If this is clock_tick, we find a better parent
            if strcmp(type,'clock')
                % find a better parent by 20% threshold | shorter hop
                if abs(potential_in_est-cur_parent_in_est) > 0.2 | shortest_hop < cur_parent_hop
                    all_mote.parent(id) = potential_parents(c);
                    all_mote.hop(id) = shortest_hop + 1;
                end
            elseif strcmp(type, 'link')                    
                % if this is link failure, we find an alternative parent
                all_mote.parent(id) = potential_parents(c);
                all_mote.hop(id) = shortest_hop + 1;    
            end
        end    
    end
end

% My parent is bad, I can't find an alternative parent.  
% I become a leaf.
if strcmp(type,'link') & all_mote.parent(id) == old_parent & old_parent ~= protocol_params.invalid_parent & id ~= sim_params.base_station
    all_mote.parent(id) = protocol_params.invalid_parent;
    all_mote.hop(id) = Inf;
    route_stat.cur_num_retrans(id) = 0;
    all_mote.last_failed_seq_num(id) = max([all_mote.route_seq_num(id), protocol_params.neighbor_list(id).route_seq_num]); % not the parent's seq number
    all_mote.route_seq_num(id) = -1;
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

% don't know if this is a good idea
if receive_packet.source == all_mote.parent(id)
    if receive_packet.hop == Inf
        % This is path failure
        route_selection(id,'link');
        %elseif receive_packet.hop ~= all_mote.hop(id) - 1
        % My parent find a shorter path
        %all_mote.hop(id) = receive_packet.hop + 1;
    end
end

% 
% if id ~= sim_params.base_station
%     protocol_params.round_update(id) = protocol_params.round_update(id) + 1;    
%     % Find good neighbors greater than threshold
%     [r,c]=find(protocol_params.neighbor_list(id).in_est >= protocol_params.neighbor_sel_threshold);
%     potential_parents = protocol_params.neighbor_list(id).nodeID(c);
%     potential_hops = protocol_params.neighbor_list(id).hop(c);
%     potential_in_est = protocol_params.neighbor_list(id).in_est(c);
%     if ~isempty(protocol_params.neighbor_list(id).route_parent)
%         potential_route_parent = protocol_params.neighbor_list(id).route_parent(c);    
%         if ~isempty(potential_route_parent)
%             [r,c] = find(potential_route_parent ~= id);
%             potential_parents = potential_parents(c);
%             potential_hops = potential_hops(c);
%             potential_in_est = potential_in_est(c);
%         end
%     end
%     
%     % Find the min hop among these good neighbors
%     %[shortest_hop, shortest_index] = min(protocol_params.neighbor_list(id).hop(c));
%     [shortest_hop, shortest_index] = min(potential_hops);
%     %% find all nodes that have the min hop counts > threshold
%     if ~isempty(potential_parents) & shortest_hop ~= +Inf
%         [r,c]=find(potential_hops == shortest_hop);
%         potential_parents = potential_parents(c);
%         potential_in_est = potential_in_est(c);
%         [r,c]=max(potential_in_est);
%         if ~isempty(c)
%             %[a,b]=find(protocol_params.neighbor_list(potential_parents(c)).nodeID==id);
%             %if abs(protocol_params.neighbor_list(potential_parents(c)).out_est(b) - r) > 0.5
%             %    disp('0.99');    
%             %end
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
function update_neighbor_list(id, receive_packet)
global protocol_params all_mote sim_params;

[new, index] = find_neighbor_index(receive_packet.source, protocol_params.neighbor_list(id));
[neighbor_new, index_feedback] = find_neighbor_index(id, receive_packet.neighbor_list);
in_est = 0;
if ~neighbor_new, in_est = receive_packet.neighbor_list.out_est(index_feedback);, end

if new
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, protocol_params.invalid_parent, ...
        receive_packet.route_seq_num, in_est, 0, ...
        feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, []));
        %track_packet(receive_packet.link_seqnum, []));
else
    if isempty(protocol_params.neighbor_list(id).track_info)
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, []);
        %track_info = track_packet(receive_packet.link_seqnum, []);
    else
        track_info = feval(protocol_params.estimator, 'track_packet', receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index));
        %track_info = track_packet(receive_packet.link_seqnum, protocol_params.neighbor_list(id).track_info(index));
    end
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, protocol_params.no_save, ...
        receive_packet.route_seq_num, in_est, feval(protocol_params.estimator, 'calculate_est', track_info), ... %calculate_est(track_info), ...
        track_info);
end

if receive_packet.source == all_mote.parent(id) & receive_packet.hop == Inf
    % This is path failure    
    route_selection(id,'link');     
end

% Update sequence number, what happen if i don't have a parent, my seq number won't get updated
if receive_packet.source == all_mote.parent(id) & id ~= sim_params.base_station
    if all_mote.route_seq_num(id) > receive_packet.route_seq_num
        % This is also path failure
        disp('ERROR');       
    else
        all_mote.route_seq_num(id) = receive_packet.route_seq_num;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function shortestpath_packet = shortestpath_routing_packet(source, hop, route_seq_num, neighbor_list, length)
global protocol_params radio_params;
shortestpath_packet.source = source;
shortestpath_packet.hop = hop;
shortestpath_packet.route_seq_num = route_seq_num;
shortestpath_packet.neighbor_list = neighbor_list_filtering(neighbor_list, protocol_params.num_neighbor_to_feedback);
shortestpath_packet.type = protocol_params.route_packet_type;
shortestpath_packet.length = length;
shortestpath_packet.parent = radio_params.broadcast_addr;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  This is for in-degree control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result=neighbor_list_filtering(neighbor_list, num_neighbor)
if length(neighbor_list.out_est) > num_neighbor    
    [list,index] = sort(-1*neighbor_list.out_est);
    list = list * -1;
    result.out_est = list(1:num_neighbor);
    result.nodeID = neighbor_list.nodeID(index(1:num_neighbor));
    %result.hop = neighbor_list.hop(index(1:num_neighbor));
else
    result = neighbor_list;    
end


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
function save_neighbor_list(id, index, nodeID, hop, route_parent, route_seq_num, in_est, out_est, track_info)
global protocol_params
protocol_params.neighbor_list(id).nodeID(index) = nodeID;
if in_est ~= protocol_params.no_save, protocol_params.neighbor_list(id).in_est(index) = in_est;, end;
if hop ~= protocol_params.no_save, protocol_params.neighbor_list(id).hop(index) = hop;, end;
if out_est ~= protocol_params.no_save, protocol_params.neighbor_list(id).out_est(index) = out_est;, end;
if route_parent ~= protocol_params.no_save, protocol_params.neighbor_list(id).route_parent(index) = route_parent;, end;
if route_seq_num ~= protocol_params.no_save, protocol_params.neighbor_list(id).route_seq_num(index) = route_seq_num;, end;

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

protocol_params.neighbor_list(id).time_out(index) = protocol_params.list_time_out;