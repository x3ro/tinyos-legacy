function p=startSensing()
%p=startSensing()
%
%This function will create a packet to
%start sampling from DATA_CHANNEL
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

global ADC_LED_MASK
global ADC_COMMAND_CODE
global ADC_DATA_CHANNEL
global ADC_DESTINATION
global ADC_MAX_SAMPLES
global ADC_BYTES_PER_SAMPLE
global ADC_RESET_COUNTER
turnOn = 1;

p = commandPacket;
p = set(p, 'ledMask', ADC_LED_MASK);
p = set(p, 'commandCode', ADC_COMMAND_CODE);
p = set(p, 'ADCaction', turnOn);
p = set(p, 'dataChannel', ADC_DATA_CHANNEL);
p = set(p, 'dataDestination', ADC_DESTINATION);
p = set(p, 'maxSamples', ADC_MAX_SAMPLES);
p = set(p, 'bytesPerSample', ADC_BYTES_PER_SAMPLE);
p = set(p, 'resetCounter?', ADC_RESET_COUNTER);