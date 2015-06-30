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

function sim_settings
global sim_params;

% Standard simulation settings
sim_params.total_mote = 100;                   % number of motes to simulate
sim_params.range = 80;                       % dimension of the grid (assuming square)
sim_params.simulation_duration = 100000*2000; % 1 sec == 100000 sim_time
sim_params.base_station = 1;                 % base station ID
sim_params.gui_mode = 1;                     % 0 means NO gui mode (may change later)
sim_params.topology_style = 'row_and_column'; % choices: line, row and column, random

% start array parameters
sim_params.start_predefined = 1;             % 1 = a file specific predefined start time for each mote
sim_params.start_predefined_file = 'defaults\100start';  % path of that file
sim_params.random_start_range = 10*100000;      % if start time is generated randomly,
                                               % this specifies the range of randomness (100000 == 1 sec)

% time series setting
sim_params.time_series_tick = 100000;
