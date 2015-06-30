function useTopology(topology)
%this function takes the locations and anchor nodes from a topology
%and adds them to TESTBED

global TESTBED

%TESTBED.xy = [topology.xy(:,1) -topology.xy(:,2)-1]*100;
TESTBED.xy = topology.xy;
TESTBED.anchorNodes=topology.anchorNodes;
TESTBED.nodeIDs = topology.nodeIDs;
