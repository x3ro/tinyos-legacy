function p=readLog()
%p=readLog()
%
%This function will create a packet to
%read your log at LOGGER_LINES
%if your mote is running the COMMAND component
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

global LOGGER_LED_MASK
global LOGGER_COMMAND_CODE
global LOGGER_LINES
global LOGGER_DESTINATION

p = commandPacket;
p = set(p, 'ledMask', LOGGER_LED_MASK);
p = set(p, 'commandCode', LOGGER_COMMAND_CODE);
for i = 1:length(LOGGER_LINES)
    p = set(p, ['lines' num2str(i)], LOGGER_LINES(i));
end
p = set(p, 'dataDestination', LOGGER_DESTINATION);