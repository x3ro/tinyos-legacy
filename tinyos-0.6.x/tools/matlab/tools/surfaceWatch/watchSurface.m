function h=watchSurface(varargin)
%watchSurface(varargin)
%
%USAGE:     watchSurface(moteIDs, <PLOT parameters>)
%
%This function takes an array of moteIDs and matlab SURFACE parameters.
%
%THIS FUNCTION IS EXACTLY LIKE SURF.  It even takes the same arguments (in fact it just passes them on to SURF). 
%WATCHSURFACE pops up a watch figure, which is just a modified SURFACE figure. WATCHSURFACE returns a handle to that figure, just as SURF does.
%
%There are only two ways that WATCHSURFACE differs from SURF:
%   1.  The first argument must always be an array of moteIDs
%   2.  data from these motes is constantly added to the WATCHSURFACE figure
%
%You can interact with the WATCH figure the same way you would after using SURF.  In particular, you should know how to use
%the SET, AXIS, LEGEND, XLABEL, YLABEL, TITLE, etc, commands.  
%
%There are also a few new functions associated with a WATCH figure
%   1. removeWatch(h)
%   1. setWatchedField(h) -- this is a string holding the name of the field of the packet that should be watched.
%   1. setAddMethod(h) -- this is a string holding the name of the function used to add data.
%   2. setWatchDuration(h) -- sets the number of data points saved in the watch figure
%   3. setTrailerLength(h)  -- sets the amount of space behind the beginning of the last watched data to show
%   4. setHeaderLength(h)  -- sets the amount of space in front of the beinning of the first watched data to show
%
%To get the data out of the watch figure, use the handle that was returned: x = get(h, 'XData'); y = get(h, 'YData');
%In this way, you can watch some data and then extract the data later for further analysis.
%
%It is possible to set a flag such that when a data stream realizes that it is going off the plot it could simply wrap
%around to the beginning of the plot again, but this hasn't been implemented.
%
%If you want to watch a regular surface or use some other surface function, change the WATCH_SURFACE_PLOT_FUNTION global variable.

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

global DEFAULT_WATCH_SURFACE_PARAMS
global WATCH_SURFACE_PLOT_FUNCTION %note that the default is 'surfc'.  Change this global to 'surf' or whatever kind of surface plot you want

watchParams = DEFAULT_WATCH_SURFACE_PARAMS;   %note that we could allow the user to send a new set of watch params, but that is too much trouble.
moteIDs = varargin{1};
watchParams.moteIDs = moteIDs;
varargin = {varargin{2:end}};

%Note: I have to go through all these next few lines of code because matlab doesn't have a command
%that will just give me a blank surface plot
eval(['hTemp = ' WATCH_SURFACE_PLOT_FUNCTION '([0 0; 0 0], varargin{:});']);   %create a new figure (with bogus data z=[1 1;1 1])
h = hTemp(1);        %Note that if the user assigns initial data it will be stored in a second plot, not this one.
colormap hot;
set(h, 'XData',[], 'YData', [], 'ZData', [], 'CData', []);   %get rid of the bogus data.  Now we have an new empty plot
set(h,'EraseMode','normal'); 
set(gcf,'DoubleBuffer', 'on');
set(gcf,'BackingStore', 'on');
set(gcf,'Renderer', 'OpenGL');

if watchParams.drawPoints ==1
    if ishold
        watchParams.traces = plot3(0,0,0,'.','MarkerSize',25); %nonuniform
    else
        hold on
        watchParams.traces = plot3(0,0,0,'.','MarkerSize',25); %nonuniform
        hold off
    end
    set(watchParams.traces, 'XData',[], 'YData', [], 'ZData', []);   %get rid of the bogus data.  Now we have an new empty plot
end

set(h,'UserData', watchParams);           % and now it is a WATCH figure
    
packetPorts = getPortMapping(moteIDs);

clearPacketBuffers(getPortMapping(watchParams.moteIDs));

packetPorts = addPacketListeners(packetPorts, {'watchSurfaceReceiveNewData', h});