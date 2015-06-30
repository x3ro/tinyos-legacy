function printPacket(packetPort, packet)
%printPacket(packetPort, packet)
%
%This function is a generic packetListener.
%it takes a port and a packet as objects,
%and prints out the packet and the name
%of the port, if there is one.

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

global DEBUG
global GROUP_ID
global DISPLAY_HEX
global LISTEN

if DEBUG
    disp(sprintf('\t\tPort %s generated packet:\n', get(packetPort, 'name')))
end

if length(packet)>1
    for i=1:length(packet)
        printPacket(packetPort, packet(i))
    end
    return
end

AM=get(packet,'AM');
groupID=get(packet,'groupID');
%moteID=get(packet,'srcID');

if groupID==GROUP_ID | sum(groupID==LISTEN.groupIDs)>0 | strcmpi(LISTEN.groupIDs, 'all')
    if sum(AM==LISTEN.AMs)>0  | strcmpi(LISTEN.AMs, 'all')
        %if sum(moteID==LISTEN.moteIDs)>0  | strcmpi(LISTEN.moteIDs, 'all')
            %if HEX mode
            if findstr(LISTEN.displayMode,'h') | findstr(LISTEN.displayMode,'x')
                bytes=toBytes(packet);
                fprintf(1, '%2.2X %2.2X %2.2X %2.2X %2.2X   ',bytes);
                fprintf(1,'\n');
    
            %if DEC mode
             elseif findstr(LISTEN.displayMode,'d')
                bytes=toBytes(packet);
                fprintf(1, '%1d %1d %1d %1d %1d   ',bytes);
                fprintf(1,'\n');
            else %else VERBOSE mode
                disp('-----------------')
                display(packet)
            end
        %end
    end
end