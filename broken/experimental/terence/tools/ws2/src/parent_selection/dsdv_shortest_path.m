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

% No Estimation of seq number arrival time.
% Same route update as DSDV
% No usage of even/odd seq number, path failed detection based on failed parent

function output=dsdv_shortest_path(varargin)
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
protocol_params.list_time_out = 2;               % This specifies timeout of a neighboring node (e.g. 2 route msg time)
protocol_params.route_packet_length =  666;      % Packet length in bits
protocol_params.phase_shift_window = 100000;     % 1 sec phase shift random window to avoid repeated collision
protocol_params.num_neighbor_to_feedback = 200;  % Maximum number of neighbors to give feedback
protocol_params.warmup_time = 200*100000;        % Warm up time.  200 seconds.
protocol_params.route_speed_up = 5;             % Route update speed up time (e.g. 10 times shorter than the usual route time)

%% GUI settings
protocol_params.mote_func = 'square_mote_withno_menu';
protocol_params.parent_line_func = 'parent_line_with_menu';
protocol_params.mote_text_func = 'default_mote_text';

void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is called to initialise this applicaton
function void = initialise(id, start_time)
global all_mote protocol_stat protocol_params sim_params route_phase_shift route_stat;

% Initialize the parent to be invalid.
% This has an effect that no DATA messages are sent unless there is a route!
%
% NOTE:  EVEN invalid_parent is used.  The message will still be sent out!
% Is invalid_parent == broadcast?
all_mote.parent(id) = protocol_params.invalid_parent; 

% Initialize the neighborhood table fields
protocol_params.neighbor_list(id).nodeID = [];         % node ID
protocol_params.neighbor_list(id).hop = [];            % hop count
protocol_params.neighbor_list(id).sink_seq_num = [];   % DSDV sink seq number
protocol_params.neighbor_list(id).time_out = [];       % time out value for each node
protocol_params.neighbor_list(id).packet_seq_num = []; % packet sequence number to avoid duplicated packet

% If this is the base station, set hop to 0, set the sink seq number to 0
if id == sim_params.base_station
    all_mote.hop(id)= 0;
    all_mote.sink_seq_num(id)=0;
else
% If this is not the base station, initialize hop to Inf, set the sink seq to invalid
    all_mote.hop(id)= +Inf;
    all_mote.sink_seq_num(id)=-1;
end

% set the packet seq number to zero
all_mote.packet_seq_num(id) = 0;

% Initialize phase shift to be 0
route_phase_shift(id) = 0;

% Initialize number of retransmission to be 0
route_stat.cur_num_retrans(id)=0;

% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_func, id, all_mote.X(id), all_mote.Y(id));, end
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ['Mote ' num2str(id)]);, end

% Start the clock
ws('insert_event', 'dsdv_shortest_path', 'clock_tick', start_time, id, {});
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

% For each clock tick, run dsdv route selection and broadcast latest "route information".  
% This is like distance-vector protocol.
route_selection(id,'clock');
% The packet contains:  id, hop count, and sink_seq_num
packet = shortestpath_routing_packet(id, all_mote.hop(id), all_mote.sink_seq_num(id), protocol_params.route_packet_length);
% Send out the broadcast packet.
feval(sim_params.protocol_send, 'send_packet', id, packet);

% If this is the base station, increment the sink seq number
if id == sim_params.base_station
    all_mote.sink_seq_num(id)= all_mote.sink_seq_num(id) + 1;
end

% Compute the next clock event time
interval = protocol_params.route_clock_interval + route_phase_shift(id);

% Scale interval if this is in the WARM UP Phase.
%if sim_params.simulation_time <= protocol_params.warmup_time
%    interval = interval / protocol_params.route_speed_up;
%end

% Have to figure out which neighbor is old.
% If haven't heard even one packte from a neighbor, consider that it is gone by setting its hop to be infinity.
invalid_neighbor_index = find(protocol_params.neighbor_list(id).time_out <= 0);
protocol_params.neighbor_list(id).hop(invalid_neighbor_index) = +Inf;
protocol_params.neighbor_list(id).time_out = protocol_params.neighbor_list(id).time_out - 1;

% Phase shift if any has been considered.  It must be clear now.
route_phase_shift(id) = 0;

% Insert the next clock tick event.
ws('insert_event', 'dsdv_shortest_path', 'clock_tick', interval, id, {});

void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void=send_packet(id, packet)
global all_mote sim_params;
% Fill in the "Routing Information" header for each packet.
% For this version:  "HOP, PACKET_SEQ_NUM"
% Increment sequence number to avoid duplicated packet.
%packet.hop = all_mote.hop(id);
packet.packet_seq_num = all_mote.packet_seq_num(id);
all_mote.packet_seq_num(id) = all_mote.packet_seq_num(id) + 1;
feval(sim_params.protocol_send, 'send_packet', id, packet);
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = send_packet_done(id, packet, num_retrans, result)
global sim_params protocol_params protocol_stat route_phase_shift route_stat all_mote;

% If the packet just sent is an Application packet,
if packet.type ~= protocol_params.route_packet_type  
    % If the parent is valid, count num_retrans to see if it is a link failure.
    % NOTICE, link failure is FUZZY and the following is just a hack
    if (all_mote.parent(id) ~= protocol_params.invalid_parent)
        route_stat.cur_num_retrans(id) = route_stat.cur_num_retrans(id) + num_retrans;
        if (route_stat.cur_num_retrans(id) > protocol_params.link_failure_retrans)
            % determine that this is link failure and re-evaluate "Route_Selection."
            disp(['Link Failure ' num2str(id) ': parent=' num2str(all_mote.parent(id))]);
            route_selection(id, 'link');
        end
    end
    % If messages can still go through, reset the link_failure statistics.
    if (num_retrans < protocol_params.number_of_retransmission)
        route_stat.cur_num_retrans(id)=0;    
    end
    
    % Signal to the upper layer that packet has been sent.
    feval(sim_params.application, 'send_packet_done', id, packet, num_retrans, result);
else
    % if the packet is a route packet, perform a random BROADCAST to avoid repeated
    % collisions.
    route_phase_shift(id) = floor(rand * protocol_params.phase_shift_window);
end
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = receive_packet(id, receive_packet)
global sim_params protocol_params all_mote


% Receive an application packet
if receive_packet.type ~= protocol_params.route_packet_type

    % Process the data packet
    old_packet = process_data_packet(id, receive_packet);
    
    % Signal upper layer if this not a duplicated packet
    if old_packet == 0
        feval(sim_params.application, 'receive_packet', id, receive_packet);
    end

else
    % Receive a Routing Broadcast, process it.
    process_routing_packet(id, receive_packet);    
end
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ...
% COMPILE %        ['Mote ' num2str(id) ' p ' num2str(all_mote.parent(id))]);, end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function old_packet = process_data_packet(id, receive_packet)
global protocol_params all_mote radio_params sim_params
% Data packet contains "Route Information" and payload

old_packet = 0;

% Extract the neighbor information from this packet.
[new, index] = find_neighbor_index(receive_packet.source, protocol_params.neighbor_list(id));

if new
    %id, index, nodeID, hop, sink_seq_num, packet_seq_num    
    save_neighbor_list(id, index, receive_packet.source, Inf, 0, receive_packet.packet_seq_num);
else
    % Avoid forwarding duplicated packet.
    if receive_packet.packet_seq_num <= protocol_params.neighbor_list(id).packet_seq_num(index)
        old_packet = 1;
    end
    %id, index, nodeID, hop, sink_seq_num, packet_seq_num    
    save_neighbor_list(id, index, receive_packet.source, protocol_params.no_save, protocol_params.no_save, receive_packet.packet_seq_num);
end

% don't know if this is a good idea
% If my parent's address becomes broadcast, signals bad routes.
if receive_packet.source == all_mote.parent(id)
    if (receive_packet.parent == protocol_params.invalid_parent | receive_packet.parent == radio_params.broadcast_addr) ...
        & receive_packet.source ~= sim_params.base_station           
        % This is PATH failure
        disp(['Parent parent becomes invalid: ' num2str(id) ': parent=' num2str(all_mote.parent(id))]);
        route_selection(id,'link');
%        %elseif receive_packet.hop ~= all_mote.hop(id) - 1
%        % My parent find a shorter path
%        %all_mote.hop(id) = receive_packet.hop + 1;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function route_selection(id, type)
global protocol_params all_mote sim_params route_stat;

% Local variable
shortest_hop = Inf;

% Extract current information of the parent and update my own information
old_parent = all_mote.parent(id);
if all_mote.parent(id) == protocol_params.invalid_parent
    cur_parent_hop = Inf;
else
    [r,c]=find(protocol_params.neighbor_list(id).nodeID == all_mote.parent(id));
    cur_parent_hop = protocol_params.neighbor_list(id).hop(c);
    if cur_parent_hop ~= Inf
        all_mote.hop(id) = cur_parent_hop + 1;
    end
end

% Extract information from the neighborhood table
potential_parents = protocol_params.neighbor_list(id).nodeID;
potential_hops = protocol_params.neighbor_list(id).hop;
potential_sink_seq_num = protocol_params.neighbor_list(id).sink_seq_num;


% Like DSDV.
% find all nodes in the neighborhood table that have sequence number greater 
% than last failed sequence number found in neighborhood table.
% All subsequent parents must have seq number greater than this number
if ~isempty(potential_parents)
    % Find all potential parents that have the largest sink seq number larger than current route seq number
    largest_sink_seq_num=max(potential_sink_seq_num);
    [r,c]=find(potential_sink_seq_num == largest_sink_seq_num & potential_sink_seq_num > all_mote.sink_seq_num(id));
    potential_sink_seq_num = potential_sink_seq_num(c);
    potential_parents = potential_parents(c);
    potential_hops = potential_hops(c);
        
    % Find the min hop among these good neighbors
    [shortest_hop, shortest_index] = min(potential_hops);
end

%  if there are parents whose seq number is greater than mine and the hop is not infinity,
%  then, take this parent and ignore all other metrics. (double check)
if ~isempty(potential_parents) & shortest_hop ~= +Inf
    [r,c]=find(potential_hops == shortest_hop);
    potential_parents = potential_parents(c);
    if ~isempty(c)
        % if I can find my current parent, keep the current parent
        % otherwise, just pick the first alternative parent
        if isempty(find(potential_parents== all_mote.parent(id)))
            all_mote.parent(id) = potential_parents(1);
            all_mote.hop(id) = shortest_hop + 1;
        end
    end    
end

% My parent is bad, I can't find an alternative parent.  
% I become a leaf.  No more data forwarding since parent is set to invalid.
if strcmp(type,'link') & all_mote.parent(id) == old_parent & old_parent ~= protocol_params.invalid_parent & id ~= sim_params.base_station
    all_mote.parent(id) = protocol_params.invalid_parent;
    all_mote.hop(id) = Inf;
    route_stat.cur_num_retrans(id) = 0;
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
% This is a Routing Packet.  If my parent's hop becomes Inf, this ia path failure.
if receive_packet.source == all_mote.parent(id)
    if receive_packet.hop == Inf
        % This is path failure
        disp(['Parent hop becomes inf: ' num2str(id) ': parent=' num2str(all_mote.parent(id))]);
        route_selection(id,'link');
        %elseif receive_packet.hop ~= all_mote.hop(id) - 1
        % My parent find a shorter path
        %all_mote.hop(id) = receive_packet.hop + 1;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_neighbor_list(id, receive_packet)
global protocol_params all_mote sim_params;

% Find the index to the neighborhood table of this neighbor
[new, index] = find_neighbor_index(receive_packet.source, protocol_params.neighbor_list(id));

%id, index, nodeID, hop, sink_seq_num, packet_seq_num    
if new
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, receive_packet.sink_seq_num, 0);
else
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, receive_packet.sink_seq_num, protocol_params.no_save);
end

% Update sequence number, what happen if i don't have a parent, my seq number won't get updated
% Don't need to use DSDV's even and odd sequence number for route pruning.
if receive_packet.source == all_mote.parent(id) & id ~= sim_params.base_station
    if all_mote.sink_seq_num(id) > receive_packet.sink_seq_num
        % This is also path failure
        disp('ERROR');       
    else
        all_mote.sink_seq_num(id) = receive_packet.sink_seq_num;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function shortestpath_packet = shortestpath_routing_packet(source, hop, sink_seq_num, length)
global protocol_params radio_params;
% Prepare routing packet
shortestpath_packet.source = source;
shortestpath_packet.hop = hop;
shortestpath_packet.sink_seq_num = sink_seq_num;
shortestpath_packet.type = protocol_params.route_packet_type;
shortestpath_packet.length = length;
shortestpath_packet.parent = radio_params.broadcast_addr;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [new, index] = find_neighbor_index(nodeID, neighbor_list)
index = [];
if ~isempty(neighbor_list.nodeID)
    index = find(nodeID == neighbor_list.nodeID);
end
new = 0;
if isempty(index), index = length(neighbor_list.nodeID) + 1; new = 1;, end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function save_neighbor_list(id, index, nodeID, hop, sink_seq_num, packet_seq_num)
global protocol_params
protocol_params.neighbor_list(id).nodeID(index) = nodeID;
if hop ~= protocol_params.no_save, protocol_params.neighbor_list(id).hop(index) = hop;, end;
if sink_seq_num ~= protocol_params.no_save, protocol_params.neighbor_list(id).sink_seq_num(index) = sink_seq_num;, end;
if packet_seq_num ~= protocol_params.no_save, protocol_params.neighbor_list(id).packet_seq_num(index) = packet_seq_num;, end;

protocol_params.neighbor_list(id).time_out(index) = protocol_params.list_time_out;