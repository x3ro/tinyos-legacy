%defineTOSEnvironment
%
%This file should be run before working in the TOS/matlab environment
%
%It defines all the global variables and standard stuff needed for working with TOS
%
%Note that BIG_ENDIAN=1 is the way we usually read bytes (left-most byte
%is most significant).
%BIG_ENDIAN=0 is the way the mote reads and write bytes.
%This flag only concerns how the users sees the displayed bytes.
%bytes read and written to the mote are always little-endian.
%Both big-endians and little-endians agree that the left-most
%bits within a byte are most significant.

% "Copyright (c) 2000 and The Regents of the University of California.  All rights reserved.
% Permission to use, copy, modify, and distribute this software and its documentation for any purpose, 
% without fee, and without written agreement is hereby granted, provided that the above copyright notice 
% and the following two paragraphs appear in all copies of this software.
% 
% IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, 
% INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
% EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED 
% HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
% PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
% 
% Authors:  Kamin Whitehouse <kamin@cs.berkeley.edu>
% Date:     May 10, 2002

global DEBUG                        %if this is 1 then debug info comes out
DEBUG = 0;

global BIG_ENDIAN                   %defines how byte strings are printed
BIG_ENDIAN = 1;

global DISPLAY_HEX                  %defines how bytes are printed
DISPLAY_HEX=0;

global DEFAULT_PACKET_LENGTH        %defines the default packet length.
DEFAULT_PACKET_LENGTH = 36;

global START_SYMBOL                 %conventional symbol to look for starting a packet
START_SYMBOL =126;

global START_SYMBOL_SIZE            %the number of bytes in the start symbol
START_SYMBOL_SIZE = 2;

global START_SYMBOL_BYTES
%START_SYMBOL_BYTES = toBytes(START_SYMBOL, START_SYMBOL_SIZE);

global TOS_BCAST_ADDR               %conventional broadcast address
TOS_BCAST_ADDR = 65535;

global TOS_UART_ADDR                %conventional UART address
TOS_UART_ADDR = 126;

global GROUP_ID                     %GROUP ID for this set of nodes (used for sending packets, but could also be used for filtering packets)
GROUP_ID = 125;

global ROOT                         %the root directory of the matlab files
ROOT = pwd;

global DEFAULT_DATA_BUFFER_SIZE
DEFAULT_DATA_BUFFER_SIZE=1;

addpath(ROOT);                      %add all core matlab directories to the path.
addpath([ROOT '/util']);
addpath([ROOT '/tools/listen']);
addpath([ROOT '/tools/watch']);
addpath([ROOT '/tools/watchFreq']);
%addpath([ROOT '/tools/3Dwatch']);
addpath([ROOT '/tools/surfaceWatch']);
addpath([ROOT '/commStack6.1']);
addpath([ROOT '/commStack6.1/packetLayer']);
addpath([ROOT '/commStack6.1/AMLayer']);
addpath([ROOT '/commStack6.1/routingLayer']);
addpath([ROOT '/commStack6.1/routingLayer/portMap']);

endianness = BIG_ENDIAN;
BIG_ENDIAN=0;
START_SYMBOL_BYTES = toBytes(START_SYMBOL, START_SYMBOL_SIZE);
BIG_ENDIAN = endianness;

tosHeader(1) = createField('address', 2);  %tosHeader is a group of headers in the general TOS packet.
tosHeader(2) = createField('AM', 1);         %It can of course be changed or replaced.
tosHeader(3) = createField('groupID', 1);       %To replace, define a new header class and tell the 
%tosHeader(3) = createField('length', 1);       %length of the payload
tosHeader(4) = createField('data', [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);         %bytes2packet function to use the new class of headers
tosHeader(5) = createField('CRC', 2);  %by setting the packetType variable of the packetPort object
addPacketHeaders('tosHeader', tosHeader);
defineDefaultPacketHeaders('tosHeader');


defineWatchEnvironment;
%defineWatch3DEnvironment;
defineWatchSurfaceEnvironment;
defineWatchFreqEnvironment;
definePortMapEnvironment;
