function p = startReprogrammingPacket(dest)
% p=readFragmentPacket(dest, address, src)
% 
% Create a request to read a code fragment from a remote mote. The
% parameters are as follows:
%    dest - which mote should be initialized to accept the new program. -1,
%    65535, and TOS_BCAST correspond to the broadcast address; all motes
%    hearing this message will accept the code fragment
% Note that this function expects that a valid program has been read in, it
% uses the global program id. 

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
    global GROUP_ID;
    global progID;
    global PROGRAMMING_START_REPROGRAMMING;
    global startProgrammingHeader;
    global BIG_ENDIAN;
    
    endianness = BIG_ENDIAN;
    p = packet(startProgrammingHeader);
    p = set(p, 'AM', PROGRAMMING_START_REPROGRAMMING);
    p = set(p, 'address', dest);
    p = set(p, 'groupID', GROUP_ID);
    
    p = set(p, 'progID', progID);
    BIG_ENDIAN = 0;
    % compute the CRC for the packet. 
    foo=toBytes(p);
    p = set(p, 'CRC', docrc(foo(1:(length(foo)-2))));
    BIG_ENDIAN = endianness;