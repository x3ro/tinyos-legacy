%defineLogEnvironment
%
%This file defines the environment needed to interact 
%with the LOG component.  
%
%The LOG component allows you to store and retrieve
%data from the log on the mote.  It also allows you to send
%the data to either the UART or the radio.
%
%To send packets to a node running LOG, first run this file 
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
addpath([ROOT '/shared/log'])

global COMMAND_AM_HANDLER
COMMAND_AM_HANDLER=8;            %8 is the AM handler of COMMAND

global LOGGER_LED_MASK
LOGGER_LED_MASK = 2;

global LOGGER_COMMAND_CODE
LOGGER_COMMAND_CODE = 2;

global LOGGER_LINES
LOGGER_LINES = [];
%this could be an array of line numbers

global LOGGER_DESTINATION
LOGGER_DESTINATION = 0; 
%0=UART, 1=radio
