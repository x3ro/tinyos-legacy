function p2 = set(p2,varargin)
% SET Set properties of the packetPort and return the updated object

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

if length(p2)>1
    for i=1:length(p2)
        p2(i)=set(p2(i), varargin{:});
    end
    return;
end

global DEFAULT_DATA_BUFFER_SIZE
global PACKET_PORT_STORAGE  %these two lines go at the beginning of every packetPort function(simulated pass-by-reference
p = PACKET_PORT_STORAGE([p2.id]);

property_argin = varargin;
while length(property_argin) >= 2,
    prop = property_argin{1};
    val = property_argin{2};
    property_argin = property_argin(3:end);
    switch prop
    case 'dataPort'
% 		val.BytesAvailableFcn = {'data2packets',p2};
 		val(1).setMaxBufferSize(p.packetBufferSize);             
% 		val.BytesAvailableFcnCount = p.dataBufferSize;             
        p.dataPort = val;
    case 'packetListeners'
        p.packetListeners = val;         %the functions to be called when an event is triggered
    case 'packetType'
        p.packetType = val;     %the packet type to interpret the incoming data
		pkt = packet(getPacketHeaders(p.packetType));
		fields = get(pkt, 'field');
        p.packetLength = sum([fields.size]);
        p.dataBufferSize = DEFAULT_DATA_BUFFER_SIZE*p.packetLength;          %the number of bytes to be read at a time is by default the header size
    case 'packets'
        p.packetBuffer=val;     %the packet type to interpret the incoming data
    case 'packetLength'
        p.packetLength=val;     %the packet type to interpret the incoming data
    case 'dataBufferSize'
        p.dataBufferSize = val;          %the number of bytes to be read at a time
    case 'packetBufferSize'
        p.packetBufferSize = val;          %the number of bytes to be read at a time
        if ~isempty(p.dataPort)
            p.dataPort(1).setMaxBufferSize(val);
        end
    case 'timeout'
        p.timeout = val;                 %the time before triggering an event
    case 'packetBuffer'
        p.packetBuffer = val;                 %the time before triggering an event
    otherwise
        error('I dont understand your parameters')
    end
end

PACKET_PORT_STORAGE([p2.id])=p;   %this line goes at the end of every packetPort function, now (simulated pass-by-reference)

