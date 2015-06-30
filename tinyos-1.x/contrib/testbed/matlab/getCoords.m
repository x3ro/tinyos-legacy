function coords=getCoords(nodeID)
%this function will get the id of a node given the connection
global TESTBED
coords =[TESTBED.x(find(nodeID== TESTBED.id)) TESTBED.y(find(nodeID== TESTBED.id))];
