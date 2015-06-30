function packets = readPackets(MatlabDataPort, varargin)
%data2packets(MatlabDataPort, <packetPort>, <bytes>)
%
%This function reads bytes from the dataPort and parses them into packets.  
%
%If a packetPort is passed as a parameter, the packets are stored in the packetPort.
%If a matrix of bytes is passed, it is used instead of bytes read from the dataPort
%
%the 'data' field of the packets is parsed according to the headers that were
%registered for the AM byte in the 'AM' field of the packet
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

%first, get the bytes to parse.  Either from the command line parameters or
%from the dataPort that was passed as a parameter
if length(varargin)>1
    bytes=varargin{2};
else
    bytes = MatlabDataPort.getPacketBuffer;
    bytes=double(bytes);
    bytes = bytes(strmatch(START_SYMBOL_BYTES,bytes),:);
end

%change to little endian mode so we can deal with raw bytes from the motes
global BIG_ENDIAN
endianness = BIG_ENDIAN;
BIG_ENDIAN = 0;
global COMM

%create the packets with the received bytes
%first add the default headers and then add the payload headers using the AM type
packets=packet;
for i=1:size(bytes,1)
	packets(i) = packet(COMM.defaultHeaders);
	packets(i) = addField(packets(i), getAMHeaders(bytes(i,COMM.defaultHeadersAMbytePosition)));  
	packets(i) = setBytes(packets(i), bytes(i,:));
end

%change your endianness back
BIG_ENDIAN = endianness;

%figure out if there are any packet event listeners and, if there are,
%pass them the new packets
listeners='';
if length(varargin)>0
    packetPort=varargin{1};
    listeners = get(packetPort,'packetListeners');
    set(packetPort, 'packets', packets);
    if length(listeners)>=1
    	%finally send the parsed packet to everybody who is registered as a listener to it
		for i = 1:length(listeners)
            methodInfo = listeners{i};
            eval([methodInfo{1} '(packetPort, packets, methodInfo{2:end})']);
		end
    end
end