function p2 = packetPort(varargin)
%packetPort is an object that reads bytes from data port and triggers packet events
%it also injects packets by converting them to bytes.
%there is one packetPort object per dataPort
%
%   p = packetPort(dataPort, <packetListeners> <packetType>, <byteBufferSize>, <packetBufferSize>, <timeout>)
%
%The dataPort parameter is a serial port object, a socket or USB object from which bytes can be read
%
%The packetListeners parameter is an array of strings that match the names of the functions
%to be called when a packet is heard.  These functions must be able to take a packetPort and packet parameter
%The default is {} (a cell array of strings, which are the names of the packetListeners)
%
%The packetType is a string that matches the name of the packet type to be parsed.  
%the default is 'TOS_PACKET', although other packet types can be specified, as long
%as the have an 'AM' field.  The 'data' field is parsed automatically given 
%the 'AM' field of the given packet.  If there is no 'AM' or 'data' field of the given
%packet type, then further parsing is not performed.
%
%The byteBufferSize indicates how many bytes to read from the serial port at a time.
%The default is 100 times the number of bytes in packets of type packetMode or 512.
%
%The packetBufferSize indicates how many packets to buffer before triggering an event.
%The default is 1.  This packet buffering is not yet implemented.
%
%If your system is running slow, it may be because of all the event-triggered callbacks
%being made in this section of the commStack.  If so, increase the byteBufferSize or packetBufferSize.
%The higher the number, the faster the processing will be (because there are less callbacks) 
%but the higher your latency might be (because the data is buffered for a while).
%
%the Timeout is a number in seconds.  If the packetBuffer is not full but data has been in there
%for the specified amount of time, the packet event is triggered anyway.  At the moment, this
%feature is not yet implemented.  The default is 10 seconds

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
global PACKET_PORT_STORAGE %this stores the real packet ports.  The stuff passed around
%is just a reference into this array. (simulated pass-by-reference)
%Note that this simulated pass-by-reference could cause serious memory leaks if you create
%and delete a lot of packetPorts
if (length(varargin) > 0) & isa(varargin{1},'packetPort')
   p2 = varargin{1};
   return;
elseif length(varargin)==1 & length(varargin{1})>1 & ~ischar(varargin{1})  
    for i = 1:length(varargin{1})
        p2(i) = packetPort(varargin{1}(i));
    end
    return;
end


%first, check to make sure that this packetPort doesn't already exist
global COMM
sp = varargin{1};%get serialPort
nm=sp(1).name;%get my new name
if isfield(COMM, 'packetPorts')
	for i=1:length(COMM.packetPorts)
        nm2=get(COMM.packetPorts(i),'name');
        if strcmpi(nm, nm2)%make sure nobody else already has this name
            p2 = COMM.packetPorts(i);
            return
        end
	end
end

packetHeaders = getDefaultPacketHeaders;
if ~isempty(packetHeaders)
    headerSize = sum([packetHeaders.size]);
else
    headerSize=36;
end

p2.id=length(PACKET_PORT_STORAGE) + 1;
p2=class(p2, 'packetPort');

p.dataPort = [];                %the dataPort to be listened or written to
p.packetListeners = {};         %the functions to be called when an event is triggered
p.packetType = 'tosHeader';     %the packet type to interpret the incoming data
p.packetLength = headerSize;
p.dataBufferSize = 512;          %the number of bytes to be read at a time
p.packetBufferSize = 1;         %the number of packets to be read before triggering an event
p.timeout = 10;                 %the time before triggering an event
p.packetBuffer = [];            %the buffer that holds new packets (private member variable)
%p=class(p,'packetPort');   %this line of from before we used simulated pass-by-reference


property_argin = varargin;
if(length(property_argin) >5)
   p.timeout = varargin{6};  
end
if(length(property_argin) >4)
   p.packetBufferSize = varargin{5};  
end
if(length(property_argin) >3)
   p.dataBufferSize = varargin{4};  
end
if(length(property_argin) >2)
   p.packetType=varargin{3}; 
end
if(length(property_argin) >1)
   p.packetListeners=varargin{2};
end
if length(property_argin) >0
    p.dataPort = varargin{1};
end

%this must be an if statement because of some weird MATLAB syntax stuff
if length(PACKET_PORT_STORAGE)==0
    PACKET_PORT_STORAGE=p;   %if it is the first packet port
else
    PACKET_PORT_STORAGE(p2.id)=p;   
end


if length(property_argin) > 0  %if this is not just matlab using my constructor to copy an object, set everything right:
	if ~isempty(p.packetType)
        p2 = set(p2,'packetType',p.packetType);
	end
	if ~isempty(p.dataPort)
        p2 = set(p2, 'dataPort', p.dataPort);
    elseif ~isempty(p.dataBufferSize)
        p2 = set(p2,'dataBufferSize', p.dataBufferSize);  
	end
	if ~isempty(p.timeout)
       p2 = set(p2, 'timeout', p.timeout);  
	end
	if ~isempty(p.packetBufferSize)
       p2 = set(p2,'packetBufferSize', p.packetBufferSize);  
	end
	if ~isempty(p.packetListeners)
       p2 = set(p2,'packetListeners', p.packetListeners);  
	end
end