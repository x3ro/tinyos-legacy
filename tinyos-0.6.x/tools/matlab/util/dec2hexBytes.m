function bytes = dec2hexBytes(varargin)
%bytes = dec2hexBytes(dec, <numBytes>)
%
%This function takes an array of decimal numbers and turns it into a matlab string of 
%bytes in Hex notation.  These bytes should be the same as the bytes written by a 
%similar function call to the function "fwrite(serialPort, dec, 'uchar')"
%
%If the optional numBytes argument is passed, the result will be padded with 
%zeros to be sure there are enough bytes. If too many bytes result from
%the translation, an error will be emitted.
%
%essentialy, a number greater than 255 gets two bytes and a number 255 or less gets 1 bytes.
%numbers > 0xFFFF might cause a bug
%
%TO DO: allow this to deal with numbers of arbitrary size.

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

global BIG_ENDIAN
dec = varargin{1};

bytes = '';
if length(varargin) > 1         %then, if the user sent a parameter saying how many bytes this should be total
    numBytes = varargin{2};
else
    numBytes = zeros(1,length(dec));
end
for i=1:length(dec)     %first, use the built in matlab function dec2hex
    if numBytes(i)~=0   %if we know the correct size
        hex = dec2hex(dec(i),numBytes(i)*2);      %ask for that size
        if length(hex) > numBytes(i)*2            %and then check it
            error('Your numbers are too big for this many bytes')
        end
    else                %if we don't know the size
        hex = dec2hex(dec(i));
        if mod(length(hex),2)==1        %just make sure it is a multiple of two (one byte is 2 hex digits)
            hex = ['0' hex];
        end
    end
    if BIG_ENDIAN==1    %then format the output correctly, depending on the user's settings of endianness
        for j = 1:length(hex)
            bytes = [bytes  hex(j)];
            if mod(j,2)==0
                bytes = [bytes ' '];
            end
        end
	else
        for j = length(hex)-1:-2:1
            bytes = [bytes  hex(j) hex(j+1)];
            bytes = [bytes ' '];
        end
    end
end
