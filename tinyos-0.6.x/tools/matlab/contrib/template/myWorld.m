%define My World
%This file is described in more details in the matlab/docs directory
%See "an example matTOS application"

%There are six main things you currently have to do to define your own environment.
%Read through the following comments to understand essentially everything you have to do:

%add all directories with your functions to the path.
%this makes all the functions in those directories available for use.
global ROOT
addpath([ROOT '/contrib/template'])
addpath([ROOT '/contrib/template/myApp'])

%define the environments of all tools that you might want to use
%in this case we only want to use one app, generic sensor.  Defining this app makes available all functions useful in generic sensor
addpath([ROOT '/apps/genericSensor'])
defineGenericSensorEnvironment;

%uncommenting the following lines will change the byte format to hexidecimal
% global DISPLAY_HEX
% DISPLAY_HEX=1;

%uncommenting the following line will change the number of packets read in at a time (Default=1)
%setDataPortBufferSizes(10);

%The following lines are being run in "defineTOSenvironment"
%and define the default headers with which a packet is parsed.  
%If you are using different headers, uncomment this to REDEFINE the default packet headers.
%You might want to do this, for example, if you are using the new comm stack which uses variable length 
%packets and uses a header field for 'length' of the packet.  I've already added that field in here for you
%and reduced the size of the payload correspondingly.
% newTosHeader(1) = createField('address', 2);  %tosHeader is a group of headers in the general TOS packet.
% newTosHeader(2) = createField('AM', 1);         %It can of course be changed or replaced.
% newTosHeader(3) = createField('groupID', 1);       %To replace, define a new header class and tell the 
% newTosHeader(4) = createField('length', 1);       %To replace, define a new header class and tell the 
% newTosHeader(5) = createField('data', [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);         %bytes2packet function to use the new class of headers
% newTosHeader(6) = createField('CRC', 2);  %by setting the packetType variable of the packetPort object
% addPacketHeaders('newTosHeader', newTosHeader);
% defineDefaultPacketHeaders('newTosHeader');

%Define your incoming packet type
%When a new packet comes in, the commStack automatically tries to parse it.  It uses the AM type of the packet to find out what kind of packet it is,
%and it uses that type to parse it.  If you define a new type of packet, your should define the headers that will be used to parse it and register those 
%headers for that AM type.  Here is an example:  whenever a packet comes in on Am type 100, the data load of the packet is parsed into the following fields:
%hopCount which has 1 bytes, Xcoord which has 2 bytes, Ycoord which has 2 bytes, and lightReadings, which is an array of size 10 where each element has 2 bytes.
MY_AM_NUMBER=100;
myPayload(1) = createField('hopCount', 1);          %the number of hops away I am, 1 byte
myPayload(2) = createField('Xcoord', 2);            %my X coordinate, 2 bytes
myPayload(1) = createField('Ycoord', 2);            %my Y coordinate, 2 bytes
myPayload(2) = createField('lightReadings', [2 2 2 2 2 2 2 2 2 2]);         %an array of ten light readings, 2 bytes each.
addAMHeaders(MY_AM_NUMBER, myPayload);

%define your COMM stack.  Usually, 'addPacketPorts' is sufficient.  It defines the dataPorts and packetPorts to use the ports you specify.
%in this case we are just defining the comm stack for the local serial port on your machine
%addPacketPorts({'COM1' 'COM2'});
addPacketPorts('COM1');

%define the packetPorts that each mote will be located on.  This is only necessary if you want to use the routing layer.
%This information is stored in the portMap of the routingLayer of the commStack.
%In the future, matlab should be able to do this automatically using network discovery
%In this case, we define mote 1 to be on COM1
setPortMapping(1, getPacketPorts('serial-COM1'));
%setPortMapping(2, getPacketPorts('serial-COM2'));

%define the location of each mote.  This is only important if you want to plot over position or do something over distance.
%this information is accessible through the shared/localize functions
%in this case we are setting mote 1 to be at location 0,0,0
setLocation(1, 0,0,0);
%setLocation(2, 1, 1, 1);

%The following lines could be used to define the remote ports on the Intel/Berkeley testbed
% addpath([ROOT '/contrib/kamin'])
% defineTestbed
%add the ports on the testbed, define a mote/port mapping, and define their locations
% global testBed
% addPacketPorts(testBed.everything);
% defineTestbedPortMapping
% defineTestbedLocations