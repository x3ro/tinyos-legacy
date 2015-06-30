function h=watchFreq(varargin)
%h=watchFreq(varargin)
%
%USAGE:     watchFreq(moteIDs, <PLOT parameters>)
%
%This function takes an array of moteIDs and matlab PLOT parameters.
%
%THIS FUNCTION IS EXACTLY LIKE WATCH. 
%
%However, instead of plotting data from a number of motes of time, it plots a histogram of a frequency of 
%that data over time.  The field that is watched is defined by:
%DEFAULT_WATCH_NODES_PARAMS.fieldName
%
%for example, when this is set to 'moteID' is draws a frequency plot over which motes have been heard recently.
%It can also be used for any other data field that is in your packets.

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

global DEFAULT_WATCH_NODES_PARAMS
global WATCH_NODES_PLOT_FUNCTION %note that the default is 'plot'.  Change this global to 'loglog' or whatever kind of 2D plot you want

watchParams = DEFAULT_WATCH_NODES_PARAMS;   %note that we could allow the user to send a new set of watch params, but that is too much trouble.
if length(varargin)>0
    moteIDs = varargin{1};
else
%    moteIDs = 'all';
    error('please enter the mote IDs you want to watch, e.g. ''watchFreq([1 2 8 12 43])')
end
varargin = {varargin{2:end}};
h = [];

holdWasOn = 0;  %remember if HOLD was on before
if ishold
    holdWasOn = 1;
    hold off;
end

packetPorts = getPortMapping(moteIDs);

%Note: I have to go through all these next few lines of code because matlab doesn't have a command
%that will just give me a blank plot
eval(['hTemp = ' WATCH_NODES_PLOT_FUNCTION '(zeros(1,length(moteIDs)), varargin{:});']);   %create a new figure (with bogus data x=1, y=1)
h = hTemp(1);        %Note that if the user assigns initial data it will be stored in a second plot, not this one.
%set(h, 'XData',[], 'YData', []);   %get rid of the bogus data.  Now we have an new empty plot
watchParams.figureAxes = gca;
set(watchParams.figureAxes, 'XTickLabel', moteIDs);
watchParams.packetPort = packetPorts;
watchParams.moteIDs = moteIDs;
%set(h,'EraseMode','background');                   
set(h,'EraseMode','normal');                   
set(gcf,'DoubleBuffer','on');                   
% if watchParams.circularIndex>0
%     set(h,'XData',1:watchParams.duration,'YData',zeros(1,watchParams.duration))
%     hold on
%     watchParams.trace = plot(1,0,'r.','MarkerSize',20);
% end
set(h,'UserData', watchParams);           % and now it is a WATCH figure
addPacketListeners(packetPorts, {'watchFreqReceiveNewData', h});

if holdWasOn==1  %return the previous hold parameter
    hold on;
end