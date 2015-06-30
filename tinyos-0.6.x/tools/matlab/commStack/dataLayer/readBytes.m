function data = readBytes(dataPorts,numBytes)
%readBytes(dataPorts,numBytes)
%
%This function takes an array of dataPorts and reads 
%an array of bytes from each of them.
%The data is returned in a matrix data, where each
%row corresponds to a serial port
%
%this function provides the lowest level of read support
%to a data port, such as a serial port.
%
%If DEBUG is set to 1 then it also prints out each array 
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

data = [];

for i=1:length(dataPorts)
    data(i,:) = fread(dataPorts(i), numBytes,'uchar');  

	if DEBUG 
            disp(['Read from: ' dataPorts(i).name ' DATA: ' dec2hexBytes(data(i,:))])
    end
end




   