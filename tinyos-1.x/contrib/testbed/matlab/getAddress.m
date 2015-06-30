function address=getAddress(nodeID)
%this function will get the id of a node given the connection
global TESTBED
address = TESTBED.address(find(nodeID== TESTBED.id));

