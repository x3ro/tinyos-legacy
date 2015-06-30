function p =tofChirpCommand(varargin)
%p =tofChirp(numChirps, moteID, context)
%
%This packet will make a mote with TOF_RANGING install chirp
%a packet and sound at the same time
%
%Adjust the relevant global parameters listed below before calling this function.

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

global TOS_BCAST_ADDR
global TOF_RANGING_CHIRP_AM_HANDLER
global GROUP_ID
global TOF_RANGING_COMMAND             %this is the msgType to send to a mote if you want it to chirp
global TOF_RANGING_RANGING             %this is the msgType to send to a mote if you want it to chirp

if length(varargin)>2
    context=varargin{3};
else
    context=TOF_RANGING_RANGING;
end

if length(varargin)>1
    destination=varargin{2};
else
    destination=TOS_BCAST_ADDR;
end

if length(varargin)>0
    numChirps=varargin{1};
else
    numChirps=255;  %this tells it to chirp forever
end

p = packet(getDefaultPacketHeaders);                 %first add the tos headers
p = addField(p, getAMHeaders(TOF_RANGING_CHIRP_AM_HANDLER));        %then add my headers
p = set(p,'address', destination);       %and set their values correctly for a command packet
p = set(p,'AM', TOF_RANGING_CHIRP_AM_HANDLER);
p = set(p,'groupID', GROUP_ID);
p = set(p,'msgType', TOF_RANGING_COMMAND);
p = set(p,'context', context);
p = set(p,'chirpNumber', numChirps);