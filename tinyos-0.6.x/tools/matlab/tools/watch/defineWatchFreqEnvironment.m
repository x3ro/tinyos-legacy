%this function should be run before running the watchFreq functions

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
addpath([ROOT '/tools/watchFreq'])
addpath([ROOT '/shared/oscope']);
addpath([ROOT '/contrib/kamin/util']);
defineOscopeEnvironment

global DEFAULT_WATCH_NODES_PARAMS
DEFAULT_WATCH_NODES_PARAMS.fieldName='moteID';%'data';      %this is the name of the field that will be watched
DEFAULT_WATCH_NODES_PARAMS.addMethod='addDataToWatchFreq';      %this is the name of the function used to add new data
DEFAULT_WATCH_NODES_PARAMS.filterName='';      %this is the name of the function used to add new data
DEFAULT_WATCH_NODES_PARAMS.timeWindow=100;          %this is the number of data points stored by the watch
DEFAULT_WATCH_NODES_PARAMS.packetPort = [];       %this is the amount of space at the end
DEFAULT_WATCH_NODES_PARAMS.history = [];       %this is the amount of space at the end
DEFAULT_WATCH_NODES_PARAMS.sortBy = 1;       %indicates what to sort bar graph according to.  1=sort by Value, 2=sortbyFreq

global WATCH_NODES_PLOT_FUNCTION
WATCH_NODES_PLOT_FUNCTION = 'bar'; % you could change this to 'loglog' or whatever you want