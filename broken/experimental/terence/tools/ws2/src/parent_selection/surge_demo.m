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

function output=surge_demo(varargin)
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
protocol_params.track_info_window = 20;       % XXXXXXXXX Wrong place:  this should be estimator
protocol_params.neighbor_sel_threshold=0.5;  % Set to be 50% threshold for parent selection
protocol_params.min_samples = 8;              % Minimum samples to trust an estimation
protocol_params.estimator = 'moving_ave';     % Use moving average as the estimator

%% GUI settings
protocol_params.mote_func = 'square_mote_withno_menu';
protocol_params.parent_line_func = 'parent_line_with_menu';
protocol_params.mote_text_func = 'default_mote_text';

void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is called to initialise this applicaton
function void = initialise(id, start_time)
global all_mote protocol_stat protocol_params sim_params;

all_mote.parent(id) = protocol_params.invalid_parent; 
protocol_params.neighbor_list(id).nodeID = [];
protocol_params.neighbor_list(id).out_est = [];
protocol_params.neighbor_list(id).track_info = [];
protocol_params.neighbor_list(id).hop = [];
protocol_params.neighbor_list(id).route_parent = [];
protocol_params.neighbor_list(id).ack_failed = [];
protocol_params.neighbor_list(id).time_out = [];
protocol_params.neighbor_list(id).in_est =[];
if id == sim_params.base_station
    all_mote.hop(id)= 0;
else
    all_mote.hop(id)= +Inf;
end

% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_func, id, all_mote.X(id), all_mote.Y(id));, end
% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ['Mote ' num2str(id)]);, end

ws('insert_event', 'surge_demo', 'clock_tick', start_time, id, {});
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
global all_mote sim_params protocol_params app_params protocol_stat packet_sent;

% Set interval to the next clock interval
interval = protocol_params.route_clock_interval;

% Have to figure out which neighbor is old
invalid_neighbor_index = find(protocol_params.neighbor_list(id).time_out <= 0);

% Clear old neighbors
protocol_params.neighbor_list(id).out_est(invalid_neighbor_index) = 0;
protocol_params.neighbor_list(id).ack_failed(invalid_neighbor_index) = 0;

for i=1:length(invalid_neighbor_index)
    protocol_params.neighbor_list(id).track_info(invalid_neighbor_index(i)) = ...
        feval(protocol_params.estimator, 'reset_estimation', protocol_params.neighbor_list(id).track_info(invalid_neighbor_index(i)));
end
protocol_params.neighbor_list(id).hop(invalid_neighbor_index) = +Inf;

% Decrement neighbor reference count
protocol_params.neighbor_list(id).time_out = protocol_params.neighbor_list(id).time_out - 1;

% date_msg * Exp(retrans) 
exp_retrans = floor(packet_sent * ( 1 - protocol_params.neighbor_sel_threshold));
packet_sent = 0;

% Update ACK_FAILED for parent
if ~isempty(protocol_params.neighbor_list(id).nodeID)
    [new, index] = find(all_mote.parent(id)==protocol_params.neighbor_list(id).nodeID);
    if ~isempty(index)
        protocol_params.neighbor_list(id).ack_failed(index) = protocol_params.neighbor_list(id).ack_failed(index) - exp_retrans;
        % Make negative ACK_FAILED to be zero
        if protocol_params.neighbor_list(id).ack_failed(index) < 0
            protocol_params.neighbor_list(id).ack_failed(index) = 0;
        end
    end
end




ws('insert_event', 'surge_demo', 'clock_tick', interval, id, {});
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void= send_packet(id, packet)
global sim_params packet_sent;
feval(sim_params.protocol_send, 'send_packet', id, packet);
packet_sent = packet_sent + 1;
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = send_packet_done(id, packet, num_retrans, result)
global sim_params protocol_params protocol_stat route_phase_shift all_mote;

feval(sim_params.application, 'send_packet_done', id, packet, num_retrans, result);

index = [];
if ~isempty(protocol_params.neighbor_list(id).nodeID)
    [new, index] = find(all_mote.parent(id) == protocol_params.neighbor_list(id).nodeID);
    if ~isempty(index)
        protocol_params.neighbor_list(id).ack_failed(index) = protocol_params.neighbor_list(id).ack_failed(index) + num_retrans;
    end
end

void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = receive_packet(id, receive_packet)
global sim_params protocol_params all_mote

process_data_packet(id, receive_packet);
feval(sim_params.application, 'receive_packet', id, receive_packet);

% COMPILE %if sim_params.gui_mode, feval('gui_layer', protocol_params.mote_text_func, id, all_mote.X(id), all_mote.Y(id), ...
% COMPILE %        ['Mote ' num2str(id) ' p ' num2str(all_mote.parent(id))]);, end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function process_data_packet(id, receive_packet)
global protocol_params all_mote

% First update neighborhood with new data packet
update_neighbor_list(id, receive_packet);

% Select the best parent
parent_selection(id);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function parent_selection(id)
global all_mote sim_params protocol_params;

if id ~= sim_params.base_station
    
    % Unless my current parent is REALLY BAD, I switch to another one
    [r,c]=find(protocol_params.neighbor_list(id).nodeID == all_mote.parent(id));
    if (protocol_params.neighbor_list(id).ack_failed(c) < 3 & protocol_params.neighbor_list(id).time_out(c) > 0)
        % Keep the same parent
        return;
    end
    
    % Find good neighbors greater than threshold
    [r,c]=find(protocol_params.neighbor_list(id).out_est >= protocol_params.neighbor_sel_threshold);
    potential_parents = protocol_params.neighbor_list(id).nodeID(c);
    potential_hops = protocol_params.neighbor_list(id).hop(c);
    potential_out_est = protocol_params.neighbor_list(id).out_est(c);
    
    % Never select nodes which are your children
    if ~isempty(protocol_params.neighbor_list(id).route_parent)
        potential_route_parent = protocol_params.neighbor_list(id).route_parent(c);    
        if ~isempty(potential_route_parent)
            [r,c] = find(potential_route_parent ~= id);
            potential_parents = potential_parents(c);
            potential_hops = potential_hops(c);
            potential_out_est = potential_out_est(c);
        end
    end
    
    % Find the min hop among these good neighbors
    [shortest_hop, shortest_index] = min(potential_hops);
    
    %% find all nodes that have the min hop counts > threshold
    if ~isempty(potential_parents) & shortest_hop ~= +Inf
        [r,c]=find(potential_hops == shortest_hop);
        potential_parents = potential_parents(c);
        potential_out_est = potential_out_est(c);
        [r,c]=max(potential_out_est);
        if ~isempty(c)
            %[a,b]=find(protocol_params.neighbor_list(potential_parents(c)).nodeID==id);
            %if abs(protocol_params.neighbor_list(potential_parents(c)).out_est(b) - r) > 0.5
            %    disp('0.99');    
            %end
            all_mote.parent(id) = potential_parents(c);
            all_mote.hop(id) = shortest_hop + 1;
% COMPILE %    if sim_params.gui_mode, 
% COMPILE %        feval('gui_layer', protocol_params.parent_line_func, id, all_mote.X(id), all_mote.Y(id), ...
% COMPILE %            all_mote.X(all_mote.parent(id)), all_mote.Y(all_mote.parent(id)), ...
% COMPILE %            'Reliability', ['app_lib(''display_reliability'', ' num2str(id) ');']);
% COMPILE %    end;
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_neighbor_list(id, receive_packet)
global protocol_params;

[new, index] = find_neighbor_index(receive_packet.source, protocol_params.neighbor_list(id));

if new
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, receive_packet.parent, ...
        0, 0, ...
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
    save_neighbor_list(id, index, receive_packet.source, receive_packet.hop, receive_packet.parent, ...
        feval(protocol_params.estimator, 'calculate_est', track_info), protocol_params.no_save, ... %calculate_est(track_info), ...
        track_info);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [new, index] = find_neighbor_index(nodeID, neighbor_list)
index = [];
if ~isempty(neighbor_list.nodeID)
    index = find(nodeID == neighbor_list.nodeID);
end
new = 0;
if isempty(index), index = length(neighbor_list.nodeID) + 1; new = 1;, end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function save_neighbor_list(id, index, nodeID, hop, route_parent, out_est, ack_failed, track_info)
global protocol_params
protocol_params.neighbor_list(id).nodeID(index) = nodeID;
if ack_failed ~= protocol_params.no_save, protocol_params.neighbor_list(id).ack_failed(index) = ack_failed;, end;
if hop ~= protocol_params.no_save, protocol_params.neighbor_list(id).hop(index) = hop;, end;
if out_est ~= protocol_params.no_save, protocol_params.neighbor_list(id).out_est(index) = out_est;, end;
if route_parent ~= protocol_params.no_save, protocol_params.neighbor_list(id).route_parent(index) = route_parent;, end;
protocol_params.neighbor_list(id).in_est(index) = 0;

if isempty(protocol_params.neighbor_list(id).track_info)
    protocol_params.neighbor_list(id).track_info = [track_info];
else
    protocol_params.neighbor_list(id).track_info(index) = track_info;
end

protocol_params.neighbor_list(id).time_out(index) = protocol_params.list_time_out;