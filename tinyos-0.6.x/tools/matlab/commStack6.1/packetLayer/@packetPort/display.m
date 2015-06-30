function display(p2)
% PACKETPORT/DISPLAY Displays the packet to the user

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
global PACKET_PORT_STORAGE  %these two lines go at the beginning of every packetPort function(simulated pass-by-reference
p = PACKET_PORT_STORAGE([p2.id]);

for i=1:length(p)
	disp(' ')
    if ~isempty(p(1).dataPort)
    	    disp(['dataPort:             ' p(i).dataPort(1).name.toCharArray']);                %the dataPort to be listened or written to; this needs to be fixed so it doesn't give an error when an array or paketPorts are displayed
    else
        disp(['dataPort:             ' ]);                %the dataPort to be listened or written to; this needs to be fixed so it doesn't give an error when an array or paketPorts are displayed
    end
    if length(p(i).packetListeners)>0
        packetListeners = p(i).packetListeners;
        l =  packetListeners{1};
		disp(['packetListeners:      ' l{1}]);         %the functions to be called when an event is triggered
		for j = 2:length(packetListeners)
            l =  packetListeners{j};
            disp(['                      ' l{1}]);
        end%the functions to be called when an event is triggered
    else
		disp(['packetListeners:      ' ]);         %the functions to be called when an event is triggered
    end
    disp(['packetType:           ' get(p2(i),'packetType')]);     %the packet type to interpret the incoming data
	disp(['dataBufferSize:       ' num2str(get(p2(i),'dataBufferSize'))]);          %the number of bytes to be read at a time
	disp(['packetBufferSize:     ' num2str(get(p2(i),'packetBufferSize'))]);         %the number of packets to be read before triggering an event
	disp(['timeout:              ' num2str(get(p2(i),'timeout'))]);                 %the time before triggering an event
end


PACKET_PORT_STORAGE([p2.id])=p;   %this line goes at the end of every packetPort function, now (simulated pass-by-reference)

