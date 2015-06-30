function reliableDownloadHandler(packetPort, packet)
% reliableDownloadHandler(packetPort, packet)
% 
% a handler for the reliable program download to the mote. It is designed
% to recognize moteID-related packets, and bitmask-related packets, and act
% on them. Currently written to deal with a sigle port at a time; I'm not
% sure what the results would be for a multiport call (ID would work,
% bitmap would fail at this point)

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
    global packetsExpected;
    global packetBitmask;
    global arrived;
    global sent;
    global timeDiff;
    global PROGRAMMING_WRITE_FRAGMENT;
    PROGRAMMING_MAX_CAPSULES = 8192;
    am = get(packet, 'AM');
    arrived = clock;
    timeDiff= (arrived -sent) * [0 0 0 3600 60 1]';
    disp(timeDiff);
    if am == PROGRAMMING_WRITE_FRAGMENT 
	code = get(packet,'code');
	    disp(sprintf('%02x ', code));
	capsuleNo = get(packet, 'capsule');
	if (capsuleNo == (65535 - 15))
	    cid = code(1) + code(2)*256;
	    disp(sprintf('Mote id %d', cid));
	    packetsExpected = packetsExpected - 1;
	end
	if ((capsuleNo >= PROGRAMMING_MAX_CAPSULES) & ...
	    (capsuleNo < PROGRAMMING_MAX_CAPSULES+(length(packetBitmask)/16))) 
	    start = (capsuleNo-PROGRAMMING_MAX_CAPSULES)*16 + 1
	    packetBitmask(start:start+15) = code;
	    packetsExpected = packetsExpected -1;
	end
	
    end
    