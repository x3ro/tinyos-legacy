function location = getLocation(ID)
%This function gives the [x y] location of a mote by node ID.  At the
%moment, it converts the ID to hex and returns the last to hex digits.

nodeID = dec2hex(ID);
if length(nodeID)<3
    location=0;
else
    location = [str2num(nodeID(2)) str2num(nodeID(3))];
end