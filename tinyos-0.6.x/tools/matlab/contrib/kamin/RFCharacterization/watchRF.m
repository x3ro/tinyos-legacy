function h = watchRF(varargin)
%h = watchRF(<moteIDs>)
%
%This funtion uses watchSurface but configures it to watch RF
%If you pass moteIDs it will watch those otherwise it will just
%watch all motes.

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

global ADC_DATA_CHANNEL

if length(varargin) ==0
    error('you must pass a mote ID as a parameter');
    %moteIDs = 'all';
    packetLength = 36;  %This should be fixed somehow later when I have time to waste
else
    moteIDs = varargin{1};
    if length(moteIDs)>1
        error('watchRF can only watch a single mote at a time');
    else
        packetLength = get(getPortMapping(moteIDs(1)), 'packetLength');
    end
end

if get(getPortMapping(moteIDs), 'dataBufferSize') < 10*packetLength
    set(getPortMapping(moteIDs), 'dataBufferSize', 10*packetLength);
end

%startRFBiasCalibration(moteIDs, 0.05, 100);

figure
h = watch(moteIDs);
watchParams = get(h, 'UserData');
%DEFAULT_WATCH_PARAMS.fieldName='samples';%'data';      %this is the name of the field that will be watched
%DEFAULT_WATCH_PARAMS.addMethod='addDataToWatch';      %this is the name of the function used to add new data
DEFAULT_WATCH_PARAMS.duration=400;          %this is the number of data points stored by the watch
%DEFAULT_WATCH_PARAMS.circularIndex = 1;          %Set this to 1 for circular drawing, 0 for sliding over
watchParams.filterName='estimateRF';      %this is the name of the filter that takes the new data (and possibly a memory of the old data) and filters it down to a single value.
set(h, 'UserData', watchParams);

ADC_DATA_CHANNEL = 0;
routePackets(moteIDs, startSensing);
pause(0.1)
routePackets(moteIDs, setClockRate(16));

