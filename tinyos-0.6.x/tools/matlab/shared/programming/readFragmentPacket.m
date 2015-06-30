function p = readFragmentPacket(dest, address, src)
% p=readFragmentPacket(dest, address, src)
% 
% Create a request to read a code fragment from a remote mote. The
% parameters are as follows:
%    dest - which mote should be initialized to accept the new program. -1,
%    65535, and TOS_BCAST correspond to the broadcast address; all motes
%    hearing this message will accept the code fragment
%
%    address - starting address of the code fragment to be included. The
%    address is specified in capsule numbers, and is 0 based. Address 0
%    corresponds to code at byte addresses from 0 ro 15; address 1
%    corresponds to code at byte addresses from 16 to 31, and so forth. 
%    
%    src - address of the mote that should receive the reply. If the mote
%    is to reply over the serial port, this should be set to 126 (0x7e,
%    TOS_UART_ADDRESS). If it is to be received by the regular generic
%    base, then it should be the address of the generic base. 
% 
% Note that this function expects that a valid program has been read in.

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
    global readFragmentHeader;
    global PROGRAMMING_READ_FRAGMENT;
    global BIG_ENDIAN;
    endianness = BIG_ENDIAN;
    p = packet(readFragmentHeader);
    p = set(p, 'AM', PROGRAMMING_READ_FRAGMENT);
    p = set(p, 'address', dest);
    p = set(p, 'groupID', GROUP_ID);
    
    p = set(p, 'progID', progID);
    p = set(p, 'capsule', bitand(address, 65535));
    p = set(p, 'src', src);
    BIG_ENDIAN =0;
    % compute the CRC for the packet. 
    foo=toBytes(p);
    p = set(p, 'CRC', docrc(foo(1:(length(foo)-2))));
    BIG_ENDIAN = endianness;