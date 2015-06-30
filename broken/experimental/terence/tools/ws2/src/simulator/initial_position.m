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
function initial_position
global all_mote sim_params

style = sim_params.topology_style;
range = sim_params.range;
total_mote = sim_params.total_mote;

if strcmpi(style, 'random')
    all_mote.X = rand(1, total_mote) .* range;
    all_mote.Y = rand(1, total_mote) .* range;
elseif strcmpi(style, 'row_and_column')
    num_in_each = ceil(sqrt(total_mote));
    space = range / num_in_each;
    counter = 1;
    all_mote.X = [];
    all_mote.Y = [];
    for i = 1:num_in_each
        for j = 1:num_in_each
            all_mote.X = [all_mote.X space * i - space/2];
            all_mote.Y = [all_mote.Y space * j - space/2];
            counter = counter + 1;
            if (counter > total_mote)
                generate_dist_matrix;
                return
            end
        end
    end
elseif strcmpi(style, 'line')
    padding = (range / total_mote) / 2;
    space = (range - 2 * padding) / (total_mote - 1);
    all_mote.X = padding + 0:space:(total_mote * space);
    all_mote.Y = range / 2 * ones(1, total_mote);
end
generate_dist_matrix;



function void = generate_dist_matrix
global radio_params all_mote
[x1, x2] = meshgrid(all_mote.X);
diffX = abs(x1 - x2);
[y1, y2] = meshgrid(all_mote.Y);
diffY = abs(y1 - y2);
radio_params.dist_matrix = sqrt(diffX.^2 + diffY.^2);
void = -1;
        

