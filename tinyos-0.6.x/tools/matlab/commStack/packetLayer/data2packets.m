function data2packets(s, event, packetPort)
%data2packets(s, event, packetPort)
%
%%%%THis implementation was made to read variable length packets!!
%%%%it is also an old inefficient method of start symbol searching
%%%% overall, inefficient!!!
%
%this function is called when a dataPort fills it's buffer.  
%
%the function searches for the start symbol (which is an array of bytes) 
%and then reads all the bytes and interprets them as a packet.
%
%the 'data' field is parsed according to the headers that were
%registered for the AM byte in the 'AM' field of the packet
%
%the function then assures that more data will be read, even if we are in manual mode.

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
if s.BytesAvailable==0
    return
end
%Instead of doing the following, we should probably just tell the serial port to stop triggering this function on byte arrival
listeners = get(packetPort,'packetListeners');
if length(listeners)<1
    flushinput(get(packetPort, 'dataPort'));
    return
end

global START_SYMBOL_BYTES
global START_SYMBOL_SIZE            %the number of bytes in the start symbol
global BIG_ENDIAN
%global DEBUG    %You might not want to see all the actual data if you are trying to debug (it goes by so fast that everything on the screen flies by
global COMM

endianness = BIG_ENDIAN;
BIG_ENDIAN = 0;

bytes = [s.UserData fread(s,s.BytesAvailable, 'uchar')'];
bufferLength = length(bytes);

index = 1;
bytesFound = 0;

%while we have enough bytes buffered to possibly complete an entire packet
while bufferLength-index+1 >= COMM.defaultHeaderSize
    
    %keep looking through the bytes until you found all the start bytes
    while bytes(index + bytesFound) == START_SYMBOL_BYTES(bytesFound+1)                    %until one matches the start symbol
        bytesFound = bytesFound + 1;                                %Indicate that we found another peice of the startSymbol
        if bytesFound == START_SYMBOL_SIZE
            
            %once you found the start bytes, create the header of the packet
            data = bytes(index:index+COMM.defaultHeaderSize-1);
            pkt = packet(COMM.defaultHeaders);
            pkt = addField(pkt, getAMHeaders(data(COMM.defaultHeadersAMbytePosition)));  
            pkt = setBytes(pkt, data);

            %finally send the parsed packet to everybody who is registered as a listener to it
            for i = 1:length(listeners)
                methodInfo = listeners{i};
                eval([methodInfo{1} '(packetPort, pkt, methodInfo{2:end})']);
            end
            
            %If DEBUG==1, print the packet
% 			if DEBUG==1
%                 pkt
%             end
           
            bytesFound=0;                                           %reset the startsymbol detection 
            index = index+COMM.defaultHeaderSize-3;                           %set the index one packet-length ahead (I actually subtract 2 more than I should here because sometimes a packet is missing a byte or two and I don't want to miss the next one, so I backtrack a little bit.
            break;
        end
    end
    index = index + bytesFound + 1;  %if the start symbol wasn't found, increment index
    bytesFound = 0; %and reset the start symbol detection
end

s.UserData = bytes(index:end);          %store the unused bytes for later use (for some reason this temporary holdover stuff doesn't work sometimes and we see a missing bit somewhere!!!  FIX IT!)
% if strcmp(s.ReadAsyncMode,'manual')                    %If the serial port is in manual mode
%     stopasync(s);                                       %stop it from reading
%     readasync(s, s.InputBufferSize - s.BytesAvailable); %try to read more data
% end
BIG_ENDIAN = endianness;
