function location = getLocation(ID)
%This function gives the [x y] location of a mote by node ID.  At the
%moment, it converts the ID to hex and returns the last to hex digits.

%nodeID = dec2hex(ID);
%if length(nodeID)<3
%    location=0;
%else
%    location = [str2num(nodeID(2)) str2num(nodeID(3))];
%end

% calculate the node location based on a linearization of the array
% position

VIS.numNodes = 100;
VIS.gridsize = 10;

location = [ mod(ID,VIS.gridsize); floor(ID./VIS.gridsize) ];

