function checkProgram(packetPort,prog) 
% checkProgram(packetPort, prog) 
%
% Check whether the program prog has been downloaded to the mote connected to
% packetPort. All missing packets are retransmitted until the entire
% program has been acknowled by the mote.  Some of the overall
% functionality still needs work -- loading a bitmap can fail if a mote is
% unresponsive, and that information is not communicated properly to the
% application. 
    
%        
%    "Copyright (c) 2000 and The Regents of the University of California.  All
%    rights reserved. 
%
%    Permission to use, copy, modify, and distribute this software and its 
%    documentation for any purpose, without fee, and without written agreement 
%    is hereby granted, provided that the above copyright notice and the 
%    following two paragraphs appear in all copies of this software. 
%
%    IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY 
%    FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES 
%    ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
%    THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
%    DAMAGE.  
%
%    THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, 
%    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
%    AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
%    IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION
%    TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
%
%    Authors:  Robert Szewczyk <szewczyk@cs.berkeley.edu>
%    Date:     June 1, 2002 

    global TOS_BCAST_ADDR;
    global packetBitmask;
%    p = newProgramPacket(TOS_BCAST_ADDR, prog);
%    injectPackets(packetPort, p);
    
   % writeProgram(packetPort, prog);

    loadBitmap(packetPort, prog);
    sprintf('%02x ', packetBitmask);
    missingPackets = find(packetBitmask ~= 255);
    needsChecking = length(missingPackets);
    while needsChecking ~= 0
	for i = 1:length(missingPackets)
	    for j = ((missingPackets(i)-1)*8):((missingPackets(i)-1)*8)+7
		if ((j*16+1) < length(prog))
		    disp(sprintf('Writing packet %d\r', j));
		
		    p = writeFragmentPacket(TOS_BCAST_ADDR, j, prog);
		    injectPackets(packetPort, p);
		    pause(0.01);
		end
	    end
	end
	p = writeFragmentPacket(TOS_BCAST_ADDR, 1, prog);
	injectPackets(packetPort, p);
	loadBitmap(packetPort, prog);
	sprintf('%02x ', packetBitmask);
	missingPackets = find(packetBitmask ~= 255);
	needsChecking = length(missingPackets);
    end