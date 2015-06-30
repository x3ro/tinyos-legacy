function bytes = toBytes(varargin)
%toBytes(data)
%
%this function takes an array of integers and returns an array
%of bytes that represents those integers as if they were in a data packet.
%
%If the optional numBytes argument is passed, the result will be padded with 
%zeros to be sure there are enough bytes. If too many bytes result from
%the translation, an error will be emitted.
%
%numbers larger than 0xffff will cause a problem
%
%Use BIG_ENDIAN to determine the endianness

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

bytes = [];
data = varargin{1};
if length(varargin) > 1
    hex = dec2hexBytes(data,varargin{2});
else
    hex = dec2hexBytes(data);
end

while length(hex) > 1
    byte = hex(1:2);
    hex = hex(4:end);
    bytes(end + 1) = hex2dec(byte);
end
