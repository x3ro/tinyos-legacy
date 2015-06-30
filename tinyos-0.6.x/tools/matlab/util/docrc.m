function crc=docrc(packet)
% crc = docrc(packet)
%
% This function computes a CRC-16 checksum for an array of bytes. It takes as
% input an array of numbers, rather than a packet object as might be
% implied. I t works as expected for numbers smaller than 256. For other
% numbers, I"m not sure what will be returned. The function might have
% problems with arrays with weird matlab elements, like int8, but works fine
% if you omit the specification.
    
%    "Copyright (c) 2000 and The Regents of the University of California.  All
%    rights reserved. 
%
%    Permission to use, copy, modify, and distribute this software and its 
%    documentation for any purpose, without fee, and without written agreement 
%    is hereby granted, provided that the above copyright notice and the 
%    following two paragraphs appear in all copies of this software. 
%
%    IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY 
%    FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES 
%    ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
%    THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
%    DAMAGE.  
%
%    THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, 
%    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
%    AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
%    IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION
%    TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
%
%    Authors:  Robert Szewczyk <szewczyk@cs.berkeley.edu>
%    Date:     May 28, 2002 

    crc=0;
    index=1;
    count = length(packet);
    while count > 0
	crc = bitxor(crc, bitshift(packet(index), 8));
	index = index+1;
	i = 8;
	for i = 1:8
	    if (bitand(crc, 32768) == 32768)
		crc = bitxor(bitshift(crc,1), 4129);
	    else
		crc = bitshift(crc, 1);
	    end
	end
	crc = bitand(crc, 65535);
	count = count-1;
    end
    