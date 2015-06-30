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
addpath([ROOT '/shared/oscope'])

global COMMAND_AM_HANDLER
COMMAND_AM_HANDLER=8;            %8 is the AM handler of COMMAND

global OSCOPE_AM_HANDLER
OSCOPE_AM_HANDLER=10;            %8 is the AM handler of COMMAND

global ADC_LED_MASK
ADC_LED_MASK = 1;

global ADC_COMMAND_CODE
ADC_COMMAND_CODE = 1;

global ADC_DATA_CHANNEL
ADC_DATA_CHANNEL = 1;   
%0 = RF Signal Strength
%1 = photo, etc

global ADC_DESTINATION
ADC_DESTINATION = 0;    
%0=packet to UART
%1 = raw data to UART
%2 = packet to BCAST

global ADC_MAX_SAMPLES
ADC_MAX_SAMPLES = 0;
%0 = infinite number of samples
%x = collect x samples

global ADC_BYTES_PER_SAMPLE
ADC_BYTES_PER_SAMPLE = 0;
%0 = 2 bytes per sample
%x = x bytes per sampz`le

global ADC_RESET_COUNTER
ADC_RESET_COUNTER = 1;
%1 = reset counter
%0 = don't reset counter

oscopeDataHeader(1)= createField('moteID', 2);
oscopeDataHeader(2)= createField('lastReadingNumber', 2);
oscopeDataHeader(3)= createField('dataChannel', 2);
oscopeDataHeader(4)= createField('samples', [2 2 2 2 2 2 2 2 2 2]);
addAMHeaders(OSCOPE_AM_HANDLER, oscopeDataHeader);