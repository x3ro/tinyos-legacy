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
addpath([ROOT '/tools/surfaceWatch'])
%addpath([ROOT '/tools/surfaceWatch/watchSurfaceTools'])
addpath([ROOT '/shared/oscope']);
defineOscopeEnvironment
addpath([ROOT '/shared/localize']);
defineLocalizeEnvironment

global DEFAULT_WATCH_SURFACE_PARAMS
DEFAULT_WATCH_SURFACE_PARAMS.fieldName='samples';%'data';      %this is the name of the field that will be watched
DEFAULT_WATCH_SURFACE_PARAMS.addMethod='addDataToWatchSurface';      %this is the name of the function used to add new data
DEFAULT_WATCH_SURFACE_PARAMS.filterName='lastSample';      %this is the name of the filter that takes the new data (and possibly a memory of the old data) and filters it down to a single value.
DEFAULT_WATCH_SURFACE_PARAMS.resolution=10;      %this is the number of interpolated data points on the x and y axes
DEFAULT_WATCH_SURFACE_PARAMS.drawPoints=1;      %this indicates whether to indicate the real dataPoints in the interpolation.
DEFAULT_WATCH_SURFACE_PARAMS.x = [];      %this array holds the x coordinate of each mote.
DEFAULT_WATCH_SURFACE_PARAMS.y = [];      %this array holds the y coordinate of each mote.
DEFAULT_WATCH_SURFACE_PARAMS.z = [];      %this array holds the sensor reading of each mote.
DEFAULT_WATCH_SURFACE_PARAMS.moteIndexMap = [];      %this array holds the positions of the nodes in the x,y,z data arrays.

global WATCH_SURFACE_PLOT_FUNCTION
WATCH_SURFACE_PLOT_FUNCTION = 'surfc'; % you could change this to 'surf' or whatever you want