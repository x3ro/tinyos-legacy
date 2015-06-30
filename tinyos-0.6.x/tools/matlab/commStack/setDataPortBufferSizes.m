function setDataPortBufferSizes(packetNumber)
%setDataPortBufferSizes(packetNumber)
%
%This function takes the number of packets that each packet Port should buffer
%before triggering an event (note that the default is one).
%
%it then sets each dataPort to buffer this many packets before triggering anything.

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

global COMM

if isfield(COMM,'dataPorts')
    dataPorts = COMM.dataPorts;

    global DEFAULT_DATA_BUFFER_SIZE
	DEFAULT_DATA_BUFFER_SIZE=packetNumber;
	
	packetHeaders = getDefaultPacketHeaders;
	headerSize = sum([packetHeaders.size]);
	
	if length(dataPorts)>0
        for i=1:length(dataPorts)
            fclose(dataPorts(i));                                                  %first close the dataPort
			dataPorts(i).InputBufferSize = 100*DEFAULT_DATA_BUFFER_SIZE*headerSize;             
			dataPorts(i).BytesAvailableActionCount = DEFAULT_DATA_BUFFER_SIZE*headerSize;             
			fopen(dataPorts(i));                                                   %and re-open the serial port    
		end
	end
end