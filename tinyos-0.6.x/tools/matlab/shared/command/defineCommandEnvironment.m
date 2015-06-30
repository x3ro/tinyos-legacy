%defineCommandEnvironment
%
%This file defines the environment needed to interact 
%with the COMMAND component.  
%
%The COMMAND component basically gives you a command
%interface to do some low level stuff with the 
%effectors on the node, such as the radio or sounder.
%
%To send packets to a node running COMMAND, first run this file 
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

%TO DO: put all these globals in a COMMAND ENVIRONMENT structure
global ROOT
addpath([ROOT '/shared/command'])

global COMMAND_AM_HANDLER
COMMAND_AM_HANDLER=8;            %8 is the AM handler of COMMAND

commandHeader(1)= createField('ledMask', 1);
commandHeader(2)= createField('commandCode',1);
addAMHeaders(COMMAND_AM_HANDLER, commandHeader);

global LED_COMMAND_CODE             %each command has an LED mask that sets the LEDs if the command is successful
LED_COMMAND_CODE = 0;

global RADIO_LED_MASK               %it also has a command code that allows the packet and it's arguments to be interpreted
RADIO_LED_MASK = 4;

global RADIO_COMMAND_CODE
RADIO_COMMAND_CODE = 4;

global RADIO_POT_SETTING
RADIO_POT_SETTING = 76;

global JAM_LED_MASK
JAM_LED_MASK = 5;

global JAM_COMMAND_CODE
JAM_COMMAND_CODE = 5;

global SOUNDER_LED_MASK
SOUNDER_LED_MASK = 6;

global SOUNDER_COMMAND_CODE
SOUNDER_COMMAND_CODE = 6;

global MICROPHONE_LED_MASK
MICROPHONE_LED_MASK = 6;

global MICROPHONE_COMMAND_CODE
MICROPHONE_COMMAND_CODE = 6;

