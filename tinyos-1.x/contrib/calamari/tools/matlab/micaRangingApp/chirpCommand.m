function chirpCommand(nodeID)

global TESTBED
global CMRI
index = find(nodeID == TESTBED.nodeIDs);
if length(index)==1
  send(nodeID, CMRI.transmitCommandMsg, TESTBED.address{index});
end
