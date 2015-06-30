function writeProgram(packetPort, program) 
% writeProgram(packetPort, program)
% 
% Write broadcast a program to the packetPort. If the node attached to the
% packetPort is a GENERIC_BASE, the program gets rebroadcasted, otherwise
% it is sent only to the node that is connected to that port
    
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
    ncapsules = floor((length(program) + 15) / 16);
    for i=0:(ncapsules-1)
	disp(sprintf('Writing packet %d\r', i));
	p = writeFragmentPacket(TOS_BCAST_ADDR, i, program);
	injectPackets(packetPort, p);
	pause(0.01);
    end
    p = writeFragmentPacket(TOS_BCAST_ADDR, 0, program);
    injectPackets(packetPort, p);
    