function getID(packetPort) 
% getID(packetPort)
%
% Query a mote for its ID, and display the ID information. It currently
% returns nothing; the relevant information is displayed on screen. 
    
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
%    Date:     May 28, 2002 
    
    global TOS_BCAST_ADDR;
    global TOS_UART_ADDR;
    global packetsExpected;
    global sent;
    p = readFragmentPacket(TOS_BCAST_ADDR, 65520, TOS_UART_ADDR);
    packetsExpected = 1;
    addPacketListeners(packetPort,'reliableDownloadHandler');
    ntries = 8;
    while (packetsExpected == 1) & (ntries > 0)
	sent = clock;    injectPackets(packetPort, p);
	pause(0.5);
	ntries = ntries - 1;
    end
    if ntries <= 0
	disp('Giving up after 8 tries, please check the hardware');
    end
    removePacketListeners(packetPort, 'reliableDownloadHandler');
