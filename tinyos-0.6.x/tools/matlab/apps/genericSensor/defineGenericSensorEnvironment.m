%genericSensor is a TOS application that should encapsulate all
%core functionality of a sensor node.
%
%It is essentially just a .desc file that initializes several
%key shared components.  You can interact with these components
%through the AM handler command interfaces that they offer.
%These are more evident by looking in their corresponding tools
%directory.  All this file does is define their environments 
%so that you can run their commands.

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

addpath([ROOT '/apps/genericSensor']);
addpath([ROOT '/shared/command']);
defineCommandEnvironment
addpath([ROOT '/shared/log']);
defineLogEnvironment
addpath([ROOT '/shared/oscope']);
defineOscopeEnvironment
addpath([ROOT '/shared/sleep']);
defineSleepEnvironment
addpath([ROOT '/shared/clock']);
defineClockEnvironment
addpath([ROOT '/shared/localize']);
defineLocalizeEnvironment
