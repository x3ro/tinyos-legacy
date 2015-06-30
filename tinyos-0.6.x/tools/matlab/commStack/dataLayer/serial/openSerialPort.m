function s=openSerialPort(port)
%s=openSerialPort(port)
%
%This function takes the name of a serial port or a cell array of names
%e.g. 'COM1'  or {'COM1' 'COM2'} and opens it for read/write.
%
%It sets the important parameters need for TOS environments.
%All other parameters are also explicitly set
%so that you can change them if you want to, 
%or change them after you get your handle to the serial port object.
%If there are several options, all are listed and all but one are commented out.
%
%Currently, if DEBUG is set to TRUE then eventhandlers are called when the input 
%buffer fills up, when the output buffer becomes empty, or when an error occurs
%
%TO DO: write a wrapper class that envolopes this interface for socket and USB data ports

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

global DEBUG

serialPorts = instrfind;
if ~isempty(serialPorts)
    serialPortNames = serialPorts.name;
else
    serialPortNames={};
end
if ~iscell(serialPortNames)
    serialPortNames = {serialPortNames};
end

if ischar(port)
    port = {port};
end
for i = 1:length(port)
    alreadyExists=0;
    for name=1:length(serialPortNames)
        if strcmpi(serialPortNames{name}, ['serial-' upper(port{i})])
            s(i) = serialPorts(name);
            alreadyExists=1;
        end
    end
    if alreadyExists
        continue
    end
	s(i) = serial(port{i});
	s(i).BaudRate = 19200;
	s(i).FlowControl = 'none';

    s(i).InputBufferSize = 36;
	s(i).OutputBufferSize = 36;
	
	%s.ReadAsyncMode = 'manual';    %read data only when I say fread or readasync
	s(i).ReadAsyncMode = 'continuous'; %read data all the time and store in a buffer
	
	s(i).Timeout = 10; %seconds
	
	if DEBUG
        %s.BytesAvailableActionMode = 'terminator'; %trigger an even whenever a terminator symbol is received
        s(i).BytesAvailableFcnMode = 'byte'; %trigger an even whenever a certain number of bytes are received
        s(i).BytesAvailableFcnCount = s(i).InputBufferSize;  %indicated the number of bytes
        s(i).BytesAvailableFcn = 'bytesAvailableEventHandler';         %specifies the action to be called when bytes are available
	
        s(i).OutputEmptyFcn = 'outputBufferEmptyEventHandler'; %specifies the action to take when the output buffer becomes empty
	
        s(i).ErrorFcn = 'serialPortErrorEventHandler';  %specifies the action to take when an error occurs
	end
	
	fopen(s(i));
end
