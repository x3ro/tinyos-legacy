%define Sarah's Matlab World
%for NEST Retreat 6/17/2002
%before you do any of this, run defineTOSenvironment from the nest/tools/matlab directory.

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
%     Authors:  Sarah Bergbreiter <sbergbre@eecs.berkeley.edu>
%     Date:     June 17, 2002 

%add all directories with your functions to the path.
%this makes all the functions in those directories available for use.
global ROOT
addpath([ROOT '/contrib/sarah'])
addpath([ROOT '/contrib/sarah/openLoopGUI'])
addpath([ROOT '/contrib/sarah/testApp'])

%define your COMM stack.  Usually, 'addPacketPorts' is sufficient.  It defines the dataPorts and packetPorts to use the ports you specify.
%in this case we are just defining the comm stack for the local serial port on your machine
addPacketPorts('COM1');
%addPacketPorts('COM5');

%define the packetPorts that each mote will be located on.  This is only necessary if you want to use the routing layer.
%This information is stored in the portMap of the routingLayer of the commStack.
%In the future, matlab should be able to do this automatically using network discovery
%In this case, we define mote 1 to be on COM1
setPortMapping(1, getPacketPorts('serial-COM1'));
%setPortMapping(2, getPacketPorts('serial-COM5'));

%define the location of each mote.  This is only important if you want to plot over position or do something over distance.
%this information is accessible through the shared/localize functions
%in this case we are setting mote 1 to be at location 0,0,0
setLocation(1, 0,0,0);
%setLocation(2, 1,0,0);
%setLocation(2, 1, 1, 1);

