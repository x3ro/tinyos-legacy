function data = writeBytes(dataPorts,bytes)
%writeBytes(dataPorts,bytes)
%
%This function takes an array of dataPorts and writes 
%an array of bytes to each of them.
%
%this function is used for the lowest level of read access to
%a data port, such as the serial port.
%
%If DEBUG is set to 1 then it also prints out the bytes 
%to screen and the port name.
   
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
global BIG_ENDIAN
endianness = BIG_ENDIAN;
BIG_ENDIAN = 0;

for i=1:length(dataPorts)
    while ~strcmp(dataPorts(i).transferStatus,'idle')
        pause(0.05)
    end
    
    fwrite(dataPorts(i), bytes,'uchar', 'async');  

	if DEBUG 
            disp(['Write to: ' dataPorts(i).name ' DATA: ' dec2hexBytes(bytes)])
    end
end

BIG_ENDIAN = endianness;


   