%this function should be run before running the listen functions

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

global ROOT
addpath([ROOT '/tools/watch'])
%addpath([ROOT '/tools/watch/watchTools'])
addpath([ROOT '/shared/oscope']);
defineOscopeEnvironment
addpath([ROOT '/shared/localize']);
defineLocalizeEnvironment

global DEFAULT_WATCH_PARAMS
DEFAULT_WATCH_PARAMS.fieldName='samples';%'data';      %this is the name of the field that will be watched
DEFAULT_WATCH_PARAMS.addMethod='addDataToWatch';      %this is the name of the function used to add new data
DEFAULT_WATCH_PARAMS.filterName='';      %this is the name of the function used to add new data
DEFAULT_WATCH_PARAMS.duration=200;          %this is the number of data points stored by the watch
DEFAULT_WATCH_PARAMS.trailerLength=20;      %this is the amount of space in the beginning of the window
DEFAULT_WATCH_PARAMS.headerLength=20;       %this is the amount of space at the end
DEFAULT_WATCH_PARAMS.packetPort = [];       %this is the amount of space at the end
DEFAULT_WATCH_PARAMS.circularIndex = 1;          %Set this to 1 for circular drawing, 0 for sliding over
DEFAULT_WATCH_PARAMS.trace = [];            %this holds the handle of a figure that shows the trace

global WATCH_PLOT_FUNCTION
WATCH_PLOT_FUNCTION = 'plot'; % you could change this to 'loglog' or whatever you want