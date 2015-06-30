function p=botPacket(varargin)
%p=botPacket(varargin)
%
%this function will create a packet.
%You can use this function to do things like: routePacket('all', myPacket)

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
%     Authors:  Sarah Bergbreiter <sbergbre@eecs.berkeley.edu>
%     Date:     June 17, 2002 

global GROUP_ID;
global BIG_ENDIAN;
global BOT_AM;
BOT_AM = 98;

%define the headers of my new packet type to SEND to your mote
%Note that this defines the first field to be address, of size 2 bytes
myCommand(1) = createField('address', 2);  %tosHeader is a group of headers in the general TOS packet.
myCommand(2) = createField('AM', 1);         %It can of course be changed or replaced.
myCommand(3) = createField('groupID', 1);       %To replace, define a new header class and tell the 
myCommand(4) = createField('botData', [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);       %your new field
myCommand(5) = createField('CRC', 2);  %by setting the packetType variable of the packetPort object

%create a packet that has those fields
p=packet(myCommand);

%set the data values on that packet
p=set(p, 'address', 65535);
p=set(p, 'groupID', GROUP_ID);
p=set(p, 'AM', BOT_AM);

p=set(p, 'botData', varargin{1});
%p=set(p, 'botData', [60 148 60 148 60 153 60 158 60 153 60 148 60 143 60 138 60 143 60 148 60 153 60 158 60 153 60 148 60 148]);       % from input to this function

endianness = BIG_ENDIAN;
BIG_ENDIAN = 0;
foo=toBytes(p);
p = set(p, 'CRC', docrc(foo(1:(length(foo)-2))));
BIG_ENDIAN = endianness;
