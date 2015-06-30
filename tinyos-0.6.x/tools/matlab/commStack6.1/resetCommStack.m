function resetCommStack()
%resetCommStack
%
%This function resets everything in the COMM stack
%to make it as if it were freshly created.

%     "Copyright (c) 2000 and The Regents of the University of California.  All rights reserved.
% 
%     Permission to use, copy, modify, and distribute this software and its documentation for any purpose, without fee, and without written agreement 
%     is hereby granted, provided that the above copyright notice and the following two paragraphs appear in all copies of this software.
%     
%     IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING 
%     OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%     THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
%     FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
%     PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
%     
%     Authors:  Kamin Whitehouse <kamin@cs.berkeley.edu>
%     Date:     May 10, 2002 

global COMM

if ~isfield(COMM, 'dataPorts') | length(COMM.dataPorts) == 0
    COMM.dataPorts = instrfind;
end    

if ~isfield(COMM, 'packetPorts') | length(COMM.packetPorts) < length(COMM.dataPorts)
    addPacketPorts(COMM.dataPorts);
else
    if length(COMM.packetPorts) > 0
        for i = 1:length(COMM.packetPorts)
            set(COMM.packetPorts(i), 'packetListeners','');
        end
    end
end

clearPacketBuffers(COMM.packetPorts);

fclose(COMM.dataPorts);
fopen(COMM.dataPorts);