%defineClockEnvironment
%
%This file defines the environment needed to interact 
%with the CLOCK component.  
%
%The CLOCK component basically gives you a command
%interface to do set the clock rate of the mote
%
%To send packets to a node running CLOCK, first run this file 
%and then run one of the other functions in this directory.
%This will return a packet, which you can then send
%using any type of injection command

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

global ROOT
addpath([ROOT '/shared/clock'])

global COMMAND_AM_HANDLER
COMMAND_AM_HANDLER=8;            %8 is the AM handler of COMMAND

global CLOCK_LED_MASK
CLOCK_LED_MASK = 240; %240 doesn't effect the LEDS

global CLOCK_COMMAND_CODE
CLOCK_COMMAND_CODE = 7;

global tick1ps
tick1ps = [128 6];

global tick2ps
tick2ps = [128 5];

global tick4ps
tick4ps = [128 4];

global tick8ps
tick8ps = [128 3];

global tick16ps
tick16ps = [64 3];

global tick32ps
tick32ps = [32 3];

global tick64ps
tick64ps = [16 3];

global tick128ps
tick128ps = [8 3];

global tick256ps
tick256ps = [4 3];

global tick512ps
tick512ps = [2 3];

global tick1024ps
tick1024ps = [1 3];

global tick2048ps
tick2048ps = [2 2];

global tick4096ps
tick4096ps = [1 2];

global tick10ps
tick10ps = [102 3];

global tick100ps
tick100ps = [41 2];

global tick1000ps
tick1000ps = [33 1];