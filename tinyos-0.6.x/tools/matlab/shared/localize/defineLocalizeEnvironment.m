%defineLocalizeEnvironment
%
%This file defines the environment needed to interact 
%with the LOCALIZE component.  
%
%The LOCALIZE component on the node finds the location
%of that node in some unknown way. This toolset is used
%to interact with this component in two ways:
%   1.  To make locations available to user
%   2.  To interact with the localize component
%
%To send packets to a node running LOCALIZE, first run this file 
%and then run one of the other functions in this directory.
%This will return a packet, which you can then send
%using any type of injection command

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
addpath([ROOT '/shared/localize'])

global LOCALIZE_AM_HANDLER
LOCALIZE_AM_HANDLER=25;            %8 is the AM handler of COMMAND

global LOCATIONS
LOCATIONS = {};

localizeDataHeader(1)= createField('moteID', 2);
localizeDataHeader(2)= createField('onsetTiming', 2);
localizeDataHeader(3)= createField('offsetTiming', 2);
addAMHeaders(LOCALIZE_AM_HANDLER, localizeDataHeader);
