function p=setClockRate(varargin)
%p=setClockRate(tickRate)
%
%This function will create a packet to
%go into SLEEP_MODE
%if your mote is running the COMMAND component
%Adjust the relevant global parameters listed below before calling this function.
%
%possible values of tickRate are 1, 2, 4, 8, 16, 32, 63, ....4096, 10, 100, 1000

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

global CLOCK_LED_MASK
global CLOCK_COMMAND_CODE

tickRate = 32; %default is 32 times per second
if length(varargin)>0
    tickRate = varargin{1};
end

eval(['global tick' num2str(tickRate) 'ps']);
eval(['clockSettings = tick' num2str(tickRate) 'ps;']);
    
p = commandPacket;
p = set(p, 'ledMask', CLOCK_LED_MASK);
p = set(p, 'commandCode', CLOCK_COMMAND_CODE);
p = set(p, 'clockSetting1', clockSettings(1));
p = set(p, 'clockSetting2', clockSettings(2));
