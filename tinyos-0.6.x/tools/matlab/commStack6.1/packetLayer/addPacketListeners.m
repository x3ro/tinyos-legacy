function packetPorts = addPacketListeners(packetPorts, packetListeners)
%packetPorts = addPacketListener(packetPorts, packetListeners)
%
%This function provides a packet level interface to reading
%from motes in a particular port.
%
%Adds packetListeners to the packetPorts.
%Also configures the dataPort of each packetPort
%to tell it when it receives data and tells
%the dataPort to start reading
%
%A packetListener is any function that takes an object
%and a packet as a parameters, where the object
%is the object that generated the packet,
%e.g. this packetPort.
%

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
%TO DO: 1) add a non-event-driven way to read packets.
%       2) allow people to add the same packetListener twice if they use different parameters



%first, make sure that all parameters are cell arrays of cell arrays


%check the parameter format
if ischar(packetListeners)
    packetListeners = {{packetListeners}};
end

if ~iscell(packetListeners)
    disp('USAGE:  addPacketListeners(p,''listener'')')
    disp('        addPacketListeners(p,{''listener'', param1, param2...})')
    error('        addPacketListeners(p,{{...},{...},...}')
end

if ~iscell(packetListeners{1})
    packetListeners={packetListeners};
end


%then add the listeners, checking for duplicates

for i = 1:length(packetPorts)
    oldListeners = get(packetPorts(i),'packetListeners');
    if length(oldListeners)==0
        %add the first one
        packetPorts(i) = set(packetPorts(i),'packetListeners', {packetListeners{1}});
        oldListeners = get(packetPorts(i),'packetListeners');
    end
    %now check for duplicates
    oldListenerNames={};
    for j=1:length(oldListeners)
        oldListenerNames{end+1}=oldListeners{j}{1};
    end
    for j=1:length(packetListeners)
        if sum(strcmpi(oldListenerNames, packetListeners{j}{1})) ==0
            packetPorts(i) = set(packetPorts(i),'packetListeners', {oldListeners{:} packetListeners{j}});
        end
    end
end