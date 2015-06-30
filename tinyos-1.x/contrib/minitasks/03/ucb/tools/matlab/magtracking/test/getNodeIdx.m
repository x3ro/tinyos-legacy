function idx = getNodeIdx(nodeID)
%
% search the list of node IDs to find the node's index in the
% global node array.  If the nodeID isn't found, a new index is allocated.
% 


global VIS;

% for debugging, translate ints to strings, and do the sanity check below
if isfield(VIS,'debug') & VIS.debug
    if isnum(nodeID);
        nodeID = sprintf('0x%x', nodeID)
    end
end
    
if isstr(nodeID)
    x = str2num( nodeID(length(nodeID)-1) );
    y = str2num( nodeID(length(nodeID)) );

    width = sqrt(VIS.num_nodes);
    if isempty(x) | isempty(y) | x >= width | y >= width
        disp( sprintf('request for bad node id "%x"', nodeID) );
        garbage = goes.here; % cause matlab to barf, so we get a stack trace
    end
    nodeID = 512 + 16*x + y;
end


idx = find(VIS.nodeIdx == nodeID);

if length(idx) > 1
  error
end

if length(idx) == 0 
  idx = length( VIS.nodeIdx ) + 1;
  VIS.nodeIdx( idx ) = nodeID;
  VIS.flag.nodes_updated = 1;
  
  % initialize the node struct to reasonable values
  VIS.node(idx).id = nodeID;
  VIS.node(idx).real_x = -1;
  VIS.node(idx).real_y = -1;
  VIS.node(idx).calc_x = -1;
  VIS.node(idx).calc_y = -1;
  VIS.node(idx).parent = -1;
  VIS.node(idx).mag_time = -1000000;
  VIS.node(idx).mag_reading = 0;
end


