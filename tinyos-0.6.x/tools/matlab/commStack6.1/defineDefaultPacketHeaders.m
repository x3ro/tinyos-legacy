function defineDefaultPacketHeaders(name)
%defineDefaultPacketHeaders(name)
%
%this function defines the default headers that are used by the comm stack
%when receiving and parsing a new packet.

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
global DEFAULT_DATA_BUFFER_SIZE

COMM.defaultHeaders = getPacketHeaders(name);
COMM.defaultHeaderSize = sum([COMM.defaultHeaders.size]);
numBytes=1;
for i=1:length(COMM.defaultHeaders)
    if strcmpi(COMM.defaultHeaders(i).label,'AM')
        COMM.defaultHeadersAMbytePosition=numBytes;
        break;
        %COMM.defaultHeadersAMnumBytes=2; %we will need this line if we ever move to more than 255 AM types 
    else
        numBytes=numBytes+sum(COMM.defaultHeaders(i).size);
    end
end
%setDataPortBufferSizes(DEFAULT_DATA_BUFFER_SIZE)
