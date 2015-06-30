function serialPorts = clearBuffers(serialPorts)
%serialPort = clearBuffers(serialPorts)
%
%This function clears the buffers of the matlab serial port objects and then clears the buffer
%of the actual serial ports, which also might have buffered data.
%make sure that nothing is sending data to this serial port
%before you try to clear the buffers (otherwise it will never terminate)

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

for i=1:length(serialPorts)
	dataListener = serialPorts(i).BytesAvailableAction;
	serialPorts(i).BytesAvailableAction = '';
	readMode= serialPorts(i).ReadAsyncMode;
	serialPorts(i).ReadAsyncMode = 'continuous';
	while serialPorts(i).BytesAvailable > 0
        data = fread(serialPorts(i), serialPorts(i).BytesAvailable, 'uchar');
        %stopasync(serialPorts(i));                                       %stop it from reading
        %readasync(serialPorts(i), serialPorts(i).InputBufferSize - serialPorts(i).BytesAvailable); %try to read more data
        pause(0.07)  %this pause here is to give some time for the data to fill up the buffer
	end
	serialPorts(i).BytesAvailableAction = dataListener;
	serialPorts(i).ReadAsyncMode = readMode;
end