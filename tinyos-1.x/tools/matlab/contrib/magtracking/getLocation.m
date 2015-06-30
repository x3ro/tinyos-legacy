function location = getLocation(ID)

nodeID = dec2hex(ID);
if length(nodeID)<3
    location=0;
else
    location = [str2num(nodeID(2)) str2num(nodeID(3))];
end