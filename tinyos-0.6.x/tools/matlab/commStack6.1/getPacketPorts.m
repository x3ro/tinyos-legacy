function packetPorts = getPacketPorts(portNames)
%packetPorts = getPacketPorts(portNames)
%
%This function finds packetPorts with the given names, if they exist
%and returns them.

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

if ischar(portNames)
    portNames = {portNames};
end

packetPorts=[];

for i = 1:length(COMM.packetPorts)
    for j = 1:length(portNames)
        pp = get(COMM.packetPorts(i),'dataPort');
        if strcmpi(pp(1).name, portNames{j}) | findstr(pp(1).name, upper(portNames{j}))
            if isempty(packetPorts)
                packetPorts=COMM.packetPorts(i); %this if statement is a stupid hack because I couldn't figure out how to do it in one statement
            else
                packetPorts(end+1)=COMM.packetPorts(i);
            end
        end
    end
end