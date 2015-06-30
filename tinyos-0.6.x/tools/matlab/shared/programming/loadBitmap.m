function loadBitmap(packetPort,prog) 
% loadBitmap(packetPort, prog) 
%   
% Load the bitmap of packets corresponding to the received/missing code
% fragments from program prog.  It returns nothing, but it changes the
% global array packetBitmask, and in the event of failure it displays error
% messages.
    
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
    
    
    nelements = ceil(length(prog) / (16 * 16 * 8)); % number of bitmap
                                                    % packets we need to
    global packetsExpected;
    global TOS_BCAST_ADDR;
    global TOS_UART_ADDR;
    global packetBitmask;
    global sent;
    packetBitmask = char(zeros(nelements*16, 1));
    addPacketListeners(packetPort, 'reliableDownloadHandler');
    for i=8192:(8192+nelements-1)
	p = readFragmentPacket(TOS_BCAST_ADDR, i, TOS_UART_ADDR);
	packetsExpected = 1;
	ntries = 8;
	while (packetsExpected == 1) & (ntries > 0)
	    sent = clock; injectPackets(packetPort, p);
	    ntries = ntries - 1;
	    pause(0.1);
	end
	if (ntries == 0)
	    disp('Failed after 8 attempts; check hardware');
	end
    end
    removePacketListeners(packetPort, 'reliableDownloadHandler');
    