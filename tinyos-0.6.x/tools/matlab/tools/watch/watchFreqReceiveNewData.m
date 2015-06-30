function watchFreqReceiveNewData(packetPort, packet, h)
%watchFreqReceiveNewData(packetPort, packet, h)
%
%This function is called by the packetPort event handler.
%It is passed the handle of the WATCH figure to plot to, and is given the received packet
%
%The data is extracted from the packet and added to the figure.
%The way to add it to the figure is stored in the figure itself

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

%disp('entered watchreceivenewData')
watchParams = get(h,'UserData');
data = get(packet, watchParams.fieldName);
moteID = get(packet, 'moteID');
if ~isempty(watchParams.filterName)
    filter = watchParams.filterName;
    eval(['data = ' filter '(moteID, data);']);
end
watchParams.history = [watchParams.history data];
watchParams.history = timeWindow(watchParams.history, watchParams.timeWindow);
set(h,'UserData', watchParams);           
addMethod = watchParams.addMethod;
eval([addMethod '(h, watchParams.history);']);
%disp('left watchreceivenewData')
