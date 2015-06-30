%defineOscopeEnvironment
%
%This file defines the environment needed to interact 
%with the OSCOPE component.  
%
%The OSCOPE component is like having an oscilloscope
%on the mote; it allows you to observe the values of
%certain pins.  If you know the pins that your 
%sensor is connected to, you can monitor the output
%of your sensor.  Channel 0 is radio signal strength,
%channel 1 is often photo sensor, etc.
%
%You have the option of sending the data to the 
%UART, the log, or the radio.
%
%To send packets to a node running OSCOPE, first run this file 
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
addpath([ROOT '/shared/programming'])

global progID;
progID = 1;

global PROGRAMMING_NEW_PROGRAM;
PROGRAMMING_NEW_PROGRAM = 47;
global newProgramHeader;
tmpHeader = [];
clear tmpHeader;
tmpHeader(1) = createField('address', 2); 
tmpHeader(2) = createField('AM', 1);     
tmpHeader(3) = createField('groupID', 1);
tmpHeader(4) = createField('progID', 2); 
tmpHeader(5) = createField('length', 2);
tmpHeader(6) = createField('padding', 26);
tmpHeader(7) = createField('CRC', 2);
newProgramHeader = tmpHeader;
addAMHeaders(PROGRAMMING_NEW_PROGRAM, newProgramHeader(4:6));

global PROGRAMMING_START_REPROGRAMMING;
PROGRAMMING_START_REPROGRAMMING = 48;
global startProgrammingHeader;
clear tmpHeader;
tmpHeader(1) = createField('address', 2); 
tmpHeader(2) = createField('AM', 1);     
tmpHeader(3) = createField('groupID', 1);
tmpHeader(4) = createField('progID', 2); 
tmpHeader(5) = createField('padding',28); 
tmpHeader(6) = createField('CRC', 2);
startProgrammingHeader = tmpHeader;
addAMHeaders(PROGRAMMING_START_REPROGRAMMING, startProgrammingHeader(4:5));

global PROGRAMMING_WRITE_FRAGMENT;
PROGRAMMING_WRITE_FRAGMENT = 49;
global writeFragmentHeader;
clear tmpHeader;
tmpHeader(1) = createField('address', 2); 
tmpHeader(2) = createField('AM', 1);     
tmpHeader(3) = createField('groupID', 1);
tmpHeader(4) = createField('progID', 2); 
tmpHeader(5) = createField('capsule', 2);
tmpHeader(6) = createField('code', ones(1,16));
% unused padding field, this is where we could insert things like a
% digital signature.
tmpHeader(7) = createField('padding',10); 
tmpHeader(8) = createField('CRC', 2);
writeFragmentHeader = tmpHeader;
addAMHeaders(PROGRAMMING_WRITE_FRAGMENT, writeFragmentHeader(4:7));

global PROGRAMMING_READ_FRAGMENT;
PROGRAMMING_READ_FRAGMENT = 50;
global readFragmentHeader;
clear tmpHeader;
tmpHeader(1) = createField('address', 2); 
tmpHeader(2) = createField('AM', 1);     
tmpHeader(3) = createField('groupID', 1);
tmpHeader(4) = createField('progID', 2); 
tmpHeader(5) = createField('capsule', 2);
tmpHeader(6) = createField('src', 2);
% unused padding field, this is where we could insert things like a
% digital signature.
tmpHeader(7) = createField('padding',24); 
tmpHeader(8) = createField('CRC', 2);
readFragmentHeader = tmpHeader;
addAMHeaders(PROGRAMMING_READ_FRAGMENT, readFragmentHeader(4:7));


global packetBitmask;
packetBitmask = char(zeros(1024,1));
global packetExpected;
packetExpected = 0;

% other useful globals:
global sent;
sent = clock;
global arrived;
arrived = clock;

global timeDiff;
timeDiff = 0;