function p = newProgramPacket(dest, program) 
% p = newProgramPacket(dest, program)
%    
% Create a packet which initializes a mote for network
% reprogramming. Parameters are:
%    dest - which mote should be initialized to accept the new program. -1,
%    65535, and TOS_BCAST correspond to the broadcast address; all motes
%    hearing this message will accept the new program
%    
%    program - array which contains the actual code to be downloaded to the
%    mote. This array is created with readSrec function. 
% NOTE: at the moment, there is a global progID variable, so only a single
% reprogramming can be occuring within matlab session at a time. In order
% for this function to work, you MUST use readSrec to read in the code
% array to properly initialize the global state.
    
    
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
    global progID
    global newProgramHeader;
    global PROGRAMMING_NEW_PROGRAM;
    global BIG_ENDIAN;
    endianness = BIG_ENDIAN;
    %tosHeader is a group of headers in the general TOS packet.
    
    p = packet(newProgramHeader); 
    p = set(p, 'AM', PROGRAMMING_NEW_PROGRAM);
    p = set(p, 'address', dest);
    p = set(p, 'groupID', GROUP_ID);
    p = set(p, 'length', length(program));
    p = set(p, 'progID', progID);
    BIG_ENDIAN = 0;
    foo=toBytes(p);
    p = set(p, 'CRC', docrc(foo(1:(length(foo)-2))));
    BIG_ENDIAN = endianness;