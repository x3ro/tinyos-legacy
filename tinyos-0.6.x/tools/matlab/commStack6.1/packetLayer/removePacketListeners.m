function packetPorts = removePacketListeners(packetPorts, packetListeners)
%packetPorts = removePacketListener(packetPorts, packetListeners)
%
%This function takes a packetPort object and the name of a function
%
%Removes packetListeners from the packetPorts.
%If there are no more packetListeners, 
%tells the dataPorts to stop telling me
%when it gets data.

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
if ischar(packetListeners)
    packetListeners = {{packetListeners}};
end

for i = 1:length(packetPorts)
    oldListeners = get(packetPorts(i),'packetListeners');
    for j=1:length(packetListeners)
        count=1;
        oldListeners2={};
        for k=1:length(oldListeners)
            if ~strcmpi(oldListeners{k}{1}, packetListeners{j}{1})
                oldListeners2{count} = oldListeners{k};
                count=count+1;
            end
        end
        oldListeners=oldListeners2;
    end
    set(packetPorts(i),'packetListeners',oldListeners);
end
