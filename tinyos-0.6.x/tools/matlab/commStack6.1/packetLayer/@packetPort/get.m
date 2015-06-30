function val = get(p2,prop_name)
% GET Get properties from the specified object
% and return the value

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

if length(p2)>1
    for i=1:length(p2)
        val(i)=get(p2(i), prop_name);
    end
    return;
end

global PACKET_PORT_STORAGE  %these two lines go at the beginning of every packetPort function(simulated pass-by-reference
p = PACKET_PORT_STORAGE([p2.id]);

switch prop_name
case 'name'
   val= p.dataPort(1).name;                %the dataPort to be listened or written to
case 'dataPort'
   val= p.dataPort;                %the dataPort to be listened or written to
case 'packetListeners'
    val=p.packetListeners;         %the functions to be called when an event is triggered
case 'packetType'
    val=p.packetType;     %the packet type to interpret the incoming data
case 'packets'
    val=p.packetBuffer;     %the packet type to interpret the incoming data
case 'packetLength'
    val=p.packetLength;     %the packet type to interpret the incoming data
case 'dataBufferSize'
    val=p.dataBufferSize;          %the number of bytes to be read at a time
case 'packetBufferSize'
    val=p.packetBufferSize;          %the number of bytes to be read at a time
case 'timeout'
    val=p.timeout;                 %the time before triggering an event
case 'packetBuffer'
val = p.packetBuffer;                 %the time before triggering an event
otherwise
    error([prop_name,' Is not a valid dataset property'])
end


%PACKET_PORT_STORAGE([p2.id])=p;   %this line goes at the end of every packetPort function, now (simulated pass-by-reference)
