function setRanging(nodes, maxNeighbors)

global TESTBED

if nargin<1 | isempty(nodes) | strcmp(nodes, 'all')
  nodes=TESTBED.nodeIDs;
end
if nargin<2 | isempty(maxNeighbors)
  maxNeighbors = 6;
end

for node=nodes
  i= find(TESTBED.nodeIDs==node);
  nodeInds = vectorFind(nodes,TESTBED.nodeIDs);
  [neighborDists, neighbors] = sort(TESTBED.distanceMatrix(i,nodeInds));
  neighbors = neighbors(1:min(maxNeighbors+1,length(neighbors))); %choose the 8 closest nodes to be neighbors
  cmd = ['peg ' num2str(TESTBED.nodeIDs(i)) ' CalamariSetRanging(' num2str(length(neighbors)-1)];
  for j=2:length(neighbors) %add each of the neighbors and its distance
      cmd = [cmd ',' num2str(TESTBED.nodeIDs(neighbors(j))) ',' num2str(neighborDists(j))];
  end
  cmd = [cmd ')'];
   for k=1:TESTBED.retry
    disp(cmd);
    eval(cmd)
    pause(0.25);
  end
end

