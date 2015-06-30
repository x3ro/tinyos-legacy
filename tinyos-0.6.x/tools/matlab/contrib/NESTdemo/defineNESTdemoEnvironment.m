
%define the matlab environment that will be used in the NEST demo

%uncommenting the following lines will make sure the output of packets is in hex
%global DISPLAY_HEX
%DISPLAY_HEX=1;

global NETWORK_SCALE
NETWORK_SCALE=300;  %this is the ratio of network units to Centimeters

global MAX_NETWORK_DIMENSION
MAX_NETWORK_DIMENSION=5;  %this is the largest side of the network in network coordinates

global MAGNETOMETER_READINGS
MAGNETOMETER_READINGS=0;

global TOF_READINGS
TOF_READINGS=1;

global GROUP_ID
GROUP_ID=134;

%the following lines redefine the default packet header
%because we are using variable length packets in the NEST demo
variableLengthHeader(1) = createField('address', 2);  %tosHeader is a group of headers in the general TOS packet.
variableLengthHeader(2) = createField('AM', 1);         %It can of course be changed or replaced.
variableLengthHeader(3) = createField('groupID', 1);       %To replace, define a new header class and tell the 
variableLengthHeader(4) = createField('length', 1);       %To replace, define a new header class and tell the 
variableLengthHeader(5) = createField('data', 29);         %bytes2packet function to use the new class of headers
variableLengthHeader(6) = createField('CRC', 2);  %by setting the packetType variable of the packetPort object
addPacketHeaders('variableLengthHeader', variableLengthHeader);
defineDefaultPacketHeaders('variableLengthHeader');

%define my local ports
addPacketPorts('COM1');
%addPacketPorts('COM2');
addPacketPorts('COM3');


%define the IDs for the PURSUER_RENE for routing purposes (so we know which serial port to send packets to)
global PURSUER_RENE
PURSUER_RENE = hex2dec('198');
%setPortMapping(PURSUER_RENE, getPacketPorts('serial-COM2'));
setPortMapping(PURSUER_RENE, getPacketPorts('serial-COM3'));
%setLocation(PURSUER_RENE, 0,0,0);

%define the IDs for the PURSUER_MICA for routing purposes (so we know which serial port to send packets to)
global PURSUER_MICA
PURSUER_MICA = hex2dec('199');
setPortMapping(PURSUER_MICA, getPacketPorts('serial-COM1'));
%setLocation(PURSUER_MICA, 0,0,0);

%define the IDs for the GENERIC_BASE for routing purposes (so we know which serial port to send packets to)
global GENERIC_BASE
GENERIC_BASE = hex2dec('100');
setPortMapping(GENERIC_BASE, getPacketPorts('serial-COM1'));
%setLocation(GENERIC_BASE, 0,0,0);


%define the IDs of all the motes in the network and define their locations and port mappings
%we assume that a node with ID '231' is at location x=3, y=1 and that all nodes
%are accessible through the generic base
global NETWORK_MOTE_IDS
NETWORK_MOTE_IDS =[];
for i=0:4
    for j=0:4
        strn = ['2' num2str(i) num2str(j)];
        moteID=hex2dec(strn);
        NETWORK_MOTE_IDS(end+1) = moteID;
        setLocation(moteID, i,j);
        setPortMapping(moteID, getPortMapping(GENERIC_BASE));
    end
end


%define the AM type that the AGRO application is using (which is the app that gives us all sensor readings)
global AGRO_AM
AGRO_AM=5;

agroHeaders(1) = createField('type', 1);  %the number of messages I received
agroHeaders(2) = createField('packID', 1);         %the number of messages I sent.
agroHeaders(3) = createField('from', 1);         %the number of messages I sent.
agroHeaders(4) = createField('nodeID1', 1);
agroHeaders(5) = createField('reading1', 2);
agroHeaders(6) = createField('nodeID2', 1);
agroHeaders(7) = createField('reading2', 2);
agroHeaders(8) = createField('nodeID3', 1);
agroHeaders(9) = createField('reading3', 2);
agroHeaders(10) = createField('nodeID4', 1);
agroHeaders(11) = createField('reading4', 2);
agroHeaders(12) = createField('hops', [1,1,1,1,1,1,1,1]);
addAMHeaders(AGRO_AM, agroHeaders);

global MAG_AM
MAG_AM=136;
magHead(1) = createField('mag', 2);  
addAMHeaders(MAG_AM, magHead);


%setup your path properly so that we can run all the commands that we want
%particularly, import TOFcalibration and the TOFcalibration, tofRanging, and positionEstimation applications into our working path
global ROOT
addpath([ROOT '/contrib/NESTdemo'])
addpath([ROOT '/contrib/NESTdemo/pursuerEvader'])
addpath([ROOT '/contrib/kamin/TOFcalibration'])
addpath([ROOT '/contrib/kamin/TOFcalibration/analysis'])
addpath([ROOT '/shared/tofRanging'])
defineTofRangingEnvironment


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CAMERA STUFF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath([ROOT '/contrib/camera'])
serialPortString = 'COM4';
positionInches = [ 48 ; -24 ; 52.5 ];  %location of the camera base in the global coord frame
baseRotationDegrees = 0;  %rotation of the tripod relative to the global coord frame
descentAngleDegrees = 45;  %tilt down of the camera base
zoomFactor = 80;
defineCameraEnvironment(serialPortString, positionInches, baseRotationDegrees, descentAngleDegrees, zoomFactor);
