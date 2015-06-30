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
function output=mh_send_retransmit_surge(varargin)
output = feval(varargin{:});

%%
% Intialise this component.
%
%%
function void = initialise(id)
global all_mote ack_miss transmission_queue link_stat retransmit;
transmission_queue{id} = [];
ack_miss(id) = 0;
retransmit.random_delay = 666 * 10; % 10 standard packet time;
%all_mote.link_seqnum(id) = 1;
link_stat.num_retransmit(id) = 0;       % number of retransmit attempted for each node
void = -1;

%% 
% Send packet: when an application need to send a packet, it calls this function
% which deposits the packet into the queue, and transmit if lower level permits.
%%
function void = send_packet(id, app_packet)
global transmission_queue sim_params all_mote

void = -1;
send_packet_queue = transmission_queue{id};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ************************* IMPORTANT ****************************
% Link sequence number should be incremented even for retransmission
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%
% app_seqnum is the number of packets you send. 
% application need this sequence number to keep track of things
% app_packet.link_seqnum = all_mote.link_seqnum(id);
% all_mote.link_seqnum(id) = all_mote.link_seqnum(id) + 1;

% If the queue is empty, can send it right away.
if isempty(send_packet_queue)
    void = feval(sim_params.radio, 'send_packet', id, app_packet);
    if void == 0
        error('Send packet fails because low level is busy... should not happen.');
    end
end
transmit_packet.packet = app_packet;
send_packet_queue = [send_packet_queue transmit_packet];    
transmission_queue{id} = send_packet_queue;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = send_packet_done(id, radio_packet, result)
global sim_params ack_miss protocol_params link_stat transmission_queue retransmit;
% Packet is still in the packet queue but packets that behind this should not call check_idle
% assume radio_packet has the field remembering the number of times a packet can be left to be retransmitted
% insert the next send_packet_ack_pending, if during this time, didn't get an ACK, retransmit
void = -1;

% For broadcast messages, result is ALWAYS 1.  Therefore, no retransmission is required.
if result == 1
    num_retrans = ack_miss(id);
    clean_up_transmission_queue(id);
    feval(sim_params.protocol, 'send_packet_done', id, radio_packet, num_retrans, result);
    return;
else
    ack_miss(id) = ack_miss(id) + 1;
end

if ack_miss(id) < protocol_params.number_of_retransmission;    
    link_stat.num_retransmit(id) = link_stat.num_retransmit(id) + 1;
    ws('insert_event', 'mh_send_retransmit_surge', 'random_delay_retransmit', floor(rand*retransmit.random_delay) , id, {});
else
    num_retrans = ack_miss(id);
    clean_up_transmission_queue(id);
    feval(sim_params.protocol, 'send_packet_done', id, radio_packet, num_retrans, result);    
end


function void=random_delay_retransmit(id)
global sim_params transmission_queue;
app_packet = transmission_queue{id}(1).packet;

void = feval(sim_params.radio, 'send_packet', id, app_packet);
if void == 0
    error('Send packet fails because low level is busy... should not happen.');
end
void = -1;

%%
%  Clean up the transmission queue
%
%  parameters:  id of the sender
%  
%%
function void = clean_up_transmission_queue(id)
global transmission_queue sim_params ack_miss;

void = -1;
ack_miss(id) = 0;
len = length(transmission_queue{id});  % Length of the transmission queue
transmission_queue{id} = transmission_queue{id}(2:len);  % Dequeue

if (len > 1)
    % Transmit the next packet    
    app_packet = transmission_queue{id}(1).packet;
    void = feval(sim_params.radio, 'send_packet', id, app_packet);
    if void == 0
        error('Send packet fails because low level is busy... should not happen.');
    end
end
