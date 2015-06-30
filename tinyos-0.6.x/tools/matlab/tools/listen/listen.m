function listen(varargin)
%listen(packetPorts | moteIDs,  'verb'/'hex'/'dec', AM_types,  group_IDs)
%
%This function takes a packet port array (or a set of moteIDs) as 
%a parameter and prints out all the packets that they hears.
%
%it filters packet using the AM types and group IDS and moteIDs that you sent it
%
%the display mode can be:
%   1:  'verb'
%   2:  'hex'
%   3:  'dec
%It essentially just adds a packetListener to the ports.
%
%You can also use this event handler to print data
%that comes from an AM handler or router object,
%or anything that generates packet events.

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
%     Authors:  Kamin Whitehouse <kamin@cs.berkeley.edu>
%     Date:     May 10, 2002 

global LISTEN


%if the user sent a set of groupIDs, store them
if length(varargin)>3
    LISTEN.groupIDs=varargin{4};
else
    LISTEN.groupIDs='all';
end

%if the user sent a set of AM types, store them
if length(varargin)>2
    LISTEN.AMs=varargin{3};
else
    LISTEN.AMs='all';
end

%if the user sent a display type
if length(varargin)>1
    LISTEN.displayMode=varargin{2};
else
    LISTEN.displayMode='hex';
end

%if the user sent a packet port or mote iD
if length(varargin)>0
    LISTEN.moteIDs = varargin{1};
else
    LISTEN.moteIDs = 'all';
end

if isnumeric(LISTEN.moteIDs) | strcmpi(LISTEN.moteIDs,'all')
    packetPorts = getPortMapping(LISTEN.moteIDs);
else
    packetPorts = LISTEN.moteIDs;    
    LISTEN.moteIDs='all';
end

addPacketListeners(packetPorts, 'printPacket');