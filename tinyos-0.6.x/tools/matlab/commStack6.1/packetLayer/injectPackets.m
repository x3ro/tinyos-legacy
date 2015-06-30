function injectPackets(packetPorts, packets)
%injectPackets(packetPorts, packets)
%
%This function takes a list of packetPorts and a list of packets
%and writes them all in little-endian format to the mote.
%
%This provides a packet-level interface to writing to motes.
%
%Note that the packet-level interace to reading from motes is
%event driven.

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

%TO DO: add a non-event driven read packets function

global BIG_ENDIAN
endianness = BIG_ENDIAN;
BIG_ENDIAN=0;

for j=1:length(packets)
    %insert the CRC bytes.  This assumes that the last two bytes of the packet are CRC bytes
    bytes=toBytes(packets(j));
%    packets(j) = set(packets(j), 'CRC', docrc(bytes(1:end-2)));
    for i=1:length(packetPorts)
        dataPort =get(packetPorts(i),'dataPort');
        write(dataPort(1), bytes);
    end
end

BIG_ENDIAN=1;
